using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Api;

/// <summary>
/// Contratos de saída da API. São DTOs, nunca entidades cruas — evita over-posting e deixa a
/// forma do JSON independente do domínio.
///
/// Valores monetários viajam como decimal. Nunca como double: o JavaScript do cliente não tem
/// decimal nativo, e é responsabilidade dele tratar isso como texto ou centavos.
/// </summary>
public sealed record LancamentoDto
{
    public required int Id { get; init; }
    public required string Descricao { get; init; }
    public required string Despesa { get; init; }
    public required string Subdespesa { get; init; }
    public required string Conta { get; init; }
    public required string FormaPagamento { get; init; }
    public required decimal ValorPrevisto { get; init; }
    public required decimal ValorPago { get; init; }
    public required bool Pago { get; init; }
    public DateOnly? DataVencimento { get; init; }
    public DateOnly? DataPagamento { get; init; }
    public DateOnly? DataCadastro { get; init; }
    public int? NotaFiscal { get; init; }
    public int? Cheque { get; init; }
    public bool ChequeCompensado { get; init; }
    public required string Situacao { get; init; }
    public string? Observacao { get; init; }
    public required int UsuarioId { get; init; }

    public static LancamentoDto De(Lancamento l) => new()
    {
        Id = l.Id,
        Descricao = l.Descricao,
        Despesa = l.Despesa,
        Subdespesa = l.Subdespesa,
        Conta = l.Conta,
        FormaPagamento = l.FormaPagamento,
        ValorPrevisto = l.ValorPrevisto.Valor,
        ValorPago = l.ValorPago.Valor,
        Pago = l.Pago,
        DataVencimento = l.DataVencimento,
        DataPagamento = l.DataPagamento,
        DataCadastro = l.DataCadastro,
        NotaFiscal = l.NotaFiscal,
        Cheque = l.Cheque,
        ChequeCompensado = l.ChequeCompensado,
        // Enum como texto: legível na consulta e imune a reordenação.
        Situacao = l.Situacao.ToString(),
        Observacao = l.Observacao,
        UsuarioId = l.UsuarioId
    };
}

public sealed record ResultadoDto
{
    public required IReadOnlyList<LancamentoDto> Lancamentos { get; init; }
    public required int Quantidade { get; init; }
    public required decimal TotalPrevisto { get; init; }
    public required decimal TotalPago { get; init; }

    public static ResultadoDto De(ResultadoConsulta r) => new()
    {
        Lancamentos = r.Lancamentos.Select(LancamentoDto.De).ToList(),
        Quantidade = r.Quantidade,
        TotalPrevisto = r.TotalPrevisto.Valor,
        TotalPago = r.TotalPago.Valor
    };
}

public sealed record TotalPorSubdespesaDto
{
    public required int SubdespesaId { get; init; }
    public required string Subdespesa { get; init; }
    public required string Despesa { get; init; }
    public required int Quantidade { get; init; }
    public required decimal TotalPrevisto { get; init; }
    public required decimal TotalPago { get; init; }

    public static TotalPorSubdespesaDto De(TotalPorSubdespesa t) => new()
    {
        SubdespesaId = t.SubdespesaId,
        Subdespesa = t.Subdespesa,
        Despesa = t.Despesa,
        Quantidade = t.Quantidade,
        TotalPrevisto = t.TotalPrevisto.Valor,
        TotalPago = t.TotalPago.Valor
    };
}
