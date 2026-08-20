using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Api;

/// <summary>
/// Traduz os parâmetros de consulta da URL para o filtro de domínio.
///
/// Mora aqui, e não dentro de um endpoint, porque duas rotas precisam da tradução idêntica:
/// a consulta que enche a grade e a exportação da mesma consulta. Se cada uma interpretasse
/// os parâmetros por conta própria, a planilha poderia trazer um conjunto diferente do que
/// está na tela — que é exatamente o tipo de divergência silenciosa que ninguém percebe até
/// alguém somar os dois e ver que não bate.
/// </summary>
public static class FiltroDaConsulta
{
    public static ConsultaLancamentos Montar(
        DateOnly? inicio, DateOnly? fim,
        string? porData, string? pagamento,
        string? descricao, string? despesa, string? subdespesa, string? conta,
        int? notaFiscal, int? cheque, bool? chequeCompensado, string? situacao,
        decimal? valorMinimo, decimal? valorMaximo, bool? faixaSobreValorPago)
    {
        var hoje = DateOnly.FromDateTime(DateTime.Today);
        var periodo = inicio is not null && fim is not null
            ? new Periodo(inicio.Value, fim.Value)
            : Periodo.UltimosSeisMeses(hoje);   // mesmo padrão da tela do legado

        return new ConsultaLancamentos
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
    }
}
