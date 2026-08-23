using AgendaFinanceira.Dominio;
using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Paridade contra a base congelada — o oráculo mais forte que temos: três anos de operação
/// real do legado. Os números esperados estão em docs/paridade-referencia.md.
///
/// Sem a base, estes testes falham em vez de passar em silêncio: paridade não verificada não
/// é paridade. As instruções para recriá-la estão no mesmo documento.
/// </summary>
public class ParidadeLeituraTeste
{
    private const string CaminhoBase = @"C:\PROGRAMAS\AgendaFinanceira-paridade\BASE_PARIDADE.FDB";

    // Cobre tudo, inclusive os 11 registros com a data zero do Delphi.
    private static readonly Periodo Tudo = new(new DateOnly(1899, 1, 1), new DateOnly(2030, 12, 31));

    private static RepositorioLancamentos Repositorio()
    {
        Assert.True(File.Exists(CaminhoBase),
            $"Base de paridade não encontrada em {CaminhoBase}. " +
            "Ver docs/paridade-referencia.md para recriá-la a partir do backup.");
        return new RepositorioLancamentos(new ConexaoFirebird(CaminhoBase));
    }

    [Fact]
    public void Le_a_quantidade_exata_de_lancamentos()
    {
        var repo = Repositorio();

        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo });
        Assert.Equal(13972, r.Quantidade);
    }

    [Fact]
    public void Reproduz_o_total_pago_acumulado()
    {
        var repo = Repositorio();

        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo });
        Assert.Equal(Dinheiro.De(34501459.68m), r.TotalPago);
    }

    [Fact]
    public void Reproduz_o_total_previsto_acumulado()
    {
        var repo = Repositorio();

        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo });
        Assert.Equal(Dinheiro.De(35586456.69m), r.TotalPrevisto);
    }

    [Theory]
    [InlineData(FiltroPagamento.Pagos, 12462)]
    [InlineData(FiltroPagamento.NaoPagos, 1510)]
    public void Filtra_por_situacao_de_pagamento(FiltroPagamento filtro, int esperado)
    {
        var repo = Repositorio();

        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo, Pagamento = filtro });
        Assert.Equal(esperado, r.Quantidade);
    }

    [Theory]
    // Despesa, quantidade e total pago — de docs/paridade-referencia.md.
    [InlineData("DESPESAS", 4448, 17202250.60)]
    [InlineData("AGRICOLA", 2777, 6424525.50)]
    [InlineData("CASA RAUL", 2479, 1486431.43)]
    [InlineData("PETROTORQUE", 1555, 3421328.94)]
    [InlineData("ESCRITORIO", 1205, 1217832.33)]
    [InlineData("VEICULOS", 599, 695315.10)]
    [InlineData("BASE JC", 450, 358851.85)]
    [InlineData("CHACARA", 257, 1415053.76)]
    [InlineData("COMPRAS E FINANCIAMENTOS", 121, 1928309.05)]
    [InlineData("DESTILARIA", 73, 10160.72)]
    [InlineData("DUBAI", 5, 322806.23)]
    [InlineData("IMPOSTOS", 3, 18594.17)]
    public void Reproduz_os_totais_por_despesa(string despesa, int quantidade, decimal totalPago)
    {
        var repo = Repositorio();

        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo, Despesa = despesa });
        Assert.Equal(quantidade, r.Quantidade);
        Assert.Equal(Dinheiro.De(totalPago), r.TotalPago);
    }

    [Fact]
    public void A_soma_das_despesas_fecha_o_total_geral()
    {
        var repo = Repositorio();

        var todos = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo });
        var porDespesa = todos.Lancamentos.GroupBy(l => l.Despesa)
                                          .Select(g => g.Somar(l => l.ValorPago))
                                          .Somar();

        Assert.Equal(todos.TotalPago, porDespesa);
    }

    // ---- Casos especiais catalogados na Fase 2 ----

    [Fact]
    public void A_data_zero_do_delphi_vira_ausencia_de_data()
    {
        var repo = Repositorio();

        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo });
        var semVencimento = r.Lancamentos.Count(l => l.DataVencimento is null);

        Assert.Equal(11, semVencimento);
        Assert.DoesNotContain(r.Lancamentos, l => l.DataVencimento == new DateOnly(1899, 12, 30));
    }

    [Fact]
    public void Cheque_compensado_encontra_os_registros_em_minuscula()
    {
        var repo = Repositorio();

        // O legado usa LIKE sensível a caixa e perde 9 registros gravados com 's'.
        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo, ChequeCompensado = true });
        Assert.Equal(2297 + 9, r.Quantidade);
    }

    [Theory]
    [InlineData(SituacaoStatus.Liberada, 501)]
    [InlineData(SituacaoStatus.Aguardando, 13)]
    public void Filtra_por_situacao_de_liberacao(SituacaoStatus situacao, int esperado)
    {
        var repo = Repositorio();

        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo, Situacao = situacao });
        Assert.Equal(esperado, r.Quantidade);
    }

    [Fact]
    public void Le_o_lancamento_de_valor_impreciso_com_o_valor_pretendido()
    {
        var repo = Repositorio();

        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo });
        var l = r.Lancamentos.Single(x => x.Id == 19035);

        // No banco está 147059.765625.
        Assert.Equal(Dinheiro.De(147059.77m), l.ValorPrevisto);
    }

    [Fact]
    public void Preserva_o_travessao_do_win1252_no_texto_livre()
    {
        var repo = Repositorio();

        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo });
        var comTravessao = r.Lancamentos.Where(l => l.Observacao is not null &&
                                                    l.Observacao.Contains('\u2013')).ToList();

        // Lido como ISO-8859-1 puro, o travessão viraria caractere de controle e sumiria.
        Assert.NotEmpty(comTravessao);
        Assert.Contains(comTravessao, l => l.Observacao!.Contains("Quadra K"));
    }

    [Fact]
    public void Preserva_acentuacao_no_texto_livre_lido_como_bytes()
    {
        var repo = Repositorio();

        // DESCRICAO passa pelo caminho OCTETS + página 1252. São 158 na base.
        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo });
        var comAcento = r.Lancamentos.Count(l => l.Descricao.Any(EhAcentuado));

        Assert.Equal(158, comAcento);
        Assert.Contains(r.Lancamentos, l => l.Descricao.Contains("INSTALAÇÃO"));
    }

    [Fact]
    public void Preserva_acentuacao_nos_cadastros_lidos_como_texto()
    {
        var repo = Repositorio();

        // SUBCATEGORIA.DESCRICAO vem como string pelo charset da conexão — outro caminho.
        var r = repo.Consultar(new ConsultaLancamentos { Periodo = Tudo });
        var subdespesas = r.Lancamentos.Select(l => l.Subdespesa).Distinct().ToList();

        Assert.Contains(subdespesas, s => s.Contains("MANUTENÇÃO"));
        Assert.Contains(subdespesas, s => s.Contains("CONSTRUÇÃO"));
    }

    private static bool EhAcentuado(char c) => "ÁÉÍÓÚÃÕÇÂÊÔÀáéíóúãõçâêôà".Contains(c);

    // ---- Consolidado por despesa: a troca da coluna de data ----

    [Fact]
    public void Consolidado_pago_filtra_por_data_de_pagamento()
    {
        var repo = Repositorio();

        var linhas = repo.ConsolidarPorDespesa("AGRICOLA", Tudo, apenasPagos: true);

        Assert.NotEmpty(linhas);
        Assert.All(linhas, l => Assert.Equal("AGRICOLA", l.Despesa.Trim()));
    }

    [Fact]
    public void Consolidado_nao_pago_usa_outra_coluna_e_da_outro_resultado()
    {
        var repo = Repositorio();

        var pagos = repo.ConsolidarPorDespesa("AGRICOLA", Tudo, apenasPagos: true);
        var naoPagos = repo.ConsolidarPorDespesa("AGRICOLA", Tudo, apenasPagos: false);

        var totalPagos = pagos.Somar(l => l.TotalPago);
        var totalNaoPagos = naoPagos.Somar(l => l.TotalPrevisto);

        // São recortes diferentes: um olha quando o dinheiro saiu, o outro quando vence.
        Assert.NotEqual(totalPagos, totalNaoPagos);
    }

    // ---- Consolidado recortado por conta ----
    //
    // Pedido de quem opera: "quanto saiu desta conta, nesta despesa". O oráculo aqui é a
    // própria consulta de lançamentos, que já filtrava por conta muito antes — se os dois
    // caminhos discordam, um deles está errado.

    /// <summary>A conta com mais lançamentos na despesa, para o teste não depender de nome fixo.</summary>
    private static string ContaMaisUsadaEm(RepositorioLancamentos repo, string despesa) =>
        repo.Consultar(new ConsultaLancamentos
            {
                Periodo = Tudo,
                Despesa = despesa,
                FiltrarPorData = ColunaDeData.Pagamento,
                Pagamento = FiltroPagamento.Pagos
            })
            .Lancamentos
            .GroupBy(l => l.Conta.Trim())
            .OrderByDescending(g => g.Count())
            .First().Key;

    [Fact]
    public void Consolidado_por_conta_bate_com_a_consulta_de_lancamentos()
    {
        var repo = Repositorio();
        var conta = ContaMaisUsadaEm(repo, "AGRICOLA");

        var consolidado = repo.ConsolidarPorDespesa("AGRICOLA", Tudo, apenasPagos: true, conta);

        var lancamentos = repo.Consultar(new ConsultaLancamentos
        {
            Periodo = Tudo,
            Despesa = "AGRICOLA",
            Conta = conta,
            FiltrarPorData = ColunaDeData.Pagamento,
            Pagamento = FiltroPagamento.Pagos
        });

        Assert.NotEmpty(consolidado);
        Assert.Equal(lancamentos.Quantidade, consolidado.Sum(l => l.Quantidade));
        Assert.Equal(lancamentos.TotalPago, consolidado.Somar(l => l.TotalPago));
    }

    [Fact]
    public void Consolidado_por_conta_e_um_recorte_do_consolidado_inteiro()
    {
        var repo = Repositorio();
        var conta = ContaMaisUsadaEm(repo, "AGRICOLA");

        var inteiro = repo.ConsolidarPorDespesa("AGRICOLA", Tudo, apenasPagos: true);
        var daConta = repo.ConsolidarPorDespesa("AGRICOLA", Tudo, apenasPagos: true, conta);

        // Recorte de verdade: nunca traz mais do que o todo, e a base tem mais de uma conta
        // nesta despesa — então tem de trazer menos.
        Assert.True(daConta.Somar(l => l.TotalPago) < inteiro.Somar(l => l.TotalPago));
        Assert.True(daConta.Sum(l => l.Quantidade) < inteiro.Sum(l => l.Quantidade));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void Conta_vazia_devolve_o_consolidado_inteiro(string? conta)
    {
        // Garante que a tela mandando "" não vira um filtro que zera tudo, e que o JOIN em
        // CONTAS não entra quando não deve — um CONTA_ID órfão sumiria da soma sem ninguém pedir.
        var repo = Repositorio();

        var semParametro = repo.ConsolidarPorDespesa("AGRICOLA", Tudo, apenasPagos: true);
        var comVazio = repo.ConsolidarPorDespesa("AGRICOLA", Tudo, apenasPagos: true, conta);

        Assert.Equal(semParametro.Sum(l => l.Quantidade), comVazio.Sum(l => l.Quantidade));
        Assert.Equal(semParametro.Somar(l => l.TotalPago), comVazio.Somar(l => l.TotalPago));
    }

    [Fact]
    public void Conta_inexistente_devolve_vazio_em_vez_de_ignorar_o_filtro()
    {
        var repo = Repositorio();

        var linhas = repo.ConsolidarPorDespesa(
            "AGRICOLA", Tudo, apenasPagos: true, "CONTA QUE NAO EXISTE");

        Assert.Empty(linhas);
    }

    [Fact]
    public void Vencimentos_traz_apenas_nao_pagos_ate_a_data()
    {
        var repo = Repositorio();

        var hoje = new DateOnly(2025, 3, 26); // último dia de cadastro na base
        var r = repo.Vencimentos(hoje);

        Assert.All(r.Lancamentos, l =>
        {
            Assert.False(l.Pago);
            Assert.True(l.DataVencimento is null || l.DataVencimento <= hoje);
        });
    }
}
