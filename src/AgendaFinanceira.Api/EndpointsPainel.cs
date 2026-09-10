using AgendaFinanceira.Dominio;
using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Api;

public static class EndpointsPainel
{
    public static void MapearPainel(this WebApplication app)
    {
        app.MapGet("/painel", (RepositorioPainel repo, System.Security.Claims.ClaimsPrincipal quem,
                               string? mes) =>
        {
            var hoje = DateOnly.FromDateTime(DateTime.Today);
            var referencia = LerMes(mes) ?? new DateOnly(hoje.Year, hoje.Month, 1);

            var p = repo.Montar(referencia, hoje, quem.SetorDaSessao());

            return Results.Ok(new
            {
                mes = p.Mes.ToString("yyyy-MM"),
                vencido = Montante(p.Vencido),
                venceEmSeteDias = Montante(p.VenceEmSeteDias),
                pagoNoMes = Montante(p.PagoNoMes),
                pagoNoMesAnterior = Montante(p.PagoNoMesAnterior),
                previstoNoMes = Montante(p.PrevistoNoMes),
                porDespesa = p.PorDespesa.Select(d => new
                {
                    despesa = d.Despesa,
                    quantidade = d.Quantidade,
                    total = d.Total.Valor
                }),
                serie = p.Serie.Select(m => new
                {
                    mes = m.Mes.ToString("yyyy-MM"),
                    previsto = m.Previsto.Valor,
                    pago = m.Pago.Valor
                }),
                dias = p.Dias.Select(d => new
                {
                    data = d.Data.ToString("yyyy-MM-dd"),
                    quantidade = d.Quantidade,
                    total = d.Total.Valor,
                    aPagar = d.APagar
                })
            });
        })
        .RequireAuthorization()
        .WithTags("Painel")
        .WithSummary("Os números da tela inicial")
        .WithDescription(
            "Informe `mes` como `aaaa-mm`; sem ele, o mês corrente.\n\n" +
            "Todos os números são do **setor de quem está autenticado**, que vem do token e não " +
            "de parâmetro. Ver docs/unificacao-das-bases.md.\n\n" +
            "**Este sistema é contas a pagar.** Não há receita em lugar nenhum do banco, " +
            "então o painel não tem entrada, sobra nem saldo — teria de inventar número. O que " +
            "ele mostra é compromisso:\n\n" +
            "- **vencido**: a pagar com vencimento até hoje. É a mesma condição do aviso que o " +
            "legado dá ao abrir, e portanto o número que a operadora já conhece.\n" +
            "- **venceEmSeteDias**: a pagar nos sete dias seguintes. Não se sobrepõe ao vencido.\n" +
            "- **pagoNoMes** e **pagoNoMesAnterior**: pelo pagamento, para dar a comparação.\n" +
            "- **previstoNoMes**: tudo que vence no mês, pago ou não.\n" +
            "- **porDespesa**: para onde o dinheiro foi no mês, do maior para o menor.\n" +
            "- **serie**: doze meses; previsto conta por vencimento e pago por pagamento, " +
            "porque são grandezas de colunas de data diferentes.\n" +
            "- **dias**: os dias do mês com vencimento, para o calendário.\n\n" +
            "Todas as somas convertem para decimal **antes** de somar. `SUM` direto sobre as " +
            "colunas `FLOAT` do legado acumularia erro linha a linha.");

        static object Montante(Montante m) => new { quantidade = m.Quantidade, total = m.Total.Valor };
    }

    /// <summary>Lê `aaaa-mm`. Formato inválido vira nulo, e o chamador decide o padrão.</summary>
    private static DateOnly? LerMes(string? texto)
    {
        if (string.IsNullOrWhiteSpace(texto)) return null;
        return DateOnly.TryParse(texto + "-01", out var d) ? d : null;
    }
}
