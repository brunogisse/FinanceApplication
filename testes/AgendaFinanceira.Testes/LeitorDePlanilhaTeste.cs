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

        var linhas = LeitorDePlanilha.Ler(p).Linhas;

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

        var linhas = LeitorDePlanilha.Ler(p).Linhas;

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

        Assert.Equal(2, LeitorDePlanilha.Ler(p).Linhas.Count);
    }

    [Fact]
    public void Descricao_vira_maiuscula_sem_acento_como_no_legado()
    {
        using var p = Planilha(("15/03/2026", "Manutenção do Trator Ação", 100.00m));

        Assert.Equal("MANUTENCAO DO TRATOR ACAO", LeitorDePlanilha.Ler(p).Linhas[0].Descricao);
    }

    [Fact]
    public void Le_valor_escrito_como_texto_com_simbolo_de_moeda()
    {
        using var p = Planilha(("15/03/2026", "ALUGUEL", "R$ 1.234,56"));

        Assert.Equal(Dinheiro.De(1234.56m), LeitorDePlanilha.Ler(p).Linhas[0].Valor);
    }

    [Fact]
    public void Recusa_planilha_sem_nenhuma_linha_com_data()
    {
        using var p = Planilha(("", "SO DESCRICAO", null));

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(p).Linhas);
        Assert.Contains("nenhuma linha com data", e.Message);
    }

    [Fact]
    public void Planilha_toda_ilegivel_explica_o_que_encontrou_na_coluna_de_data()
    {
        // Antes da tolerância a cabeçalho, isto era um erro apontando a linha 2. Agora a
        // primeira linha ilegível é tratada como preâmbulo — então a recusa vem no fim, e
        // precisa dizer o que havia ali, senão viraria "não achei dados" e nada mais.
        using var p = Planilha(("nao e data", "QUALQUER", 100.00m));

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(p).Linhas);
        Assert.Contains("linha 2", e.Message);
        Assert.Contains("nao e data", e.Message);
        Assert.Contains("data, descrição e valor", e.Message);
    }

    [Fact]
    public void Data_ilegivel_no_meio_dos_dados_ainda_derruba_a_leitura()
    {
        // Depois que os dados começaram, linha torta é erro de verdade: pular em silêncio
        // sumiria com um pagamento sem ninguém ver.
        using var p = Planilha(
            ("15/03/2026", "BOA", 100.00m),
            ("nao e data", "TORTA", 100.00m));

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(p).Linhas);
        Assert.Contains("linha 3", e.Message);
    }

    [Fact]
    public void Pula_titulo_e_cabecalho_de_extrato_bancario()
    {
        // Formato de extrato: título na primeira linha, cabeçalho depois, e só então os
        // dados — com data em texto e valor com o D de débito no fim.
        using var p = Planilha(
            ("EXTRATO CONTA CORRENTE", "", null),
            ("", "", null),
            ("DATA", "HISTÓRICO", null),
            ("02/06/2025", "DÉB. CONV. SEGUROS", "440,18D"),
            ("04/06/2025", "SALARIO ALINE", "1.535,93D"));

        var leitura = LeitorDePlanilha.Ler(p);

        Assert.Equal(2, leitura.Linhas.Count);
        Assert.Equal(new DateOnly(2025, 6, 2), leitura.Linhas[0].Data);
        Assert.Equal(Dinheiro.De(440.18m), leitura.Linhas[0].Valor);
        // Ponto de milhar e a letra do fim saem sem estragar o valor.
        Assert.Equal(Dinheiro.De(1535.93m), leitura.Linhas[1].Valor);
        Assert.Equal(0, leitura.CreditosIgnorados);
    }

    [Fact]
    public void Linha_com_valor_e_sem_data_herda_a_data_da_anterior()
    {
        // Extrato não repete a data dentro do mesmo dia. Pela regra do legado essas linhas
        // caíam na consolidação de descrição e O VALOR SUMIA sem aviso — num extrato real de
        // junho/2025 eram duas linhas, R$ 1.632,73.
        using var p = Planilha(
            ("10/06/2025", "CLUBE TENIS RAFA", "90,00D"),
            ("", "CLUBE TENIS JULIA", "90,00D"));

        var leitura = LeitorDePlanilha.Ler(p);

        Assert.Equal(2, leitura.Linhas.Count);
        Assert.Equal(new DateOnly(2025, 6, 10), leitura.Linhas[1].Data);
        Assert.Equal("CLUBE TENIS JULIA", leitura.Linhas[1].Descricao);
        Assert.Equal(Dinheiro.De(90.00m), leitura.Linhas[1].Valor);
        Assert.Equal(1, leitura.DatasHerdadas);
    }

    [Fact]
    public void Linha_sem_data_sem_descricao_mas_com_valor_tambem_vira_lancamento()
    {
        // Caso real: o extrato deixou data e histórico em branco e só trouxe o valor.
        // Vira lançamento — sem descrição, e a importação recusa apontando a linha, que é
        // melhor do que engolir R$ 1.542,73 em silêncio.
        using var p = Planilha(
            ("09/06/2025", "MARANZATTI", "2.950,00D"),
            ("", "", "1.542,73D"));

        var leitura = LeitorDePlanilha.Ler(p);

        Assert.Equal(2, leitura.Linhas.Count);
        Assert.Equal(new DateOnly(2025, 6, 9), leitura.Linhas[1].Data);
        Assert.Equal("", leitura.Linhas[1].Descricao);
        Assert.Equal(Dinheiro.De(1542.73m), leitura.Linhas[1].Valor);
    }

    [Fact]
    public void Valor_sem_data_antes_de_qualquer_registro_e_recusado()
    {
        // Não há data de onde herdar. Pular seria sumir com dinheiro.
        using var p = Planilha(("", "", "500,00D"));

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(p).Linhas);
        Assert.Contains("valor mas não tem data", e.Message);
    }

    [Fact]
    public void Credito_fica_de_fora_e_e_contado()
    {
        // Crédito é dinheiro entrando, e este sistema é contas a pagar: importar como
        // despesa inventaria uma saída que não houve.
        using var p = Planilha(
            ("02/06/2025", "PAGAMENTO", "440,18D"),
            ("03/06/2025", "DEPOSITO RECEBIDO", "1.000,00C"),
            ("04/06/2025", "OUTRO PAGAMENTO", "60,00D"));

        var leitura = LeitorDePlanilha.Ler(p);

        Assert.Equal(2, leitura.Linhas.Count);
        Assert.Equal(1, leitura.CreditosIgnorados);
        Assert.DoesNotContain(leitura.Linhas, l => l.Descricao.Contains("DEPOSITO"));
    }

    [Fact]
    public void Planilha_so_de_credito_e_recusada_com_a_razao()
    {
        using var p = Planilha(("03/06/2025", "DEPOSITO", "1.000,00C"));

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(p).Linhas);
        Assert.Contains("só tem lançamentos de crédito", e.Message);
    }

    [Fact]
    public void Recusa_valor_ausente_apontando_a_linha()
    {
        using var p = Planilha(
            ("15/03/2026", "PRIMEIRA", 100.00m),
            ("16/03/2026", "SEM VALOR", null));

        var e = Assert.Throws<RegraDeNegocioException>(() => LeitorDePlanilha.Ler(p).Linhas);
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

    [Fact]
    public void Descricao_digitada_preenche_a_linha_que_o_extrato_deixou_em_branco()
    {
        using var p = Planilha(
            ("09/06/2025", "MARANZATTI", "2.950,00D"),
            ("", "", "1.542,73D"));

        var linhas = LeitorDePlanilha.Ler(p).Linhas;
        var com = LeitorDePlanilha.AplicarDescricoesManuais(
            linhas, new Dictionary<int, string> { [3] = "Pagamento à vista" });

        // Chega maiúscula e sem acento, como qualquer descrição da planilha.
        Assert.Equal("PAGAMENTO A VISTA", com[1].Descricao);
        Assert.Equal(Dinheiro.De(1542.73m), com[1].Valor);
    }

    [Fact]
    public void Descricao_digitada_nao_reescreve_o_que_a_planilha_trouxe()
    {
        // Reescrever faria a gravação divergir da prévia que a pessoa conferiu.
        using var p = Planilha(("09/06/2025", "MARANZATTI", "2.950,00D"));

        var com = LeitorDePlanilha.AplicarDescricoesManuais(
            LeitorDePlanilha.Ler(p).Linhas,
            new Dictionary<int, string> { [2] = "OUTRA COISA" });

        Assert.Equal("MARANZATTI", com[0].Descricao);
    }

    [Fact]
    public void Descricao_para_linha_inexistente_e_recusada()
    {
        // Sinal de que o arquivo escolhido não é o mesmo da prévia.
        using var p = Planilha(("09/06/2025", "MARANZATTI", "2.950,00D"));

        var e = Assert.Throws<RegraDeNegocioException>(() =>
            LeitorDePlanilha.AplicarDescricoesManuais(
                LeitorDePlanilha.Ler(p).Linhas,
                new Dictionary<int, string> { [999] = "QUALQUER" }));

        Assert.Contains("linha 999", e.Message);
    }

    [Fact]
    public void Sem_descricoes_digitadas_as_linhas_saem_intactas()
    {
        using var p = Planilha(("09/06/2025", "MARANZATTI", "2.950,00D"));
        var linhas = LeitorDePlanilha.Ler(p).Linhas;

        Assert.Same(linhas, LeitorDePlanilha.AplicarDescricoesManuais(linhas, null));
    }
}
