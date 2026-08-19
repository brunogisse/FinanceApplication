namespace AgendaFinanceira.Dominio;

/// <summary>
/// Dados informados para criar ou alterar um lançamento.
///
/// As regras que este tipo valida estão hoje espalhadas em eventos de tela do Delphi —
/// ver docs/dominio.md, "Módulo: Lançamentos". Aqui elas ficam num lugar só e testável.
/// </summary>
public sealed record DadosLancamento
{
    public required string Descricao { get; init; }

    /// <summary>
    /// A subdespesa determina a despesa: no legado, escolher a subdespesa preenche os dois
    /// campos juntos, e não há como montar uma combinação inválida. Aqui é o mesmo — a despesa
    /// não é informada, é deduzida.
    /// </summary>
    public required int SubdespesaId { get; init; }

    public required int ContaId { get; init; }
    public required int FormaPagamentoId { get; init; }
    public required Dinheiro ValorPrevisto { get; init; }
    public required DateOnly DataVencimento { get; init; }

    /// <summary>Marcar como já quitado, o que no legado é o "confirmar pagamento" da tela.</summary>
    public bool Pago { get; init; }

    /// <summary>Quando pago e não informada, assume a data de hoje.</summary>
    public DateOnly? DataPagamento { get; init; }

    /// <summary>Quando pago e não informado, assume o valor previsto.</summary>
    public Dinheiro? ValorPago { get; init; }

    public int? NotaFiscal { get; init; }
    public int? Cheque { get; init; }
    public bool ChequeCompensado { get; init; }
    public SituacaoStatus Situacao { get; init; } = SituacaoStatus.Nenhuma;
    public string? Observacao { get; init; }

    public const int TamanhoMaximoDescricao = 200;
    public const int TamanhoMaximoObservacao = 200;

    /// <summary>
    /// Valida e devolve os dados já normalizados, prontos para gravar.
    ///
    /// O legado exige descrição, valor previsto, subdespesa e conta antes de salvar; aqui
    /// vale o mesmo, mais o que o banco exige e ninguém verificava.
    /// </summary>
    public DadosLancamento Validar(DateOnly hoje)
    {
        var descricao = ValidacaoCadastro.ExigirDescricao(Descricao, TamanhoMaximoDescricao);

        if (SubdespesaId <= 0) throw new RegraDeNegocioException("Escolha a subdespesa.");
        if (ContaId <= 0) throw new RegraDeNegocioException("Escolha a conta.");
        if (FormaPagamentoId <= 0) throw new RegraDeNegocioException("Escolha a forma de pagamento.");

        if (ValorPrevisto.EhNegativo)
            throw new RegraDeNegocioException("O valor previsto não pode ser negativo.");

        if (Observacao is not null && Observacao.Length > TamanhoMaximoObservacao)
            throw new RegraDeNegocioException(
                $"A observação pode ter no máximo {TamanhoMaximoObservacao} caracteres.");

        if (NotaFiscal is < 0) throw new RegraDeNegocioException("A nota fiscal não pode ser negativa.");
        if (Cheque is < 0) throw new RegraDeNegocioException("O número do cheque não pode ser negativo.");

        // Coerência entre pago, data e valor. O legado não impõe isso, e a base tem 30
        // lançamentos marcados como pagos sem data de pagamento e 24 pagos com valor zero.
        if (Pago)
        {
            var valorPago = ValorPago ?? ValorPrevisto;
            if (valorPago.EhNegativo)
                throw new RegraDeNegocioException("O valor pago não pode ser negativo.");

            var dataPagamento = DataPagamento ?? hoje;
            if (dataPagamento < DataVencimento.AddYears(-50))
                throw new RegraDeNegocioException("A data de pagamento é anterior demais para ser real.");

            return this with
            {
                Descricao = descricao,
                ValorPago = valorPago,
                DataPagamento = dataPagamento,
                Observacao = Observacao?.Trim()
            };
        }

        // Não pago: zera o valor e limpa a data, exatamente como o legado faz ao salvar.
        return this with
        {
            Descricao = descricao,
            ValorPago = Dinheiro.Zero,
            DataPagamento = null,
            Observacao = Observacao?.Trim()
        };
    }
}
