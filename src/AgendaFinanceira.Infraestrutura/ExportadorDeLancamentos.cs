using ClosedXML.Excel;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>
/// Gera a planilha de lançamentos, equivalente ao botão de exportar da tela do legado
/// (docs/fluxos.md, item 11).
///
/// As colunas e a ordem são as mesmas do legado, para que quem já tem uma planilha de apoio
/// montada em cima da exportação continue achando cada coisa no mesmo lugar.
///
/// Três diferenças, todas deliberadas:
///
/// 1. **Não depende do Excel instalado.** O legado cria uma instância do Excel por automação
///    OLE, o que exige o Excel na máquina e deixa processos órfãos quando algo falha no meio.
/// 2. **Os valores saem exatos.** No legado o arredondamento acontece só na exportação, sobre
///    um `FLOAT` já impreciso, então a planilha pode divergir do banco. Aqui o valor já é
///    decimal desde a leitura.
/// 3. **A linha de total vai embaixo da coluna certa.** O legado escreve as somas nas colunas
///    2 e 3 fixas, presumindo que sejam valor pago e valor previsto; se a ordem dos campos da
///    consulta mudar, os totais aparecem debaixo de outra coisa.
/// </summary>
public static class ExportadorDeLancamentos
{
    public const string TipoConteudo =
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

    /// <summary>Máscara de moeda brasileira, a mesma que o legado aplica.</summary>
    private const string FormatoMoeda = "[$R$-416] #,##0.00";
    private const string FormatoData = "dd/MM/yyyy";

    /// <summary>
    /// As oito colunas do legado, na mesma ordem.
    ///
    /// Os títulos são os únicos que mudam: lá saem os nomes crus das colunas do banco
    /// (LANCAMENTO, VALOR_PAGO, DATA_VENCIMENTO), aqui sai o vocabulário da tela.
    /// </summary>
    private static readonly string[] Titulos =
    [
        "Descrição", "Valor pago", "Valor previsto", "Nota fiscal",
        "Cheque", "Vencimento", "Pagamento", "Conta"
    ];

    public static byte[] Gerar(IReadOnlyList<Lancamento> lancamentos)
    {
        using var arquivo = new XLWorkbook();
        var aba = arquivo.Worksheets.Add("Lançamentos");

        for (var c = 0; c < Titulos.Length; c++)
        {
            var celula = aba.Cell(1, c + 1);
            celula.Value = Titulos[c];
            celula.Style.Font.Bold = true;
            celula.Style.Fill.BackgroundColor = XLColor.FromArgb(0xEE, 0xF1, 0xF6);
        }

        var linha = 2;
        foreach (var l in lancamentos)
        {
            aba.Cell(linha, 1).Value = l.Descricao;
            Moeda(aba.Cell(linha, 2), l.ValorPago.Valor);
            Moeda(aba.Cell(linha, 3), l.ValorPrevisto.Valor);

            // Nota fiscal e cheque são números de documento, não quantidades: célula vazia
            // quando não há, nunca zero — zero aqui seria lido como "nota número zero".
            if (l.NotaFiscal is not null) aba.Cell(linha, 4).Value = l.NotaFiscal.Value;
            if (l.Cheque is not null) aba.Cell(linha, 5).Value = l.Cheque.Value;

            Data(aba.Cell(linha, 6), l.DataVencimento);
            Data(aba.Cell(linha, 7), l.DataPagamento);
            aba.Cell(linha, 8).Value = l.Conta;

            linha++;
        }

        // Uma linha em branco separando, como no legado, e então os totais.
        linha++;
        aba.Cell(linha, 1).Value = "TOTAL";
        aba.Cell(linha, 1).Style.Font.Bold = true;

        // Somado em decimal. Somar em ponto flutuante é justamente o defeito que originou
        // esta migração.
        Moeda(aba.Cell(linha, 2), lancamentos.Sum(l => l.ValorPago.Valor)).Style.Font.Bold = true;
        Moeda(aba.Cell(linha, 3), lancamentos.Sum(l => l.ValorPrevisto.Valor)).Style.Font.Bold = true;

        aba.SheetView.FreezeRows(1);
        aba.Columns().AdjustToContents();

        using var memoria = new MemoryStream();
        arquivo.SaveAs(memoria);
        return memoria.ToArray();
    }

    private static IXLCell Moeda(IXLCell celula, decimal valor)
    {
        celula.Value = valor;
        celula.Style.NumberFormat.Format = FormatoMoeda;
        return celula;
    }

    /// <summary>
    /// Data de calendário, gravada como data mesmo — para o Excel poder ordenar e filtrar.
    ///
    /// Vazia quando não há. O legado tem 11 registros com o zero do TDateTime (30/12/1899),
    /// que viram nulo na leitura; escrevê-los como 1899 seria propagar um dado que não existe.
    /// </summary>
    private static void Data(IXLCell celula, DateOnly? data)
    {
        if (data is null) return;
        celula.Value = data.Value.ToDateTime(TimeOnly.MinValue);
        celula.Style.DateFormat.Format = FormatoData;
    }
}
