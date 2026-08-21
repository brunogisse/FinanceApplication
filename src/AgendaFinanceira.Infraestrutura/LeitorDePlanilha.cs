using System.Globalization;
using System.Text;
using ClosedXML.Excel;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>
/// Lê a planilha de importação de pagamentos, reproduzindo as regras do legado
/// (docs/fluxos.md, item 5).
///
/// Uma diferença que vale registrar: o legado abre o Excel por automação OLE, o que **exige o
/// Excel instalado na máquina** e deixa processos órfãos quando algo falha. Aqui a planilha é
/// lida diretamente do arquivo, sem depender de nada instalado.
/// </summary>
public static class LeitorDePlanilha
{
    /// <summary>Nome que o legado procura. Não achando, usa a primeira aba.</summary>
    public const string AbaPadrao = "Planilha1";

    /// <summary>Os dados começam na linha 2; a 1 é cabeçalho.</summary>
    public const int PrimeiraLinhaDeDados = 2;

    public static LeituraDaPlanilha Ler(Stream planilha)
    {
        using var arquivo = AbrirArquivo(planilha);

        var aba = arquivo.Worksheets.FirstOrDefault(
                      w => string.Equals(w.Name, AbaPadrao, StringComparison.OrdinalIgnoreCase))
                  ?? arquivo.Worksheets.FirstOrDefault()
                  ?? throw new RegraDeNegocioException("A planilha não tem nenhuma aba.");

        var linhas = new List<LinhaImportada>();
        var creditos = 0;
        var datasHerdadas = 0;
        (int Linha, string Texto)? primeiroTextoSemData = null;
        var ultima = aba.LastRowUsed()?.RowNumber() ?? 0;

        for (var n = PrimeiraLinhaDeDados; n <= ultima; n++)
        {
            var celulaData = aba.Cell(n, 1);
            var celulaValor = aba.Cell(n, 3);
            var descricao = NormalizarDescricao(aba.Cell(n, 2).GetString());
            var textoDaData = celulaData.GetString().Trim();

            if (celulaData.IsEmpty() || string.IsNullOrWhiteSpace(textoDaData))
            {
                // Linha SEM data mas COM valor é um lançamento de verdade: o extrato apenas
                // não repetiu a data do dia. Ela herda a data do registro anterior.
                //
                // Isto conserta uma perda silenciosa: pela regra do legado, a linha caía na
                // consolidação de descrição abaixo e o VALOR DELA ERA DESCARTADO sem aviso.
                // Num extrato real de junho/2025 eram duas linhas, R$ 1.632,73 no total.
                if (TemAlgo(celulaValor))
                {
                    if (linhas.Count == 0)
                        throw new RegraDeNegocioException(
                            $"A linha {n} da planilha tem valor mas não tem data, e não há " +
                            "linha anterior de onde herdar a data.");

                    if (EhCredito(celulaValor)) { creditos++; continue; }

                    datasHerdadas++;
                    linhas.Add(new LinhaImportada
                    {
                        NumeroDaLinha = n,
                        Data = linhas[^1].Data,
                        Descricao = descricao,
                        Valor = LerValor(celulaValor, n)
                    });
                    continue;
                }

                // Sem data e sem valor: a descrição é anexada à do registro anterior,
                // separada por " - ". É assim que uma despesa com várias linhas de detalhe é
                // consolidada num lançamento só.
                if (string.IsNullOrWhiteSpace(descricao)) continue;

                // Antes do primeiro registro isso é preâmbulo — título do extrato, linha em
                // branco, o que for. Só depois que os dados começaram é que uma linha sem
                // data significa "continuação da anterior".
                if (linhas.Count == 0) continue;

                var anterior = linhas[^1];
                linhas[^1] = anterior with { Descricao = anterior.Descricao + " - " + descricao };
                continue;
            }

            // Cabeçalho de coluna ("DATA") ou qualquer outro texto antes dos dados: enquanto
            // não houver registro nenhum, a linha é ignorada em vez de derrubar a leitura.
            // Um extrato bancário traz título na primeira linha e cabeçalho na terceira.
            if (!TentarLerData(celulaData, out var data))
            {
                if (linhas.Count == 0)
                {
                    // Guarda a primeira para explicar, se no fim não vier registro nenhum:
                    // sem isso, uma planilha de colunas trocadas só diria "não achei dados".
                    primeiroTextoSemData ??= (n, textoDaData);
                    continue;
                }

                throw new RegraDeNegocioException(
                    $"A data da linha {n} da planilha não pôde ser lida: \"{textoDaData}\".");
            }

            // Extrato bancário marca D de débito e C de crédito. Crédito é dinheiro entrando,
            // e este sistema é contas a pagar: importar como despesa inventaria uma saída que
            // não houve. Fica de fora, e a prévia diz quantos foram.
            if (EhCredito(celulaValor))
            {
                creditos++;
                continue;
            }

            linhas.Add(new LinhaImportada
            {
                NumeroDaLinha = n,
                Data = data,
                Descricao = descricao,
                Valor = LerValor(celulaValor, n)
            });
        }

        if (linhas.Count == 0)
        {
            if (creditos > 0)
                throw new RegraDeNegocioException(
                    $"A planilha só tem lançamentos de crédito ({creditos}). Este sistema é " +
                    "contas a pagar, e crédito é dinheiro entrando.");

            var explicacao = primeiroTextoSemData is { } p
                ? $" A linha {p.Linha} tem \"{p.Texto}\" na coluna de data — confira se as " +
                  "colunas são data, descrição e valor, nessa ordem."
                : "";

            throw new RegraDeNegocioException(
                "A planilha não tem nenhuma linha com data e valor a partir da linha " +
                $"{PrimeiraLinhaDeDados}." + explicacao);
        }

        return new LeituraDaPlanilha
        {
            Linhas = linhas,
            CreditosIgnorados = creditos,
            DatasHerdadas = datasHerdadas,
            PrimeiraLinhaComDados = linhas[0].NumeroDaLinha
        };
    }

