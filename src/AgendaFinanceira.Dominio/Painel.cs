namespace AgendaFinanceira.Dominio;

/// <summary>Uma contagem com o dinheiro que ela representa.</summary>
public sealed record Montante
{
    public required int Quantidade { get; init; }
    public required Dinheiro Total { get; init; }

    public static readonly Montante Zero = new() { Quantidade = 0, Total = Dinheiro.Zero };
}

/// <summary>Quanto uma despesa consumiu no período.</summary>
public sealed record TotalPorDespesa
{
    public required string Despesa { get; init; }
    public required int Quantidade { get; init; }
    public required Dinheiro Total { get; init; }
}

/// <summary>Um mês da série histórica.</summary>
public sealed record MesDaSerie
{
    /// <summary>Primeiro dia do mês, para o cliente formatar como quiser.</summary>
    public required DateOnly Mes { get; init; }
    public required Dinheiro Previsto { get; init; }
    public required Dinheiro Pago { get; init; }
}

/// <summary>Um dia do mês no calendário.</summary>
public sealed record DiaDoMes
{
    public required DateOnly Data { get; init; }
    public required int Quantidade { get; init; }
    public required Dinheiro Total { get; init; }

    /// <summary>Quantos ainda não foram pagos. É o que pinta o dia no calendário.</summary>
    public required int APagar { get; init; }
}

/// <summary>
/// Os números da tela inicial.
///
/// **Este sistema é contas a pagar.** Não há receita em lugar nenhum do banco, então não
/// existe entrada, sobra nem saldo — e um painel que mostrasse "saldo" estaria inventando
/// número. O que existe é compromisso: o que venceu, o que está chegando, o que já saiu e
/// para onde foi.
/// </summary>
public sealed record Painel
{
    /// <summary>Mês de referência do painel.</summary>
    public required DateOnly Mes { get; init; }

    /// <summary>
    /// A pagar com vencimento até hoje.
    ///
    /// É exatamente o aviso que o legado dá ao abrir o sistema — "Há N despesa(s) a pagar" —,
    /// e portanto o número que a operadora conhece há três anos. Inclui o dia de hoje, como lá.
    /// </summary>
    public required Montante Vencido { get; init; }

    /// <summary>A pagar nos sete dias seguintes a hoje. Não se sobrepõe ao vencido.</summary>
    public required Montante VenceEmSeteDias { get; init; }

    /// <summary>Pago dentro do mês de referência, pela data de pagamento.</summary>
    public required Montante PagoNoMes { get; init; }

    /// <summary>O mesmo do mês anterior, só para dar a comparação.</summary>
    public required Montante PagoNoMesAnterior { get; init; }

    /// <summary>Tudo que vence no mês, pago ou não. É o compromisso do período.</summary>
    public required Montante PrevistoNoMes { get; init; }

    /// <summary>Para onde o dinheiro foi no mês, por despesa, do maior para o menor.</summary>
    public required IReadOnlyList<TotalPorDespesa> PorDespesa { get; init; }

    /// <summary>Doze meses terminando no mês de referência.</summary>
    public required IReadOnlyList<MesDaSerie> Serie { get; init; }

    /// <summary>Os dias do mês que têm vencimento, para o calendário.</summary>
    public required IReadOnlyList<DiaDoMes> Dias { get; init; }
}
