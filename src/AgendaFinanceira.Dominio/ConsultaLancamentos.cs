namespace AgendaFinanceira.Dominio;

/// <summary>Intervalo de datas de calendário, com início e fim inclusivos.</summary>
public readonly record struct Periodo
{
    public DateOnly Inicio { get; }
    public DateOnly Fim { get; }

    public Periodo(DateOnly inicio, DateOnly fim)
    {
        if (fim < inicio)
            throw new ArgumentException($"O fim ({fim:dd/MM/yyyy}) é anterior ao início ({inicio:dd/MM/yyyy}).");
        Inicio = inicio;
        Fim = fim;
    }

    /// <summary>Padrão da tela de lançamentos do legado: últimos seis meses até hoje.</summary>
    public static Periodo UltimosSeisMeses(DateOnly hoje) =>
        new(hoje.AddMonths(-6), hoje);

    public bool Contem(DateOnly data) => data >= Inicio && data <= Fim;
    public override string ToString() => $"{Inicio:dd/MM/yyyy} a {Fim:dd/MM/yyyy}";
}

/// <summary>Filtro de situação de pagamento, como o combo do legado.</summary>
public enum FiltroPagamento { Todos = 0, Pagos = 1, NaoPagos = 2 }

/// <summary>
/// Qual coluna de data o período filtra.
///
/// É a regra que mais se perde na reimplementação: a consulta por despesa do legado troca a
/// coluna conforme o modo — "quanto gastei" olha quando o dinheiro saiu, "quanto devo" olha
/// quando vence.
/// </summary>
public enum ColunaDeData { Vencimento = 0, Pagamento = 1, Cadastro = 2 }

/// <summary>Critérios de consulta de lançamentos, equivalentes aos filtros das duas abas do legado.</summary>
public sealed record ConsultaLancamentos
{
    public required Periodo Periodo { get; init; }
    public ColunaDeData FiltrarPorData { get; init; } = ColunaDeData.Vencimento;
    public FiltroPagamento Pagamento { get; init; } = FiltroPagamento.Todos;

    /// <summary>Trecho procurado na descrição, em qualquer posição.</summary>
    public string? Descricao { get; init; }

    public string? Subdespesa { get; init; }
    public string? Despesa { get; init; }
    public string? Conta { get; init; }

    public int? NotaFiscal { get; init; }
    public int? Cheque { get; init; }
    public bool? ChequeCompensado { get; init; }
    public SituacaoStatus? Situacao { get; init; }

    public Dinheiro? ValorMinimo { get; init; }
    public Dinheiro? ValorMaximo { get; init; }

    /// <summary>Sobre qual valor a faixa se aplica. O legado só permite um dos dois por vez.</summary>
    public bool FaixaSobreValorPago { get; init; }
}

/// <summary>Resultado de uma consulta, com os totais que o rodapé do legado exibe.</summary>
public sealed record ResultadoConsulta
{
    public required IReadOnlyList<Lancamento> Lancamentos { get; init; }
    public required Dinheiro TotalPrevisto { get; init; }
    public required Dinheiro TotalPago { get; init; }
    public int Quantidade => Lancamentos.Count;

    public static ResultadoConsulta De(IReadOnlyList<Lancamento> lancamentos) => new()
    {
        Lancamentos = lancamentos,
        TotalPrevisto = lancamentos.Somar(l => l.ValorPrevisto),
        TotalPago = lancamentos.Somar(l => l.ValorPago)
    };
}

/// <summary>Uma linha do consolidado por despesa, agrupada por subdespesa.</summary>
public sealed record TotalPorSubdespesa
{
    public required int SubdespesaId { get; init; }
    public required string Subdespesa { get; init; }
    public required string Despesa { get; init; }
    public required Dinheiro TotalPrevisto { get; init; }
    public required Dinheiro TotalPago { get; init; }
    public required int Quantidade { get; init; }
}
