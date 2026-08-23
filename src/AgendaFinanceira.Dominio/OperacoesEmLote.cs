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

/// <summary>
/// O que saiu da leitura de uma planilha.
///
/// Traz mais que as linhas porque a leitura descarta coisas de propósito — preâmbulo e
/// créditos —, e quem descarta em silêncio some com dado sem ninguém ver.
/// </summary>
public sealed record LeituraDaPlanilha
{
    public required IReadOnlyList<LinhaImportada> Linhas { get; init; }

    /// <summary>Linhas de crédito que ficaram de fora. Ver a nota no leitor.</summary>
    public required int CreditosIgnorados { get; init; }

    /// <summary>
    /// Linhas que tinham valor mas não data, e herdaram a da linha anterior — o extrato não
    /// repete a data dentro do mesmo dia. Contado para a prévia poder dizer.
    /// </summary>
    public required int DatasHerdadas { get; init; }

    /// <summary>Onde os dados de fato começaram — depois do título e do cabeçalho.</summary>
    public required int PrimeiraLinhaComDados { get; init; }
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

/// <summary>
/// Uma parcela como quem opera decidiu que ela deve ficar.
///
/// Existe porque parcela igual é o caso comum, não a regra: financiamento com juros, entrada
/// maior, acerto de centavo no fim. Antes, quem quisesse valores diferentes tinha de deixar o
/// sistema dividir e depois caçar cada parcela na grade — e elas nascem uma por mês, então a
/// maioria cai fora do período em tela assim que o parcelamento termina.
/// </summary>
public sealed record ParcelaAjustada
{
    public required Dinheiro ValorPrevisto { get; init; }
    public required DateOnly DataVencimento { get; init; }
    public required string Descricao { get; init; }
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
    /// Confere a lista que veio da tela e devolve as parcelas com a descrição já normalizada.
    ///
    /// **A soma não precisa fechar o valor original, e isso é decisão de quem opera.** Juros de
    /// financiamento fazem a soma passar do previsto legitimamente. Quem chama recebe
    /// <see cref="ResultadoParcelamento.Fechou"/> para dizer se bateu; recusar aqui obrigaria a
    /// operadora a lançar tudo de novo por fora.
    /// </summary>
    public static IReadOnlyList<ParcelaAjustada> ExigirParcelasValidas(
        IReadOnlyList<ParcelaAjustada> parcelas)
    {
        ExigirQuantidadeValida(parcelas.Count);

        var conferidas = new List<ParcelaAjustada>(parcelas.Count);

        for (var i = 0; i < parcelas.Count; i++)
        {
            var p = parcelas[i];
            var numero = i + 1;

            // Zero passaria pelo banco sem reclamar e viraria uma linha que ninguém cobra —
            // some da conta sem sumir da lista.
            if (p.ValorPrevisto.EhZero)
                throw new RegraDeNegocioException(
                    $"A parcela {numero} está sem valor. Informe um valor maior que zero.");

            if (p.ValorPrevisto < Dinheiro.Zero)
                throw new RegraDeNegocioException(
                    $"A parcela {numero} tem valor negativo. Este sistema é de contas a pagar.");

            conferidas.Add(p with
            {
                Descricao = ValidacaoCadastro.ExigirDescricao(
                    p.Descricao, DadosLancamento.TamanhoMaximoDescricao,
                    $"descrição da parcela {numero}")
            });
        }

        return conferidas;
    }

    /// <summary>
    /// A divisão padrão, que a tela mostra já preenchida: valor repartido em centavos inteiros
    /// com o resto nas primeiras parcelas, uma por mês a partir do vencimento original.
    /// </summary>
    public static IReadOnlyList<ParcelaAjustada> DivisaoPadrao(
        Dinheiro valor, DateOnly vencimento, string descricao, int parcelas)
    {
        ExigirQuantidadeValida(parcelas);

        var valores = valor.Dividir(parcelas);

        return Enumerable.Range(1, parcelas).Select(numero => new ParcelaAjustada
        {
            ValorPrevisto = valores[numero - 1],
            DataVencimento = VencimentoDaParcela(vencimento, numero),
            Descricao = DescricaoDaParcela(descricao, numero, parcelas)
        }).ToList();
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
