using Microsoft.Extensions.Hosting.WindowsServices;
using AgendaFinanceira.Api;
using AgendaFinanceira.Dominio;
using AgendaFinanceira.Infraestrutura;

var builder = WebApplication.CreateBuilder(args);

/*
 * Como serviço do Windows.
 *
 * `UseWindowsService` faz a API responder aos comandos do gerenciador de serviços; fora
 * dele a chamada não tem efeito, então o `dotnet run` continua igual.
 *
 * O `ContentRootPath` é obrigatório: um serviço nasce com o diretório atual em `system32`,
 * e sem isto os `appsettings.json` seriam procurados lá. O sintoma seria a API subir sem
 * configuração nenhuma e falhar por falta do caminho do banco — apontando para o lugar
 * errado, porque o arquivo existe, só não onde ela procurou.
 */
builder.Host.UseWindowsService(o => o.ServiceName = "Agenda Financeira API");

if (WindowsServiceHelpers.IsWindowsService())
{
    builder.Environment.ContentRootPath = AppContext.BaseDirectory;
    builder.Configuration
        .SetBasePath(AppContext.BaseDirectory)
        .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
        .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json",
                     optional: true, reloadOnChange: true)
        .AddEnvironmentVariables();
}

// O caminho do banco vem da configuração. Nunca é fixo no código, ao contrário do backup
// automático do legado, que aponta para a área de trabalho de um usuário específico.
var caminhoBanco = builder.Configuration["Banco:Caminho"]
    ?? throw new InvalidOperationException(
        "Configure 'Banco:Caminho' no appsettings.json apontando para o banco Firebird. " +
        "Na etapa de leitura, aponte para uma cópia, não para produção.");

builder.Services.AddSingleton(new ConexaoFirebird(caminhoBanco));
builder.Services.AddSingleton<RepositorioLancamentos>();
builder.Services.AddSingleton<RepositorioCadastros>();
builder.Services.AddSingleton<RepositorioPainel>();
builder.Services.AddSingleton<IServicoSenha, ServicoSenhaBCrypt>();
builder.Services.AddSingleton<RepositorioUsuarios>();
builder.Services.AddProblemDetails();

// Falha fechada: sem chave de assinatura, a API não sobe.
builder.Services.AdicionarAutenticacao(ConfiguracaoAutenticacao.ExigirChave(builder.Configuration));

/*
 * Origens do cliente.
 *
 * Em desenvolvimento o Angular roda em `http://localhost:4200`. **Empacotado, a página vem
 * de `file://`, e o Chromium envia `Origin: null`** — uma cadeia de caracteres, não a
 * ausência do cabeçalho. Sem `"null"` na lista, a API responde 200 mas sem o
 * `Access-Control-Allow-Origin`, e o navegador descarta a resposta: tudo funciona no
 * desenvolvimento e nada funciona no aplicativo instalado.
 *
 * A lista vem da configuração e nunca é aberta para qualquer origem: liberar tudo num
 * sistema com dados financeiros é convite. O que protege de verdade é o token — nenhum
 * endpoint além de `POST /sessao` responde sem ele, e ele viaja em cabeçalho, não em
 * cookie, então não é enviado sozinho por uma página de terceiro.
 */
const string PoliticaCliente = "cliente";
var origens = builder.Configuration.GetSection("Cors:Origens").Get<string[]>()
              ?? ["http://localhost:4200"];

builder.Services.AddCors(o => o.AddPolicy(PoliticaCliente, p => p
    .WithOrigins(origens)
    .AllowAnyHeader()
    .AllowAnyMethod()));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new()
    {
        Title = "Agenda Financeira — API",
        Version = "v1",
        Description =
            "Contas a pagar do grupo Juliatti de Carvalho.\n\n" +
            "**Etapa 5 da migração.** Consultas, cadastros e lançamentos, incluindo as " +
            "operações em lote.\n\n" +
            "Lançamentos completos: criar, alterar, excluir, parcelar, pagar em lote e importar " +
            "planilha. O Delphi continua disponível sobre a mesma base, e reverter um módulo é " +
            "voltar a usar a tela dele.\n\n" +
            "**Autenticação:** chame `POST /sessao` com usuário e senha, copie o `token` da " +
            "resposta e informe em **Authorize**, no canto superior direito.\n\n" +
            "**Níveis**, os mesmos do legado: 1 só consulta, 2 opera, 3 administra. " +
            "Diferente do legado, que apenas esconde menus na tela, aqui a regra é verificada " +
            "no servidor.\n\n" +
            "Valores monetários viajam como decimal. Datas de vencimento e pagamento são datas " +
            "de calendário (aaaa-mm-dd), nunca instantes com fuso."
    });

    // Botão "Authorize" no Swagger, para testar os endpoints protegidos.
    c.AddSecurityDefinition("Bearer", new()
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Informe apenas o token devolvido por POST /sessao."
    });
    c.AddSecurityRequirement(new()
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Agenda Financeira v1");
    c.DocumentTitle = "Agenda Financeira — API";
    // Abre direto na documentação, sem precisar navegar até /swagger.
    c.RoutePrefix = "swagger";
});

