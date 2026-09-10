using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Escrita nos cadastros de apoio, sobre uma cópia descartável da base real.
/// Primeira etapa em que a API grava — ver docs/roadmap.md, Etapa 3.
/// </summary>
public class CadastrosTeste : IClassFixture<BaseDescartavel>
{
    private readonly BaseDescartavel _base;
    public CadastrosTeste(BaseDescartavel baseDescartavel) => _base = baseDescartavel;

    // ---- Leitura: confere contra a base real ----

    [Fact]
    public void Le_os_cadastros_existentes_na_quantidade_certa()
    {
        var repo = _base.Cadastros();

        Assert.Equal(14, repo.ListarContas(Setor.Financeiro).Count);
        Assert.Equal(10, repo.ListarFormasPagamento(Setor.Financeiro).Count);
        Assert.Equal(14, repo.ListarDespesas(Setor.Financeiro).Count);
        Assert.Equal(148, repo.ListarSubdespesas(Setor.Financeiro).Count);
    }

    [Fact]
    public void Subdespesa_traz_o_nome_da_despesa_a_que_pertence()
    {
        var subs = _base.Cadastros().ListarSubdespesas(Setor.Financeiro);
        Assert.All(subs, s => Assert.False(string.IsNullOrWhiteSpace(s.Despesa)));
    }

    [Fact]
    public void Filtra_subdespesas_por_despesa()
    {
        var repo = _base.Cadastros();
        var agricola = repo.ListarDespesas(Setor.Financeiro).Single(d => d.Descricao == "AGRICOLA");
        var subs = repo.ListarSubdespesas(Setor.Financeiro, agricola.Id);

        Assert.NotEmpty(subs);
        Assert.All(subs, s => Assert.Equal(agricola.Id, s.DespesaId));
    }

    // ---- Escrita ----

    [Fact]
    public void Cria_conta_e_o_banco_atribui_o_identificador()
    {
        var repo = _base.Cadastros();
        var antes = repo.ListarContas(Setor.Financeiro).Count;

        var nova = repo.CriarConta("CONTA DE TESTE " + Guid.NewGuid().ToString("N")[..6], Setor.Financeiro);

        Assert.True(nova.Id > 0, "A trigger do banco deveria ter atribuído o identificador.");
        Assert.Equal(antes + 1, repo.ListarContas(Setor.Financeiro).Count);
    }

    [Fact]
    public void Altera_e_exclui_conta()
    {
        var repo = _base.Cadastros();
        var conta = repo.CriarConta("CONTA TEMPORARIA " + Guid.NewGuid().ToString("N")[..6], Setor.Financeiro);

        var alterada = repo.AlterarConta(conta.Id, "CONTA RENOMEADA " + conta.Id, Setor.Financeiro);
        Assert.Equal("CONTA RENOMEADA " + conta.Id, alterada.Descricao);
        Assert.Contains(repo.ListarContas(Setor.Financeiro), c => c.Id == conta.Id && c.Descricao.StartsWith("CONTA RENOMEADA"));

        repo.ExcluirConta(conta.Id, Setor.Financeiro);
        Assert.DoesNotContain(repo.ListarContas(Setor.Financeiro), c => c.Id == conta.Id);
    }

    [Fact]
    public void Cria_despesa_e_subdespesa_ligada_a_ela()
    {
        var repo = _base.Cadastros();
        var sufixo = Guid.NewGuid().ToString("N")[..6];

        var despesa = repo.CriarDespesa("DESPESA TESTE " + sufixo, Setor.Financeiro);
        var sub = repo.CriarSubdespesa("SUBDESPESA TESTE " + sufixo, despesa.Id, Setor.Financeiro);

        Assert.Equal(despesa.Id, sub.DespesaId);
        Assert.Contains(repo.ListarSubdespesas(Setor.Financeiro, despesa.Id), s => s.Id == sub.Id);
    }

