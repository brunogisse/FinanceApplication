using Dapper;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Criação, alteração e exclusão de lançamentos — Etapa 4 do roadmap.
/// Sempre sobre uma cópia descartável da base real.
/// </summary>
public class LancamentosEscritaTeste : IClassFixture<BaseDescartavel>
{
    private readonly BaseDescartavel _base;
    private readonly int _subdespesaId;
    private readonly int _despesaEsperada;
    private readonly int _contaId;
    private readonly int _formaId;

    private static readonly DateOnly Hoje = new(2026, 8, 19);

    public LancamentosEscritaTeste(BaseDescartavel baseDescartavel)
    {
        _base = baseDescartavel;
        using var con = _base.Conexao.Abrir();
        var chaves = con.QuerySingle(
            "SELECT FIRST 1 S.SUBCATEGORIA_ID, S.CATEGORIA_ID, " +
            "  (SELECT MIN(CONTA_ID) FROM CONTAS) AS CONTA, " +
            "  (SELECT MIN(FORMA_DE_PAGAMENTO_ID) FROM FORMA_DE_PAGAMENTO) AS FORMA " +
            "FROM SUBCATEGORIA S");
        _subdespesaId = chaves.SUBCATEGORIA_ID;
        _despesaEsperada = chaves.CATEGORIA_ID;
        _contaId = chaves.CONTA;
        _formaId = chaves.FORMA;
    }

    private Usuario Usuario(int id = 1, NivelAcesso nivel = NivelAcesso.Administracao,
                            Setor? setor = null) =>
        new()
        {
            Id = id, Nome = "TESTE", Nivel = nivel,
            Setor = setor ?? Setor.Financeiro, AindaSemHash = false
        };

    private DadosLancamento Dados(string? descricao = null) => new()
    {
        Descricao = descricao ?? "LANCAMENTO DE TESTE " + Guid.NewGuid().ToString("N")[..6],
        SubdespesaId = _subdespesaId,
        ContaId = _contaId,
        FormaPagamentoId = _formaId,
        ValorPrevisto = Dinheiro.De(1234.56m),
        DataVencimento = Hoje.AddDays(30)
    };

    // ---- Criação ----

    [Fact]
    public void Cria_lancamento_com_os_dados_informados()
    {
        var repo = _base.Lancamentos();
        var criado = repo.Criar(Dados("ENERGIA ELETRICA"), Usuario(), Hoje);

        Assert.True(criado.Id > 0);
        Assert.Equal("ENERGIA ELETRICA", criado.Descricao);
        Assert.Equal(Dinheiro.De(1234.56m), criado.ValorPrevisto);
        Assert.Equal(Hoje.AddDays(30), criado.DataVencimento);
    }

    [Fact]
    public void A_subdespesa_determina_a_despesa()
    {
        // No legado, escolher a subdespesa preenche os dois campos juntos. A despesa nunca é
        // informada separadamente, então não há como montar combinação inválida.
        var criado = _base.Lancamentos().Criar(Dados(), Usuario(), Hoje);
        Assert.Equal(_despesaEsperada, criado.DespesaId);
    }

    [Fact]
    public void Carimba_a_autoria_e_a_data_de_cadastro()
    {
        var criado = _base.Lancamentos().Criar(Dados(), Usuario(id: 5, nivel: NivelAcesso.Operacao), Hoje);

        Assert.Equal(5, criado.UsuarioId);
        Assert.Equal(Hoje, criado.DataCadastro);
    }

    [Fact]
    public void Nao_confirmado_entra_como_nao_pago_e_com_valor_pago_zerado()
    {
        var criado = _base.Lancamentos().Criar(Dados(), Usuario(), Hoje);

        Assert.False(criado.Pago);
        Assert.Equal(Dinheiro.Zero, criado.ValorPago);
        Assert.Null(criado.DataPagamento);
    }

    [Fact]
    public void Confirmado_sem_valor_informado_assume_o_previsto()
    {
        var criado = _base.Lancamentos().Criar(
            Dados() with { Pago = true }, Usuario(), Hoje);

        Assert.True(criado.Pago);
        Assert.Equal(Dinheiro.De(1234.56m), criado.ValorPago);
        Assert.Equal(Hoje, criado.DataPagamento);      // assume hoje quando não informada
    }

    [Fact]
    public void Confirmado_com_valor_diferente_do_previsto_respeita_o_informado()
    {
        var criado = _base.Lancamentos().Criar(
            Dados() with { Pago = true, ValorPago = Dinheiro.De(1000.00m) }, Usuario(), Hoje);

        Assert.Equal(Dinheiro.De(1234.56m), criado.ValorPrevisto);
        Assert.Equal(Dinheiro.De(1000.00m), criado.ValorPago);
    }