// O erro que chega ao cliente é a razão real da recusa, não uma mensagem genérica.
// Uma recusa por regra de negócio vira 400 com a mensagem que o operador precisa ler;
// qualquer outra coisa é falha técnica e vira 500 sem vazar detalhe interno.
app.UseExceptionHandler(ramo => ramo.Run(async contexto =>
{
    var erro = contexto.Features
        .Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerFeature>()?.Error;

    if (erro is RegraDeNegocioException regra)
    {
        contexto.Response.StatusCode = StatusCodes.Status400BadRequest;
        await contexto.Response.WriteAsJsonAsync(new { erro = regra.Message });
        return;
    }

    contexto.Response.StatusCode = StatusCodes.Status500InternalServerError;
    await contexto.Response.WriteAsJsonAsync(new { erro = "Falha ao processar a requisição." });
}));

app.UseCors(PoliticaCliente);
app.UseAuthentication();
app.UseAuthorization();

// Quem abrir a raiz vai para a documentação.
app.MapGet("/", () => Results.Redirect("/swagger")).ExcludeFromDescription();

app.MapearCadastros();
app.MapearLancamentos();
app.MapearPainel();

app.MapGet("/saude", () => Results.Ok(new { situacao = "no ar", banco = Path.GetFileName(caminhoBanco) }))
   .WithTags("Diagnóstico")
   .WithSummary("Verifica se a API está no ar")
   .WithDescription("Informa também qual arquivo de banco está em uso — útil para conferir " +
                    "que a API não está apontando para produção por engano.");

// ---- Consulta de lançamentos ----
// Reproduz os filtros das duas abas do legado. Ver docs/fluxos.md, item 6.
app.MapGet("/lancamentos", (
    RepositorioLancamentos repo,
    DateOnly? inicio, DateOnly? fim,
    string? porData,          // vencimento (padrão) | pagamento | cadastro
    string? pagamento,        // todos (padrão) | pagos | naopagos
    string? descricao, string? despesa, string? subdespesa, string? conta,
    int? notaFiscal, int? cheque, bool? chequeCompensado, string? situacao,
    decimal? valorMinimo, decimal? valorMaximo, bool? faixaSobreValorPago) =>
{
    var consulta = FiltroDaConsulta.Montar(
        inicio, fim, porData, pagamento, descricao, despesa, subdespesa, conta,
        notaFiscal, cheque, chequeCompensado, situacao,
        valorMinimo, valorMaximo, faixaSobreValorPago);

    return Results.Ok(ResultadoDto.De(repo.Consultar(consulta)));
})
.RequireAuthorization()
.WithName("ConsultarLancamentos")
.WithTags("Lançamentos")
.WithSummary("Consulta lançamentos com filtros")
.WithDescription(
    "Equivale às duas abas de pesquisa da tela de lançamentos do legado.\n\n" +
    "**Período**: sem `inicio` e `fim`, usa os últimos seis meses até hoje — o mesmo padrão " +
    "da tela atual.\n\n" +
    "**porData**: `vencimento` (padrão), `pagamento` ou `cadastro`. Define qual coluna o " +
    "período filtra. No legado, a busca por nota fiscal e por status filtra por cadastro, e " +
    "as demais por vencimento.\n\n" +
    "**pagamento**: `todos` (padrão), `pagos` ou `naopagos`.\n\n" +
    "**situacao**: `aguardando`, `liberada` ou `nenhuma`.\n\n" +
    "**chequeCompensado**: diferente do legado, encontra também os 9 registros gravados com " +
    "`s` minúsculo, que a busca atual não acha por ser sensível a caixa.\n\n" +
    "**valorMinimo / valorMaximo**: aplicam-se ao valor previsto, ou ao valor pago se " +
    "`faixaSobreValorPago=true`.");