    private static bool TemAlgo(IXLCell celula) => !string.IsNullOrWhiteSpace(celula.GetString());

    /// <summary>D de débito, C de crédito, como os extratos marcam no fim do valor.</summary>
    private static bool EhCredito(IXLCell celula)
    {
        var texto = celula.GetString().Trim();
        return texto.Length > 0 && char.ToUpperInvariant(texto[^1]) == 'C';
    }

    private static bool TentarLerData(IXLCell celula, out DateOnly data)
    {
        if (celula.DataType == XLDataType.DateTime && celula.TryGetValue<DateTime>(out var d))
        {
            data = DateOnly.FromDateTime(d);
            return true;
        }

        var texto = celula.GetString().Trim();
        return DateOnly.TryParse(texto, new CultureInfo("pt-BR"), out data)
            || DateOnly.TryParse(texto, CultureInfo.InvariantCulture, out data);
    }

    private static XLWorkbook AbrirArquivo(Stream planilha)
    {
        try { return new XLWorkbook(planilha); }
        catch (Exception e)
        {
            throw new RegraDeNegocioException(
                "Não foi possível abrir a planilha. Verifique se o arquivo é um .xlsx válido. " +
                $"Detalhe: {e.Message}");
        }
    }

    private static DateOnly LerData(IXLCell celula, int linha)
    {
        if (celula.DataType == XLDataType.DateTime && celula.TryGetValue<DateTime>(out var data))
            return DateOnly.FromDateTime(data);

        var texto = celula.GetString().Trim();
        if (DateOnly.TryParse(texto, new CultureInfo("pt-BR"), out var comCultura))
            return comCultura;
        if (DateOnly.TryParse(texto, CultureInfo.InvariantCulture, out var invariante))
            return invariante;

        throw new RegraDeNegocioException(
            $"A data da linha {linha} da planilha não pôde ser lida: \"{texto}\".");
    }

    private static Dinheiro LerValor(IXLCell celula, int linha)
    {
        if (celula.DataType == XLDataType.Number && celula.TryGetValue<decimal>(out var numero))
            return Dinheiro.De(numero);

        // O legado limpa tudo que não é dígito ou vírgula antes de converter, para tolerar
        // "R$ 1.234,56" digitado à mão.
        var limpo = LimparNumero(celula.GetString());

        if (string.IsNullOrEmpty(limpo))
            throw new RegraDeNegocioException(
                $"A linha {linha} da planilha está sem valor.");

        if (!decimal.TryParse(limpo, NumberStyles.Number, new CultureInfo("pt-BR"), out var valor))
            throw new RegraDeNegocioException(
                $"O valor da linha {linha} da planilha não pôde ser lido: \"{celula.GetString()}\".");

        return Dinheiro.De(valor);
    }

    /// <summary>Mantém apenas dígitos e a vírgula decimal, como faz o legado.</summary>
    public static string LimparNumero(string texto)
    {
        var saida = new StringBuilder(texto.Length);
        foreach (var c in texto)
            if (char.IsAsciiDigit(c) || c == ',') saida.Append(c);
        return saida.ToString();
    }

    /// <summary>
    /// Maiúsculas e sem acento, como o legado grava.
    ///
    /// A remoção de acentos vem de uma época em que o encoding era problema; hoje não seria
    /// necessária. Está mantida por paridade — mudar agora criaria diferença visível entre o
    /// que o Delphi importa e o que a API importa, durante a convivência. Vale confirmar com
    /// o cliente antes de abandonar.
    /// </summary>
    public static string NormalizarDescricao(string texto)
    {
        if (string.IsNullOrWhiteSpace(texto)) return "";

        var semAcento = new StringBuilder(texto.Length);
        foreach (var c in texto.Trim().Normalize(NormalizationForm.FormD))
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                semAcento.Append(c);

        return semAcento.ToString().Normalize(NormalizationForm.FormC).ToUpperInvariant();
    }

    /// <summary>
    /// Preenche as descrições que a planilha não trouxe, com o texto que a pessoa digitou.
    ///
    /// Extrato bancário às vezes exporta a linha só com o valor, sem histórico. Travar a
    /// importação inteira por isso obrigaria a editar o `.xlsx`; e completar sozinho seria
    /// inventar dado. Então quem opera escreve, na prévia, antes de gravar.
    ///
    /// **Só preenche o que está em branco.** Reescrever uma descrição que a planilha trouxe
    /// faria a gravação divergir da prévia que a pessoa conferiu.
    /// </summary>
    public static IReadOnlyList<LinhaImportada> AplicarDescricoesManuais(
        IReadOnlyList<LinhaImportada> linhas, IReadOnlyDictionary<int, string>? porLinha)
    {
        if (porLinha is null || porLinha.Count == 0) return linhas;

        var conhecidas = linhas.Select(l => l.NumeroDaLinha).ToHashSet();
        foreach (var n in porLinha.Keys)
            if (!conhecidas.Contains(n))
                throw new RegraDeNegocioException(
                    $"A descrição informada para a linha {n} não corresponde a nenhuma linha " +
                    "desta planilha. O arquivo escolhido não é o mesmo da prévia.");

        return linhas.Select(l =>
        {
            if (!string.IsNullOrWhiteSpace(l.Descricao)) return l;
            if (!porLinha.TryGetValue(l.NumeroDaLinha, out var texto)) return l;
            if (string.IsNullOrWhiteSpace(texto)) return l;
            return l with { Descricao = NormalizarDescricao(texto) };
        }).ToList();
    }
}
