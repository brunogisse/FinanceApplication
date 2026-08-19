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
builder.Services.AddProblemDetails();

var app = builder.Build();

// O erro que chega ao cliente é a razão real da recusa, não uma mensagem genérica.
app.UseExceptionHandler();

app.MapGet("/saude", () => Results.Ok(new { situacao = "no ar", banco = Path.GetFileName(caminhoBanco) }));

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
.WithName("ConsultarLancamentos");

// ---- Aviso de vencimentos da tela principal ----
// "DATA_VENCIMENTO <= hoje AND PAGO = 0"
app.MapGet("/lancamentos/vencimentos", (RepositorioLancamentos repo, DateOnly? ate) =>
{
    var referencia = ate ?? DateOnly.FromDateTime(DateTime.Today);
    return Results.Ok(ResultadoDto.De(repo.Vencimentos(referencia)));
})
.WithName("Vencimentos");

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
.WithName("ConsolidadoPorDespesa");

app.Run();

public partial class Program { }