// ---- Exportação da consulta para planilha ----
// Mesmos filtros da consulta acima, de propósito: é a mesma consulta, entregue em outro
// formato. Ver docs/fluxos.md, item 11.
app.MapGet("/lancamentos/exportar", (
    RepositorioLancamentos repo,
    DateOnly? inicio, DateOnly? fim,
    string? porData, string? pagamento,
    string? descricao, string? despesa, string? subdespesa, string? conta,
    int? notaFiscal, int? cheque, bool? chequeCompensado, string? situacao,
    decimal? valorMinimo, decimal? valorMaximo, bool? faixaSobreValorPago) =>
{
    var consulta = FiltroDaConsulta.Montar(
        inicio, fim, porData, pagamento, descricao, despesa, subdespesa, conta,
        notaFiscal, cheque, chequeCompensado, situacao,
        valorMinimo, valorMaximo, faixaSobreValorPago);

    var resultado = repo.Consultar(consulta);

    // Planilha vazia não ajuda ninguém: o legado avisa "Não há dados para exportar!" e não
    // abre o Excel. Aqui a recusa vem com a mesma razão, em vez de um arquivo com só o
    // cabeçalho, que parece exportação bem-sucedida.
    if (resultado.Lancamentos.Count == 0)
        throw new RegraDeNegocioException(
            "Não há lançamentos no período e filtros escolhidos para exportar.");

    var planilha = ExportadorDeLancamentos.Gerar(resultado.Lancamentos);
    var nome = $"lancamentos-{DateTime.Today:yyyy-MM-dd}.xlsx";

    return Results.File(planilha, ExportadorDeLancamentos.TipoConteudo, nome);
})
.RequireAuthorization()
.WithTags("Lançamentos")
.WithSummary("Exporta a consulta para uma planilha")
.WithDescription(
    "Aceita exatamente os mesmos filtros de `GET /lancamentos` — é a mesma consulta, entregue " +
    "como `.xlsx`. As colunas e a ordem são as do legado: descrição, valor pago, valor " +
    "previsto, nota fiscal, cheque, vencimento, pagamento e conta, com a linha de totais no fim.\n\n" +
    "⚠️ **Divergências intencionais:** não depende do Excel instalado, ao contrário do legado, " +
    "que usa automação OLE; os valores saem exatos, porque já são decimais desde a leitura, " +
    "enquanto lá o arredondamento acontece só na exportação e a planilha pode divergir do " +
    "banco; e a linha de total é escrita sob as colunas certas, não em posições fixas.");

// ---- Aviso de vencimentos da tela principal ----
// "DATA_VENCIMENTO <= hoje AND PAGO = 0"
app.MapGet("/lancamentos/vencimentos", (RepositorioLancamentos repo, DateOnly? ate) =>
{
    var referencia = ate ?? DateOnly.FromDateTime(DateTime.Today);
    return Results.Ok(ResultadoDto.De(repo.Vencimentos(referencia)));
})
.RequireAuthorization()
.WithName("Vencimentos")
.WithTags("Lançamentos")
.WithSummary("O que está vencido ou vence hoje e ainda não foi pago")
.WithDescription(
    "Alimenta o aviso \"Há N despesa(s) a pagar\" que o legado mostra ao abrir.\n\n" +
    "Reproduz exatamente `DATA_VENCIMENTO <= hoje AND PAGO = 0`. O parâmetro `ate` permite " +
    "usar outra data de referência em vez de hoje.");

// ---- Consolidado por despesa ----
// Atenção à regra central: 'pagos' filtra por DATA_PAGAMENTO e 'naopagos' por DATA_VENCIMENTO.
app.MapGet("/relatorios/por-despesa", (
    RepositorioLancamentos repo, string despesa,
    DateOnly inicio, DateOnly fim, bool? pagos, string? conta) =>
{
    if (string.IsNullOrWhiteSpace(despesa))
        return Results.BadRequest(new { erro = "Informe a despesa a consolidar." });

    var linhas = repo.ConsolidarPorDespesa(
        despesa, new Periodo(inicio, fim), pagos ?? true, conta);
    return Results.Ok(linhas.Select(TotalPorSubdespesaDto.De).ToList());
})
.RequireAuthorization()
.WithName("ConsolidadoPorDespesa")
.WithTags("Relatórios")
.WithSummary("Consolida uma despesa por subdespesa, dentro de um período")
.WithDescription(
    "Equivale à tela de consulta por despesa do legado.\n\n" +
    "**A regra central deste relatório é a troca da coluna de data conforme o modo:**\n\n" +
    "- `pagos=true` (padrão) filtra por `DATA_PAGAMENTO` e traz só o que foi pago — " +
    "responde \"quanto gastei\", olhando quando o dinheiro saiu.\n" +
    "- `pagos=false` filtra por `DATA_VENCIMENTO` e traz só o que está em aberto — " +
    "responde \"quanto devo\", olhando quando vence.\n\n" +
    "Os dois modos sobre o mesmo período dão recortes diferentes, e isso é intencional.\n\n" +
    "`conta` é opcional e recorta o consolidado a uma conta só — responde \"quanto saiu " +
    "desta conta, nesta despesa\". Sem ela, o resultado é o de sempre.");

app.Run();

public partial class Program { }