    [Fact]
    public void Cheque_compensado_vazio_vira_N_como_no_legado()
    {
        var criado = _base.Lancamentos().Criar(Dados(), Usuario(), Hoje);
        Assert.False(criado.ChequeCompensado);
    }

    [Fact]
    public void Preserva_acentuacao_ao_gravar_e_reler()
    {
        var criado = _base.Lancamentos().Criar(
            Dados("MANUTENÇÃO TRATOR") with { Observacao = "Instalação da bomba d'água" },
            Usuario(), Hoje);

        var lido = _base.Lancamentos().PorId(criado.Id, Setor.Financeiro)!;
        Assert.Equal("MANUTENÇÃO TRATOR", lido.Descricao);
        Assert.Equal("Instalação da bomba d'água", lido.Observacao);
    }

    [Fact]
    public void Normaliza_pontuacao_tipografica_ao_gravar()
    {
        // A conexão usa ISO8859_1, onde travessões e aspas curvas não existem. Sem
        // normalização explícita a conversão aconteceria assim mesmo, mas a mercê do provider.
        // Ver ADR 0009. Estes caracteres entram pelo Excel, na importação por planilha.
        var criado = _base.Lancamentos().Criar(
            Dados("LOTE 12 – QUADRA K") with { Observacao = "Parcela “única” — sem juros…" },
            Usuario(), Hoje);

        var lido = _base.Lancamentos().PorId(criado.Id, Setor.Financeiro)!;

        Assert.Equal("LOTE 12 - QUADRA K", lido.Descricao);
        Assert.Equal("Parcela \"única\" - sem juros...", lido.Observacao);
    }

    // ---- Validações que o legado não tem no banco ----

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Recusa_descricao_vazia(string descricao)
    {
        Assert.Throws<RegraDeNegocioException>(
            () => _base.Lancamentos().Criar(Dados(descricao), Usuario(), Hoje));
    }

    [Fact]
    public void Recusa_valor_previsto_negativo()
    {
        var e = Assert.Throws<RegraDeNegocioException>(() => _base.Lancamentos().Criar(
            Dados() with { ValorPrevisto = Dinheiro.De(-1m) }, Usuario(), Hoje));
        Assert.Contains("negativo", e.Message);
    }

