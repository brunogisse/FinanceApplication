using Dapper;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Parcelamento, pagamento em lote e importação — Etapa 5 do roadmap.
/// São os fluxos com mais defeito conhecido no legado, e por isso os mais testados.
/// </summary>
public class OperacoesEmLoteTeste : IClassFixture<BaseDescartavel>
{
    private readonly BaseDescartavel _base;
    private readonly int _subdespesaId, _contaId, _formaId;
    private static readonly DateOnly Hoje = new(2026, 8, 19);

    public OperacoesEmLoteTeste(BaseDescartavel baseDescartavel)
    {
        _base = baseDescartavel;
        using var con = _base.Conexao.Abrir();
        var c = con.QuerySingle(
            "SELECT FIRST 1 S.SUBCATEGORIA_ID, " +
            "  (SELECT MIN(CONTA_ID) FROM CONTAS) AS CONTA, " +
            "  (SELECT MIN(FORMA_DE_PAGAMENTO_ID) FROM FORMA_DE_PAGAMENTO) AS FORMA " +
            "FROM SUBCATEGORIA S");
        _subdespesaId = c.SUBCATEGORIA_ID; _contaId = c.CONTA; _formaId = c.FORMA;
    }

    private Usuario Usuario(int id = 1, NivelAcesso nivel = NivelAcesso.Administracao) =>
        new() { Id = id, Nome = "TESTE", Nivel = nivel, AindaSemHash = false };

    private DadosLancamento Dados(decimal valor = 1200.00m, string? descricao = null) => new()
    {
        Descricao = descricao ?? "LOTE " + Guid.NewGuid().ToString("N")[..6],
        SubdespesaId = _subdespesaId,
        ContaId = _contaId,
        FormaPagamentoId = _formaId,
        ValorPrevisto = Dinheiro.De(valor),
        DataVencimento = new DateOnly(2026, 1, 31)
    };

    // ================= PARCELAMENTO =================

    [Fact]
    public void Parcelamento_gera_a_quantidade_pedida_e_apaga_o_original()
    {
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(), Usuario(), Hoje);

        var r = repo.Parcelar(original.Id, 6, Usuario(), Hoje);

