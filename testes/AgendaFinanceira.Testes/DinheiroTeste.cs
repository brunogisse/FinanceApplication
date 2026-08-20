using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Testes;

public class DinheiroTeste
{
    [Fact]
    public void Arredonda_para_duas_casas_ao_criar()
    {
        Assert.Equal(1234.57m, Dinheiro.De(1234.567m).Valor);
        Assert.Equal(1234.56m, Dinheiro.De(1234.564m).Valor);
    }

    [Fact]
    public void Arredonda_meio_centavo_para_cima_como_manda_o_comercio()
    {
        Assert.Equal(0.13m, Dinheiro.De(0.125m).Valor);
        Assert.Equal(-0.13m, Dinheiro.De(-0.125m).Valor);
    }

    [Theory]
    // Casos reais da base, colhidos na Fase 2.
    [InlineData(147059.765625, 147059.77)]  // lançamento 19035
    [InlineData(1666.666626, 1666.67)]      // lançamento 17014, parcela de 20.000/12
    public void Converte_float_do_legado_para_o_valor_pretendido(double doBanco, decimal esperado)
    {
        Assert.Equal(esperado, Dinheiro.DeFloatDoLegado(doBanco).Valor);
    }

    [Fact]
    public void Soma_e_subtracao_nao_acumulam_erro()
    {
        // Somar 0,10 dez vezes com double daria 0,9999999999999999.
        var total = Enumerable.Repeat(Dinheiro.De(0.10m), 10).Somar();
        Assert.Equal(1.00m, total.Valor);
    }

    // ---- Divisão: o coração do parcelamento ----

    [Fact]
    public void Divisao_exata_gera_parcelas_iguais()
    {
        var parcelas = Dinheiro.De(100.00m).Dividir(4);
        Assert.All(parcelas, p => Assert.Equal(25.00m, p.Valor));
    }

    [Fact]
    public void Divisao_com_dizima_soma_exatamente_o_total()
    {
        // O caso do legado: R$ 20.000,00 em 12 parcelas.
        // Ele gera doze de R$ 1.666,666626, que somam R$ 19.999,9995.
        var total = Dinheiro.De(20000.00m);
        var parcelas = total.Dividir(12);

        Assert.Equal(12, parcelas.Length);
        Assert.Equal(total, parcelas.Somar());

        // Oito parcelas de 1.666,67 e quatro de 1.666,66.
        Assert.Equal(8, parcelas.Count(p => p.Valor == 1666.67m));
        Assert.Equal(4, parcelas.Count(p => p.Valor == 1666.66m));
    }

    [Fact]
    public void Divisao_coloca_o_centavo_extra_nas_primeiras_parcelas()
    {
        var parcelas = Dinheiro.De(100.00m).Dividir(3);

        Assert.Equal(33.34m, parcelas[0].Valor);
        Assert.Equal(33.33m, parcelas[1].Valor);
        Assert.Equal(33.33m, parcelas[2].Valor);
        Assert.Equal(Dinheiro.De(100.00m), parcelas.Somar());
    }

    [Theory]
    [InlineData(100.00, 3)]
    [InlineData(20000.00, 12)]
    [InlineData(0.05, 3)]
    [InlineData(1234.56, 7)]
    [InlineData(0.01, 2)]
    [InlineData(999999.99, 13)]
    public void Divisao_sempre_fecha_o_total(decimal valor, int partes)
    {
        var total = Dinheiro.De(valor);
        Assert.Equal(total, total.Dividir(partes).Somar());
    }

    [Fact]
    public void Divisao_de_valor_negativo_tambem_fecha()
    {
        var total = Dinheiro.De(-100.00m);
        var parcelas = total.Dividir(3);
        Assert.Equal(total, parcelas.Somar());
    }

    [Fact]
    public void Divisao_por_zero_ou_negativo_e_recusada()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Dinheiro.De(10m).Dividir(0));
        Assert.Throws<ArgumentOutOfRangeException>(() => Dinheiro.De(10m).Dividir(-1));
    }

    [Fact]
    public void Formata_em_padrao_brasileiro()
    {
        Assert.Equal("1.234,56", Dinheiro.De(1234.56m).SemSimbolo());
        Assert.Contains("1.234,56", Dinheiro.De(1234.56m).ToString());
    }

    [Fact]
    public void Centavos_sao_exatos_para_valores_grandes()
    {
        // Maior valor da base: R$ 2.070.000,00
        Assert.Equal(207000000L, Dinheiro.De(2070000.00m).Centavos);
    }
}