    [Fact]
    public void Recusa_subdespesa_inexistente()
    {
        var e = Assert.Throws<RegraDeNegocioException>(() => _base.Lancamentos().Criar(
            Dados() with { SubdespesaId = 999999 }, Usuario(), Hoje));
        Assert.Contains("subdespesa", e.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Recusa_conta_inexistente()
    {
        var e = Assert.Throws<RegraDeNegocioException>(() => _base.Lancamentos().Criar(
            Dados() with { ContaId = 999999 }, Usuario(), Hoje));
        Assert.Contains("conta", e.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Nada_e_gravado_quando_a_validacao_recusa()
    {
        var repo = _base.Lancamentos();
        var antes = Total();

        Assert.Throws<RegraDeNegocioException>(
            () => repo.Criar(Dados() with { ContaId = 999999 }, Usuario(), Hoje));

        Assert.Equal(antes, Total());
    }

    private int Total()
    {
        using var con = _base.Conexao.Abrir();
        return con.ExecuteScalar<int>("SELECT COUNT(*) FROM REGISTRO_DE_GASTOS");
    }

    // ---- Alteração ----

    [Fact]
    public void Altera_os_dados_preservando_autoria_e_data_de_cadastro()
    {
        var repo = _base.Lancamentos();
        var criado = repo.Criar(Dados("ORIGINAL"), Usuario(id: 5, nivel: NivelAcesso.Operacao), Hoje);

        var alterado = repo.Alterar(criado.Id,
            Dados("ALTERADO") with { ValorPrevisto = Dinheiro.De(999.99m) },
            Usuario(id: 1), Hoje.AddDays(10));

        Assert.Equal("ALTERADO", alterado.Descricao);
        Assert.Equal(Dinheiro.De(999.99m), alterado.ValorPrevisto);
        Assert.Equal(5, alterado.UsuarioId);           // alterar não muda quem lançou
        Assert.Equal(Hoje, alterado.DataCadastro);     // nem quando foi lançado
    }

    [Fact]
    public void Alterar_para_pago_preenche_data_e_valor()
    {
        var repo = _base.Lancamentos();
        var criado = repo.Criar(Dados(), Usuario(), Hoje);

        var pago = repo.Alterar(criado.Id, Dados() with { Pago = true }, Usuario(), Hoje);

        Assert.True(pago.Pago);
        Assert.Equal(Hoje, pago.DataPagamento);
        Assert.Equal(Dinheiro.De(1234.56m), pago.ValorPago);
    }

    [Fact]
    public void Alterar_de_pago_para_nao_pago_limpa_data_e_valor()
    {
        var repo = _base.Lancamentos();
        var criado = repo.Criar(Dados() with { Pago = true }, Usuario(), Hoje);

        var reaberto = repo.Alterar(criado.Id, Dados() with { Pago = false }, Usuario(), Hoje);

        Assert.False(reaberto.Pago);
        Assert.Null(reaberto.DataPagamento);
        Assert.Equal(Dinheiro.Zero, reaberto.ValorPago);
    }

    [Fact]
    public void Recusa_alterar_lancamento_inexistente()
    {
        Assert.Throws<RegraDeNegocioException>(
            () => _base.Lancamentos().Alterar(999999, Dados(), Usuario(), Hoje));
    }

    // ---- Autoria: a regra que no legado está comentada no Alterar ----

    [Fact]
    public void Autor_pode_alterar_o_proprio_lancamento()
    {
        var repo = _base.Lancamentos();
        var autor = Usuario(id: 5, nivel: NivelAcesso.Operacao);
        var criado = repo.Criar(Dados(), autor, Hoje);

        var alterado = repo.Alterar(criado.Id, Dados("MEU"), autor, Hoje);
        Assert.Equal("MEU", alterado.Descricao);
    }

    [Fact]
    public void Outro_usuario_nao_altera_lancamento_alheio()
    {
        var repo = _base.Lancamentos();
        var criado = repo.Criar(Dados(), Usuario(id: 5, nivel: NivelAcesso.Operacao), Hoje);
        var outro = Usuario(id: 6, nivel: NivelAcesso.Operacao);

        var e = Assert.Throws<RegraDeNegocioException>(
            () => repo.Alterar(criado.Id, Dados("INVASOR"), outro, Hoje));

        Assert.Contains("permissão", e.Message);
        Assert.NotEqual("INVASOR", repo.PorId(criado.Id, Setor.Financeiro)!.Descricao);
    }

    [Fact]
    public void Outro_usuario_nao_exclui_lancamento_alheio()
    {
        var repo = _base.Lancamentos();
        var criado = repo.Criar(Dados(), Usuario(id: 5, nivel: NivelAcesso.Operacao), Hoje);

        Assert.Throws<RegraDeNegocioException>(
            () => repo.Excluir(criado.Id, Usuario(id: 6, nivel: NivelAcesso.Operacao)));

        Assert.NotNull(repo.PorId(criado.Id, Setor.Financeiro));
    }

    [Fact]
    public void O_usuario_um_altera_e_exclui_lancamento_de_qualquer_um()
    {
        var repo = _base.Lancamentos();
        var criado = repo.Criar(Dados(), Usuario(id: 6, nivel: NivelAcesso.Operacao), Hoje);

        var alterado = repo.Alterar(criado.Id, Dados("ADMIN MEXEU"), Usuario(id: 1), Hoje);
        Assert.Equal("ADMIN MEXEU", alterado.Descricao);

        repo.Excluir(criado.Id, Usuario(id: 1));
        Assert.Null(repo.PorId(criado.Id, Setor.Financeiro));
    }

    // ---- Exclusão ----

    [Fact]
    public void Exclui_o_proprio_lancamento()
    {
        var repo = _base.Lancamentos();
        var autor = Usuario(id: 5, nivel: NivelAcesso.Operacao);
        var criado = repo.Criar(Dados(), autor, Hoje);

        repo.Excluir(criado.Id, autor);

        Assert.Null(repo.PorId(criado.Id, Setor.Financeiro));
    }

    // ---- Situação de liberação ----

    [Theory]
    [InlineData(SituacaoStatus.Aguardando)]
    [InlineData(SituacaoStatus.Liberada)]
    [InlineData(SituacaoStatus.Nenhuma)]
    public void Define_a_situacao_de_liberacao(SituacaoStatus situacao)
    {
        var repo = _base.Lancamentos();
        var criado = repo.Criar(Dados(), Usuario(), Hoje);

        var atualizado = repo.DefinirSituacao(criado.Id, situacao, Usuario());

        Assert.Equal(situacao, atualizado.Situacao);
    }

    // ---- Aparece nas consultas ----

    [Fact]
    public void O_lancamento_criado_aparece_na_consulta_e_soma_nos_totais()
    {
        var repo = _base.Lancamentos();
        var periodo = new Periodo(Hoje, Hoje.AddDays(60));

        var antes = repo.Consultar(new ConsultaLancamentos { Periodo = periodo }, Setor.Financeiro);
        repo.Criar(Dados() with { ValorPrevisto = Dinheiro.De(500.00m) }, Usuario(), Hoje);
        var depois = repo.Consultar(new ConsultaLancamentos { Periodo = periodo }, Setor.Financeiro);

        Assert.Equal(antes.Quantidade + 1, depois.Quantidade);
        Assert.Equal(antes.TotalPrevisto + Dinheiro.De(500.00m), depois.TotalPrevisto);
    }
}
