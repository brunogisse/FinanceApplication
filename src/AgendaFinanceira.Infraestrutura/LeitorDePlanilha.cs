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

    public static IReadOnlyList<LinhaImportada> Ler(Stream planilha)
    {
        using var arquivo = AbrirArquivo(planilha);

        var aba = arquivo.Worksheets.FirstOrDefault(
                      w => string.Equals(w.Name, AbaPadrao, StringComparison.OrdinalIgnoreCase))
                  ?? arquivo.Worksheets.FirstOrDefault()
                  ?? throw new RegraDeNegocioException("A planilha não tem nenhuma aba.");

        var linhas = new List<LinhaImportada>();
        var ultima = aba.LastRowUsed()?.RowNumber() ?? 0;

        for (var n = PrimeiraLinhaDeDados; n <= ultima; n++)
        {
            var celulaData = aba.Cell(n, 1);
            var descricao = NormalizarDescricao(aba.Cell(n, 2).GetString());

            // Linha sem data não vira registro novo: a descrição é anexada à do registro
            // anterior, separada por " - ". É assim que uma despesa com várias linhas de
            // detalhe é consolidada num lançamento só.
            if (celulaData.IsEmpty() || string.IsNullOrWhiteSpace(celulaData.GetString()))
            {
                if (string.IsNullOrWhiteSpace(descricao)) continue;

                if (linhas.Count == 0)
                    throw new RegraDeNegocioException(
                        $"A linha {n} da planilha não tem data e não há linha anterior " +
                        "a que anexar a descrição.");

                var anterior = linhas[^1];
                linhas[^1] = anterior with { Descricao = anterior.Descricao + " - " + descricao };
                continue;
            }

            linhas.Add(new LinhaImportada
            {
                NumeroDaLinha = n,
                Data = LerData(celulaData, n),
                Descricao = descricao,
                Valor = LerValor(aba.Cell(n, 3), n)
            });
        }

        if (linhas.Count == 0)
            throw new RegraDeNegocioException(
                "A planilha não tem nenhuma linha com data a partir da linha " +
                $"{PrimeiraLinhaDeDados}.");

        return linhas;
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
}
