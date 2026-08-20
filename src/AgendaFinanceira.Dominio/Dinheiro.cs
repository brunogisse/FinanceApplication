using System.Globalization;

namespace AgendaFinanceira.Dominio;

/// <summary>
/// Valor monetário em reais, com duas casas decimais.
///
/// Existe por causa do defeito central do legado: as colunas VALOR_PAGO, VALOR_PREVISTO e
/// VALOR_MAXIMO são FLOAT no Firebird, precisão simples. Isso deixou 471 lançamentos com valor
/// que não fecha em dois decimais e 30 acima do limite de precisão do tipo.
///
/// Este tipo torna esse erro impossível de repetir: não há como construí-lo a partir de ponto
/// flutuante, e a divisão distribui o resto para que a soma das partes seja sempre igual ao todo.
/// </summary>
public readonly record struct Dinheiro : IComparable<Dinheiro>
{
    private readonly decimal _valor;

    private Dinheiro(decimal valor) => _valor = valor;

    public static readonly Dinheiro Zero = new(0m);

    /// <summary>Cria a partir de um decimal, arredondando para duas casas.</summary>
    public static Dinheiro De(decimal valor) =>
        new(Math.Round(valor, 2, MidpointRounding.AwayFromZero));

    /// <summary>Cria a partir da quantidade de centavos. É a forma exata.</summary>
    public static Dinheiro DeCentavos(long centavos) => new(centavos / 100m);

    /// <summary>
    /// Cria a partir do que veio de uma coluna FLOAT do legado. O valor lido nunca foi o valor
    /// pretendido — R$ 147.059,765625 é R$ 147.059,77 mal guardado —, então arredondar para duas
    /// casas é a interpretação correta, não uma perda.
    /// </summary>
    public static Dinheiro DeFloatDoLegado(double valorDoBanco) =>
        new(Math.Round((decimal)valorDoBanco, 2, MidpointRounding.AwayFromZero));

    // Barreiras de compilação: dinheiro não nasce de ponto flutuante.
    [Obsolete("Dinheiro nunca é construído a partir de double. Use De(decimal) ou, para ler " +
              "uma coluna FLOAT do legado, DeFloatDoLegado(double).", error: true)]
    public static Dinheiro De(double valor) => throw new NotSupportedException();

    [Obsolete("Dinheiro nunca é construído a partir de float. Use De(decimal).", error: true)]
    public static Dinheiro De(float valor) => throw new NotSupportedException();

    public decimal Valor => _valor;
    public long Centavos => (long)Math.Round(_valor * 100m, 0, MidpointRounding.AwayFromZero);
    public bool EhZero => _valor == 0m;
    public bool EhNegativo => _valor < 0m;

    /// <summary>
    /// Divide em <paramref name="partes"/> parcelas cuja soma é exatamente igual ao todo.
    ///
    /// O legado divide direto e perde dinheiro: R$ 20.000,00 em 12 vira doze parcelas de
    /// R$ 1.666,666626, que somam R$ 19.999,9995. Aqui a divisão é feita em centavos e o resto
    /// é distribuído — as primeiras parcelas recebem um centavo a mais, de forma determinística.
    ///
    /// Para R$ 20.000,00 em 12: oito parcelas de R$ 1.666,67 e quatro de R$ 1.666,66.
    /// </summary>
    public Dinheiro[] Dividir(int partes)
    {
        if (partes <= 0)
            throw new ArgumentOutOfRangeException(nameof(partes),
                "O número de parcelas precisa ser maior que zero.");

        var totalCentavos = Centavos;
        var negativo = totalCentavos < 0;
        var absoluto = Math.Abs(totalCentavos);

        var baseCentavos = absoluto / partes;
        var resto = (int)(absoluto % partes);

        var resultado = new Dinheiro[partes];
        for (var i = 0; i < partes; i++)
        {
            var centavos = baseCentavos + (i < resto ? 1 : 0);
            resultado[i] = DeCentavos(negativo ? -centavos : centavos);
        }
        return resultado;
    }

    public static Dinheiro operator +(Dinheiro a, Dinheiro b) => DeCentavos(a.Centavos + b.Centavos);
    public static Dinheiro operator -(Dinheiro a, Dinheiro b) => DeCentavos(a.Centavos - b.Centavos);
    public static Dinheiro operator -(Dinheiro a) => DeCentavos(-a.Centavos);
    public static bool operator >(Dinheiro a, Dinheiro b) => a._valor > b._valor;
    public static bool operator <(Dinheiro a, Dinheiro b) => a._valor < b._valor;
    public static bool operator >=(Dinheiro a, Dinheiro b) => a._valor >= b._valor;
    public static bool operator <=(Dinheiro a, Dinheiro b) => a._valor <= b._valor;

    public int CompareTo(Dinheiro outro) => _valor.CompareTo(outro._valor);

    private static readonly CultureInfo PtBr = CultureInfo.GetCultureInfo("pt-BR");

    /// <summary>Formata como R$ 1.234,56.</summary>
    public override string ToString() => _valor.ToString("C", PtBr);

    /// <summary>Formata sem o símbolo, como 1.234,56.</summary>
    public string SemSimbolo() => _valor.ToString("N2", PtBr);
}

/// <summary>Soma de valores monetários sem passar por ponto flutuante em momento algum.</summary>
public static class DinheiroExtensoes
{
    public static Dinheiro Somar(this IEnumerable<Dinheiro> valores)
    {
        long centavos = 0;
        foreach (var v in valores) centavos += v.Centavos;
        return Dinheiro.DeCentavos(centavos);
    }

    public static Dinheiro Somar<T>(this IEnumerable<T> itens, Func<T, Dinheiro> seletor)
    {
        long centavos = 0;
        foreach (var item in itens) centavos += seletor(item).Centavos;
        return Dinheiro.DeCentavos(centavos);
    }
}
