namespace AgendaFinanceira.Dominio;

/// <summary>Resultado de um parcelamento.</summary>
public sealed record ResultadoParcelamento
{
    public required IReadOnlyList<Lancamento> Parcelas { get; init; }
    public required int IdOriginalExcluido { get; init; }
    public required Dinheiro ValorOriginal { get; init; }

    /// <summary>Soma das parcelas. Por construção, igual ao valor original.</summary>
    public Dinheiro SomaDasParcelas => Parcelas.Somar(p => p.ValorPrevisto);

    /// <summary>
    /// Confere que a divisão fechou. O legado gera doze parcelas de R$ 1.666,666626 para
    /// R$ 20.000,00, que somam R$ 19.999,9995 — e ninguém percebe.
    /// </summary>
    public bool Fechou => SomaDasParcelas == ValorOriginal;
}

/// <summary>
/// Resultado de um pagamento em lote, discriminando o que aconteceu com cada lançamento.
///
/// O legado apenas percorre a grade e não diz nada sobre o que ignorou — pior, trava em laço
/// infinito se encontrar um já pago. Aqui cada item tem destino conhecido.
/// </summary>
public sealed record ResultadoPagamentoEmLote
{
    public required IReadOnlyList<int> Pagos { get; init; }
    public required IReadOnlyList<int> JaEstavamPagos { get; init; }
    public required IReadOnlyList<int> SemPermissao { get; init; }
    public required IReadOnlyList<int> NaoEncontrados { get; init; }
    public required Dinheiro TotalPago { get; init; }

    public int Quantidade => Pagos.Count;
}

/// <summary>Uma linha da planilha de importação, já interpretada.</summary>
public sealed record LinhaImportada
{
    public required DateOnly Data { get; init; }
    public required string Descricao { get; init; }
    public required Dinheiro Valor { get; init; }
    public required int NumeroDaLinha { get; init; }
}

/// <summary>Resultado da importação de um lote.</summary>
public sealed record ResultadoImportacao
{
    public required IReadOnlyList<Lancamento> Lancamentos { get; init; }
    public required Dinheiro Total { get; init; }
    public int Quantidade => Lancamentos.Count;
}

/// <summary>Regras de parcelamento, isoladas para poderem ser testadas sem banco.</summary>
public static class RegrasParcelamento
{
    public const int MinimoDeParcelas = 2;
    public const int MaximoDeParcelas = 360;

    public static void ExigirQuantidadeValida(int parcelas)
    {
        if (parcelas < MinimoDeParcelas)
            throw new RegraDeNegocioException(
                $"O parcelamento precisa de pelo menos {MinimoDeParcelas} parcelas.");

        if (parcelas > MaximoDeParcelas)
            throw new RegraDeNegocioException(
                $"O parcelamento aceita no máximo {MaximoDeParcelas} parcelas.");
    }

    /// <summary>
    /// Vencimento da parcela <paramref name="numero"/>, contando a partir de 1.
    ///
    /// A primeira parcela vence no mês do vencimento original, como no legado — que faz
    /// IncMonth(vencimento, -1) e depois IncMonth(data, i), chegando ao mesmo lugar.
    /// </summary>
    public static DateOnly VencimentoDaParcela(DateOnly vencimentoOriginal, int numero) =>
        vencimentoOriginal.AddMonths(numero - 1);

    /// <summary>Descrição da parcela, no formato "DESCRIÇÃO i/N" que o legado usa.</summary>
    public static string DescricaoDaParcela(string descricaoOriginal, int numero, int total)
    {
        var sufixo = $" {numero}/{total}";
        var espaco = DadosLancamento.TamanhoMaximoDescricao - sufixo.Length;

        // Se a descrição não couber com o sufixo, corta o texto e não o número da parcela:
        // saber que é "3/12" importa mais do que os últimos caracteres do texto.
        var texto = descricaoOriginal.Length > espaco
            ? descricaoOriginal[..espaco].TrimEnd()
            : descricaoOriginal;

        return texto + sufixo;
    }

    public const string ObservacaoPadrao = "Gerada automaticamente pelo parcelamento";
}
