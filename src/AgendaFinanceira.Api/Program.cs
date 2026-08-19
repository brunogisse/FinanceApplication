using AgendaFinanceira.Api;
using AgendaFinanceira.Dominio;
using AgendaFinanceira.Infraestrutura;

var builder = WebApplication.CreateBuilder(args);

// O caminho do banco vem da configuração. Nunca é fixo no código, ao contrário do backup
// automático do legado, que aponta para a área de trabalho de um usuário específico.
var caminhoBanco = builder.Configuration["Banco:Caminho"]
    ?? throw new InvalidOperationException(
        "Configure 'Banco:Caminho' no appsettings.json apontando para o banco Firebird. " +
        "Na etapa de leitura, aponte para uma cópia, não para produção.");

builder.Services.AddSingleton(new ConexaoFirebird(caminhoBanco));
builder.Services.AddSingleton<RepositorioLancamentos>();
builder.Services.AddSingleton<RepositorioCadastros>();
builder.Services.AddSingleton<IServicoSenha, ServicoSenhaBCrypt>();
builder.Services.AddSingleton<RepositorioUsuarios>();
builder.Services.AddProblemDetails();

// Falha fechada: sem chave de assinatura, a API não sobe.
builder.Services.AdicionarAutenticacao(ConfiguracaoAutenticacao.ExigirChave(builder.Configuration));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new()
    {
        Title = "Agenda Financeira — API",
        Version = "v1",
        Description =
            "Contas a pagar do grupo Juliatti de Carvalho.\n\n" +
            "**Etapa 4 da migração.** Consultas, cadastros de apoio e lançamentos.\n\n" +
            "Lançamentos já podem ser criados, alterados e excluídos. Parcelamento, pagamento " +
            "em lote e importação por planilha continuam no Delphi, sobre a mesma base.\n\n" +
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

app.UseAuthentication();
app.UseAuthorization();

// Quem abrir a raiz vai para a documentação.
app.MapGet("/", () => Results.Redirect("/swagger")).ExcludeFromDescription();

app.MapearCadastros();
app.MapearLancamentos();

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
    var hoje = DateOnly.FromDateTime(DateTime.Today);
    var periodo = inicio is not null && fim is not null
        ? new Periodo(inicio.Value, fim.Value)
        : Periodo.UltimosSeisMeses(hoje);   // mesmo padrão da tela do legado

    var consulta = new ConsultaLancamentos
    {
        Periodo = periodo,
        FiltrarPorData = porData?.ToLowerInvariant() switch
        {
            "pagamento" => ColunaDeData.Pagamento,
            "cadastro" => ColunaDeData.Cadastro,
            _ => ColunaDeData.Vencimento
        },
        Pagamento = pagamento?.ToLowerInvariant() switch
        {
            "pagos" => FiltroPagamento.Pagos,
            "naopagos" => FiltroPagamento.NaoPagos,
            _ => FiltroPagamento.Todos
        },
        Descricao = descricao,
        Despesa = despesa,
        Subdespesa = subdespesa,
        Conta = conta,
        NotaFiscal = notaFiscal,
        Cheque = cheque,
        ChequeCompensado = chequeCompensado,
        Situacao = situacao?.ToLowerInvariant() switch
        {
            "aguardando" => SituacaoStatus.Aguardando,
            "liberada" => SituacaoStatus.Liberada,
            "nenhuma" => SituacaoStatus.Nenhuma,
            _ => null
        },
        ValorMinimo = valorMinimo is null ? null : Dinheiro.De(valorMinimo.Value),
        ValorMaximo = valorMaximo is null ? null : Dinheiro.De(valorMaximo.Value),
        FaixaSobreValorPago = faixaSobreValorPago ?? false
    };

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
    DateOnly inicio, DateOnly fim, bool? pagos) =>
{
    if (string.IsNullOrWhiteSpace(despesa))
        return Results.BadRequest(new { erro = "Informe a despesa a consolidar." });

    var linhas = repo.ConsolidarPorDespesa(despesa, new Periodo(inicio, fim), pagos ?? true);
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
    "Os dois modos sobre o mesmo período dão recortes diferentes, e isso é intencional.");

app.Run();

public partial class Program { }
