using ClosedXML.Excel;
using AgendaFinanceira.Dominio;
using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Leitura da planilha de importação, reproduzindo as regras do legado.
/// Não depende de Excel instalado — o legado depende, por usar automação OLE.
/// </summary>
public class LeitorDePlanilhaTeste
{
    /// <summary>Monta uma planilha em memória: cada linha é (data, descrição, valor).</summary>
    private static Stream Planilha(params (string Data, string Descricao, object? Valor)[] linhas)
    {
        var arquivo = new XLWorkbook();
        var aba = arquivo.Worksheets.Add(LeitorDePlanilha.AbaPadrao);

        aba.Cell(1, 1).Value = "DATA";
        aba.Cell(1, 2).Value = "DESCRICAO";
        aba.Cell(1, 3).Value = "VALOR";

        var n = LeitorDePlanilha.PrimeiraLinhaDeDados;
        foreach (var (data, descricao, valor) in linhas)
        {
            if (!string.IsNullOrEmpty(data)) aba.Cell(n, 1).Value = data;
            aba.Cell(n, 2).Value = descricao;
            switch (valor)
            {
                case null: break;
                case decimal d: aba.Cell(n, 3).Value = d; break;
                case string s: aba.Cell(n, 3).Value = s; break;
            }
            n++;
        }

        var memoria = new MemoryStream();
        arquivo.SaveAs(memoria);
        memoria.Position = 0;
        return memoria;
    }

    [Fact]
    public void Le_as_linhas_a_partir_da_segunda()
    {
        using var p = Planilha(
            ("15/03/2026", "COMBUSTIVEL", 150.00m),
            ("16/03/2026", "MANUTENCAO", 250.50m));

        var linhas = LeitorDePlanilha.Ler(p);

        Assert.Equal(2, linhas.Count);
        Assert.Equal(new DateOnly(2026, 3, 15), linhas[0].Data);
        Assert.Equal("COMBUSTIVEL", linhas[0].Descricao);
        Assert.Equal(Dinheiro.De(150.00m), linhas[0].Valor);
    }

    [Fact]
    public void Linha_sem_data_anexa_a_descricao_a_anterior()
    {
        // É assim que uma despesa com várias linhas de detalhe vira um lançamento só.
        using var p = Planilha(
            ("15/03/2026", "COMBUSTIVEL", 150.00m),
            ("", "POSTO CENTRAL", null),
            ("", "NOTA 123", null),
            ("16/03/2026", "MANUTENCAO", 250.00m));

        var linhas = LeitorDePlanilha.Ler(p);

        Assert.Equal(2, linhas.Count);
        Assert.Equal("COMBUSTIVEL - POSTO CENTRAL - NOTA 123", linhas[0].Descricao);
        Assert.Equal("MANUTENCAO", linhas[1].Descricao);
    }

    [Fact]
    public void Linha_sem_data_e_sem_descricao_e_ignorada()
    {
        using var p = Planilha(
            ("15/03/2026", "COMBUSTIVEL", 150.00m),
            ("", "", null),
            ("16/03/2026", "MANUTENCAO", 250.00m));

        Assert.Equal(2, LeitorDePlanilha.Ler(p).Count);
    }

    [Fact]
    public void Descricao_vira_maiuscula_sem_acento_como_no_legado()
    {
        using var p = Planilha(("15/03/2026", "Manutenção do Trator Ação", 100.00m));

        Assert.Equal("MANUTENCAO DO TRATOR ACAO", LeitorDePlanilha.Ler(p)[0].Descricao);
    }

    [Fact]
    public void Le_valor_escrito_como_texto_com_simbolo_de_moeda()
    {
        using var p = Planilha(("15/03/2026", "ALUGUEL", "R$ 1.234,56"));

        Assert.Equal(Dinheiro.De(1234.56m), LeitorDePlanilha.Ler(p)[0].Valor);
    }

    [Fact]
    public void Recusa_planilha_sem_nenhuma_linha_com_data()
    {
        using var p = Planilha(("", "SO DESCRICAO", null));

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(p));
        Assert.Contains("não há linha anterior", e.Message);
    }

    [Fact]
    public void Recusa_data_ilegivel_apontando_a_linha()
    {
        using var p = Planilha(("nao e data", "QUALQUER", 100.00m));

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(p));
        Assert.Contains("linha 2", e.Message);
    }

    [Fact]
    public void Recusa_valor_ausente_apontando_a_linha()
    {
        using var p = Planilha(
            ("15/03/2026", "PRIMEIRA", 100.00m),
            ("16/03/2026", "SEM VALOR", null));

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(p));
        Assert.Contains("linha 3", e.Message);
    }

    [Fact]
    public void Recusa_arquivo_que_nao_e_planilha()
    {
        using var lixo = new MemoryStream("isto nao e uma planilha"u8.ToArray());

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(lixo));
        Assert.Contains(".xlsx", e.Message);
    }

    [Theory]
    [InlineData("R$ 1.234,56", "1234,56")]
    [InlineData("1.000", "1000")]
    [InlineData("  50,00  ", "50,00")]
    [InlineData("abc", "")]
    public void Limpa_o_numero_mantendo_digitos_e_virgula(string entrada, string esperado)
    {
        Assert.Equal(esperado, LeitorDePlanilha.LimparNumero(entrada));
    }
}