        Assert.Equal(6, r.Parcelas.Count);
        Assert.Null(repo.PorId(original.Id));
    }

    [Fact]
    public void Parcelamento_de_20000_em_12_fecha_o_total()
    {
        // O caso real do legado: doze parcelas de R$ 1.666,666626 somando R$ 19.999,9995.
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(20000.00m), Usuario(), Hoje);

        var r = repo.Parcelar(original.Id, 12, Usuario(), Hoje);

        Assert.True(r.Fechou);
        Assert.Equal(Dinheiro.De(20000.00m), r.SomaDasParcelas);
        Assert.Equal(8, r.Parcelas.Count(p => p.ValorPrevisto == Dinheiro.De(1666.67m)));
        Assert.Equal(4, r.Parcelas.Count(p => p.ValorPrevisto == Dinheiro.De(1666.66m)));
    }

    [Theory]
    [InlineData(100.00, 3)]
    [InlineData(1000.00, 7)]
    [InlineData(0.05, 2)]
    [InlineData(99999.99, 13)]
    public void Parcelamento_sempre_fecha_o_total(decimal valor, int parcelas)
    {
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(valor), Usuario(), Hoje);

        var r = repo.Parcelar(original.Id, parcelas, Usuario(), Hoje);

        Assert.True(r.Fechou, $"{valor} em {parcelas} não fechou: soma {r.SomaDasParcelas}");
    }

    [Fact]
    public void Parcelas_recebem_o_sufixo_i_sobre_n_na_descricao()
    {
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(descricao: "CARTAO DE CREDITO"), Usuario(), Hoje);

        var r = repo.Parcelar(original.Id, 12, Usuario(), Hoje);

        Assert.Contains(r.Parcelas, p => p.Descricao == "CARTAO DE CREDITO 1/12");
        Assert.Contains(r.Parcelas, p => p.Descricao == "CARTAO DE CREDITO 12/12");
    }

    [Fact]
    public void Parcelas_recebem_a_observacao_padrao()
    {
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(), Usuario(), Hoje);

        var r = repo.Parcelar(original.Id, 3, Usuario(), Hoje);

        Assert.All(r.Parcelas, p =>
            Assert.Equal(RegrasParcelamento.ObservacaoPadrao, p.Observacao));
    }

    [Fact]
    public void A_primeira_parcela_vence_no_mes_do_vencimento_original()
    {
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(), Usuario(), Hoje);   // vence 31/01/2026

        var r = repo.Parcelar(original.Id, 3, Usuario(), Hoje);
        var ordenadas = r.Parcelas.OrderBy(p => p.DataVencimento).ToList();

        Assert.Equal(new DateOnly(2026, 1, 31), ordenadas[0].DataVencimento);
        Assert.Equal(new DateOnly(2026, 2, 28), ordenadas[1].DataVencimento);  // fevereiro
        Assert.Equal(new DateOnly(2026, 3, 31), ordenadas[2].DataVencimento);
    }

    [Fact]
    public void Parcelamento_preserva_a_autoria_do_original()
    {
        var repo = _base.Lancamentos();
        var autor = Usuario(id: 5, nivel: NivelAcesso.Operacao);
        var original = repo.Criar(Dados(), autor, Hoje);

        // Quem parcela é o usuário 1, mas a autoria continua sendo de quem lançou.
        var r = repo.Parcelar(original.Id, 4, Usuario(id: 1), Hoje);

        Assert.All(r.Parcelas, p => Assert.Equal(5, p.UsuarioId));
    }

    [Fact]
    public void Parcelamento_de_lancamento_alheio_e_recusado()
    {
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(), Usuario(id: 5, nivel: NivelAcesso.Operacao), Hoje);

        Assert.Throws<RegraDeNegocioException>(
            () => repo.Parcelar(original.Id, 3, Usuario(id: 6, nivel: NivelAcesso.Operacao), Hoje));

        Assert.NotNull(repo.PorId(original.Id));   // e o original continua lá
    }

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    [InlineData(-3)]
    [InlineData(400)]
    public void Quantidade_invalida_de_parcelas_e_recusada(int parcelas)
    {
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(), Usuario(), Hoje);

        Assert.Throws<RegraDeNegocioException>(
            () => repo.Parcelar(original.Id, parcelas, Usuario(), Hoje));

        Assert.NotNull(repo.PorId(original.Id));
    }

    [Fact]
    public void Nada_e_gravado_quando_o_parcelamento_e_recusado()
    {
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(), Usuario(), Hoje);
        var antes = Total();

        Assert.Throws<RegraDeNegocioException>(() => repo.Parcelar(original.Id, 1, Usuario(), Hoje));

        Assert.Equal(antes, Total());
    }

    [Fact]
    public void Parcelar_lancamento_sem_valor_e_recusado()
    {
        var repo = _base.Lancamentos();
        var original = repo.Criar(Dados(0m), Usuario(), Hoje);

        var e = Assert.Throws<RegraDeNegocioException>(
            () => repo.Parcelar(original.Id, 3, Usuario(), Hoje));
        Assert.Contains("sem valor", e.Message);
    }

    // ================= PAGAMENTO EM LOTE =================

    [Fact]
    public void Paga_todos_os_lancamentos_informados()
    {
        var repo = _base.Lancamentos();
        var ids = Enumerable.Range(0, 3)
                            .Select(_ => repo.Criar(Dados(100.00m), Usuario(), Hoje).Id)
                            .ToList();

        var r = repo.PagarEmLote(ids, Usuario(), Hoje);

        Assert.Equal(3, r.Quantidade);
        Assert.Equal(Dinheiro.De(300.00m), r.TotalPago);
        Assert.All(ids, id =>
        {
            var l = repo.PorId(id)!;
            Assert.True(l.Pago);
            Assert.Equal(Hoje, l.DataPagamento);
            Assert.Equal(l.ValorPrevisto, l.ValorPago);   // valor pago recebe o previsto
        });
    }

    [Fact]
    public void Item_ja_pago_no_lote_e_ignorado_sem_travar()
    {
        // No legado, o avanço para o próximo está dentro do "se não pago", então um item já
        // pago na grade trava a aplicação em laço infinito. UfrmLancamentos.pas:426.
        var repo = _base.Lancamentos();
        var naoPago = repo.Criar(Dados(100.00m), Usuario(), Hoje).Id;
        var jaPago = repo.Criar(Dados(50.00m) with { Pago = true }, Usuario(), Hoje).Id;

        var r = repo.PagarEmLote([jaPago, naoPago], Usuario(), Hoje);

        Assert.Equal([naoPago], r.Pagos);
        Assert.Equal([jaPago], r.JaEstavamPagos);
        Assert.Equal(Dinheiro.De(100.00m), r.TotalPago);
    }

    [Fact]
    public void Lote_inteiro_de_itens_ja_pagos_conclui_sem_pagar_nada()
    {
        var repo = _base.Lancamentos();
        var ids = Enumerable.Range(0, 3)
                            .Select(_ => repo.Criar(Dados(10.00m) with { Pago = true }, Usuario(), Hoje).Id)
                            .ToList();

        var r = repo.PagarEmLote(ids, Usuario(), Hoje);

        Assert.Empty(r.Pagos);
        Assert.Equal(3, r.JaEstavamPagos.Count);
        Assert.Equal(Dinheiro.Zero, r.TotalPago);
    }

    [Fact]
    public void Lancamento_alheio_no_lote_e_recusado_mas_nao_impede_os_demais()
    {
        var repo = _base.Lancamentos();
        var meu = repo.Criar(Dados(100.00m), Usuario(id: 6, nivel: NivelAcesso.Operacao), Hoje).Id;
        var alheio = repo.Criar(Dados(100.00m), Usuario(id: 5, nivel: NivelAcesso.Operacao), Hoje).Id;

        var r = repo.PagarEmLote([meu, alheio], Usuario(id: 6, nivel: NivelAcesso.Operacao), Hoje);

        Assert.Equal([meu], r.Pagos);
        Assert.Equal([alheio], r.SemPermissao);
        Assert.False(repo.PorId(alheio)!.Pago);
    }

    [Fact]
    public void Identificador_inexistente_no_lote_e_reportado()
    {
        var repo = _base.Lancamentos();
        var valido = repo.Criar(Dados(100.00m), Usuario(), Hoje).Id;

        var r = repo.PagarEmLote([valido, 999999], Usuario(), Hoje);

        Assert.Equal([valido], r.Pagos);
        Assert.Equal([999999], r.NaoEncontrados);
    }

    [Fact]
    public void Lote_vazio_e_recusado()
    {
        Assert.Throws<RegraDeNegocioException>(
            () => _base.Lancamentos().PagarEmLote([], Usuario(), Hoje));
    }

    [Fact]
    public void Identificadores_repetidos_sao_pagos_uma_vez_so()
    {
        var repo = _base.Lancamentos();
        var id = repo.Criar(Dados(100.00m), Usuario(), Hoje).Id;

        var r = repo.PagarEmLote([id, id, id], Usuario(), Hoje);

        Assert.Single(r.Pagos);
        Assert.Equal(Dinheiro.De(100.00m), r.TotalPago);
    }

    // ================= IMPORTAÇÃO =================

    private static LinhaImportada Linha(int numero, decimal valor, string descricao) => new()
    {
        NumeroDaLinha = numero,
        Data = new DateOnly(2026, 3, 15),
        Descricao = descricao,
        Valor = Dinheiro.De(valor)
    };

    [Fact]
    public void Importa_o_lote_todo_como_pago_com_a_data_da_planilha()
    {
        var repo = _base.Lancamentos();
        var linhas = new[]
        {
            Linha(2, 150.00m, "COMBUSTIVEL"),
            Linha(3, 250.50m, "MANUTENCAO"),
        };

        var r = repo.ImportarLote(linhas, _subdespesaId, _contaId, _formaId, Usuario(), Hoje);

        Assert.Equal(2, r.Quantidade);
        Assert.Equal(Dinheiro.De(400.50m), r.Total);
        Assert.All(r.Lancamentos, l =>
        {
            Assert.True(l.Pago);
            Assert.Equal(new DateOnly(2026, 3, 15), l.DataPagamento);
            Assert.Equal(new DateOnly(2026, 3, 15), l.DataVencimento);
            Assert.Equal(Hoje, l.DataCadastro);            // cadastro é hoje, pagamento é histórico
            Assert.Equal(l.ValorPrevisto, l.ValorPago);
        });
    }

    [Fact]
    public void Uma_linha_invalida_impede_o_lote_inteiro()
    {
        // O legado grava linha a linha com commit individual: uma falha no meio deixa parte
        // do lote gravada. Aqui é tudo ou nada.
        var repo = _base.Lancamentos();
        var antes = Total();

        var linhas = new[]
        {
            Linha(2, 100.00m, "BOA"),
            Linha(3, -50.00m, "VALOR NEGATIVO"),
            Linha(4, 100.00m, "OUTRA BOA"),
        };

        var e = Assert.Throws<RegraDeNegocioException>(
            () => repo.ImportarLote(linhas, _subdespesaId, _contaId, _formaId, Usuario(), Hoje));

        Assert.Contains("linha 3", e.Message);
        Assert.Equal(antes, Total());
    }

    [Fact]
    public void Linha_sem_descricao_aponta_o_numero_da_linha()
    {
        var repo = _base.Lancamentos();
        var e = Assert.Throws<RegraDeNegocioException>(() => repo.ImportarLote(
            [Linha(7, 100.00m, "   ")], _subdespesaId, _contaId, _formaId, Usuario(), Hoje));

        Assert.Contains("linha 7", e.Message);
    }

    [Fact]
    public void Lote_vazio_de_importacao_e_recusado()
    {
        Assert.Throws<RegraDeNegocioException>(() => _base.Lancamentos().ImportarLote(
            [], _subdespesaId, _contaId, _formaId, Usuario(), Hoje));
    }

    [Fact]
    public void Importacao_com_subdespesa_inexistente_nao_grava_nada()
    {
        var repo = _base.Lancamentos();
        var antes = Total();

        Assert.Throws<RegraDeNegocioException>(() => repo.ImportarLote(
            [Linha(2, 100.00m, "QUALQUER")], 999999, _contaId, _formaId, Usuario(), Hoje));

        Assert.Equal(antes, Total());
    }

    private int Total()
    {
        using var con = _base.Conexao.Abrir();
        return con.ExecuteScalar<int>("SELECT COUNT(*) FROM REGISTRO_DE_GASTOS");
    }
}