    // ---- Regras que o banco legado não impõe ----

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public void Recusa_descricao_vazia(string? descricao)
    {
        // O legado não tem constraint nenhuma, e por isso há uma categoria com descrição
        // vazia na base de produção.
        var e = Assert.Throws<RegraDeNegocioException>(() => _base.Cadastros().CriarConta(descricao!, Setor.Financeiro));
        Assert.Contains("Informe", e.Message);
    }

    [Fact]
    public void Recusa_descricao_maior_que_a_coluna()
    {
        var e = Assert.Throws<RegraDeNegocioException>(
            () => _base.Cadastros().CriarConta(new string('X', 51), Setor.Financeiro));
        Assert.Contains("50 caracteres", e.Message);
    }

    [Fact]
    public void Recusa_conta_repetida_sem_diferenciar_maiusculas()
    {
        var repo = _base.Cadastros();
        var nome = "CONTA UNICA " + Guid.NewGuid().ToString("N")[..6];
        repo.CriarConta(nome, Setor.Financeiro);

        var e = Assert.Throws<RegraDeNegocioException>(() => repo.CriarConta(nome.ToLowerInvariant(), Setor.Financeiro));
        Assert.Contains("Já existe", e.Message);
    }

    [Fact]
    public void Aceita_subdespesas_de_mesmo_nome_em_despesas_diferentes()
    {
        // Legítimo: o legado tem MANUTENÇÃO em mais de um centro de custo.
        var repo = _base.Cadastros();
        var sufixo = Guid.NewGuid().ToString("N")[..6];
        var d1 = repo.CriarDespesa("DESPESA A " + sufixo, Setor.Financeiro);
        var d2 = repo.CriarDespesa("DESPESA B " + sufixo, Setor.Financeiro);

        repo.CriarSubdespesa("MANUTENCAO", d1.Id, Setor.Financeiro);
        var segunda = repo.CriarSubdespesa("MANUTENCAO", d2.Id, Setor.Financeiro);

        Assert.Equal(d2.Id, segunda.DespesaId);
    }

    [Fact]
    public void Recusa_subdespesa_repetida_dentro_da_mesma_despesa()
    {
        var repo = _base.Cadastros();
        var despesa = repo.CriarDespesa("DESPESA C " + Guid.NewGuid().ToString("N")[..6], Setor.Financeiro);
        repo.CriarSubdespesa("COMBUSTIVEL", despesa.Id, Setor.Financeiro);

        var e = Assert.Throws<RegraDeNegocioException>(
            () => repo.CriarSubdespesa("combustivel", despesa.Id, Setor.Financeiro));
        Assert.Contains("Já existe", e.Message);
    }

    [Fact]
    public void Recusa_subdespesa_ligada_a_despesa_inexistente()
    {
        var e = Assert.Throws<RegraDeNegocioException>(
            () => _base.Cadastros().CriarSubdespesa("QUALQUER", 999999, Setor.Financeiro));
        Assert.Contains("não existe", e.Message);
    }

    [Fact]
    public void Explica_em_portugues_por_que_nao_da_para_excluir_um_cadastro_em_uso()
    {
        var repo = _base.Cadastros();
        // RAUL/LESSIA tem 8.474 lançamentos na base.
        var emUso = repo.ListarContas(Setor.Financeiro).Single(c => c.Descricao == "RAUL/LESSIA");

        var e = Assert.Throws<RegraDeNegocioException>(() => repo.ExcluirConta(emUso.Id, Setor.Financeiro));

        Assert.Contains("Não é possível excluir", e.Message);
        Assert.Contains("lançamentos", e.Message);
        Assert.DoesNotContain("FOREIGN KEY", e.Message);   // nada de erro técnico na cara do operador
    }

    [Fact]
    public void Recusa_alteracao_de_cadastro_inexistente()
    {
        var e = Assert.Throws<RegraDeNegocioException>(
            () => _base.Cadastros().AlterarConta(999999, "QUALQUER", Setor.Financeiro));
        Assert.Contains("não encontrada", e.Message);
    }
}
