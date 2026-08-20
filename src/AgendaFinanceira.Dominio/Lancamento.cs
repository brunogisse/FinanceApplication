namespace AgendaFinanceira.Dominio;

/// <summary>Situação de liberação do lançamento (coluna SITUACAO_STATUS).</summary>
public enum SituacaoStatus
{
    /// <summary>Sem status. É o caso de 13.458 dos 13.972 lançamentos.</summary>
    Nenhuma = 0,
    Aguardando = 1,
    Liberada = 2
}

/// <summary>
/// Um lançamento de despesa — a tabela REGISTRO_DE_GASTOS.
///
/// Nomes de domínio seguem a tela do legado, não o banco: o que a tabela chama de CATEGORIA a
/// operadora chama de Despesa, e SUBCATEGORIA é Subdespesa.
/// </summary>
public sealed record Lancamento
{
    public required int Id { get; init; }
    public required string Descricao { get; init; }

    public required int DespesaId { get; init; }
    public required string Despesa { get; init; }
    public required int SubdespesaId { get; init; }
    public required string Subdespesa { get; init; }
    public required int ContaId { get; init; }
    public required string Conta { get; init; }
    public required int FormaPagamentoId { get; init; }
    public required string FormaPagamento { get; init; }

    public required Dinheiro ValorPrevisto { get; init; }
    public required Dinheiro ValorPago { get; init; }
    public required bool Pago { get; init; }

    /// <summary>Nulo quando o legado gravou o zero do TDateTime (30/12/1899). São 11 registros.</summary>
    public required DateOnly? DataVencimento { get; init; }
    public required DateOnly? DataPagamento { get; init; }
    public required DateOnly? DataCadastro { get; init; }

    public int? NotaFiscal { get; init; }
    public int? Cheque { get; init; }

    /// <summary>
    /// Lido sem diferenciar maiúscula de minúscula. O legado tem 9 registros gravados com 's'
    /// minúsculo que a busca dele, sensível a caixa, nunca encontra.
    /// </summary>
    public bool ChequeCompensado { get; init; }

    public SituacaoStatus Situacao { get; init; }
    public string? Observacao { get; init; }
    public required int UsuarioId { get; init; }

    /// <summary>
    /// Vínculo com CADASTRO_NF do módulo de estoque, que não é migrado. Dado opaco, mantido
    /// só para não se perder. Há 5 valores apontando para notas inexistentes.
    /// </summary>
    public int? EntradaId { get; init; }

    /// <summary>Está vencido e ainda não foi pago, na data de referência informada.</summary>
    public bool EstaVencido(DateOnly hoje) =>
        !Pago && DataVencimento is not null && DataVencimento <= hoje;
}
