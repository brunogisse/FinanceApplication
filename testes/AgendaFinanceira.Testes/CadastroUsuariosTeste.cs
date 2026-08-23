using Dapper;
using AgendaFinanceira.Infraestrutura;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Cadastro de usuários — criar, alterar e excluir.
///
/// **Nenhuma destas regras existe no legado.** A tela de lá é um `TDBNavigator` sobre
/// `select * from LOGIN`, sem validação alguma. Cada teste aqui documenta um buraco concreto
/// que ela deixa aberto.
///
/// A base é descartável e todos os usuários são criados pelo próprio teste. Nenhuma senha
/// real do sistema aparece no código.
/// </summary>
public class CadastroUsuariosTeste : IClassFixture<BaseDescartavel>
{
    private readonly BaseDescartavel _base;
    public CadastroUsuariosTeste(BaseDescartavel baseDescartavel) => _base = baseDescartavel;

    private static string NomeInedito() => "U" + Guid.NewGuid().ToString("N")[..10].ToUpperInvariant();

    /// <summary>Quem executa a operação. Administrador comum, não o usuário 1.</summary>
    private static Usuario Administrador(int id = 99) => new()
    {
        Id = id,
        Nome = "ADMIN",
        Nivel = NivelAcesso.Administracao,
        AindaSemHash = false
    };

    private static DadosUsuario Dados(string nome, NivelAcesso nivel = NivelAcesso.Operacao) =>
        new() { Nome = nome, Nivel = nivel };

    // ---------------- Criação ----------------

    [Fact]
    public void Criar_grava_a_senha_nas_duas_colunas()
    {
        // O texto plano existe para o Delphi continuar autenticando quem foi criado pela API.
        // Sem ele, a pessoa entraria no sistema novo e seria recusada pelo antigo.
        var repo = _base.Usuarios();
        var nome = NomeInedito();

        var criado = repo.Criar(Dados(nome), "senha123");

        using var con = _base.Conexao.Abrir();
        var linha = con.QuerySingle(
            "SELECT SENHA, SENHA_HASH FROM LOGIN WHERE LOGIN_ID = @id", new { id = criado.Id });

        Assert.Equal("senha123", ConexaoFirebird.TextoDoLegado(linha.SENHA));
        Assert.False(string.IsNullOrEmpty(ConexaoFirebird.TextoDoLegado(linha.SENHA_HASH)));
    }

    [Fact]
    public void Quem_foi_criado_pela_api_consegue_entrar()
    {
        // A costura entre criar e autenticar: as duas peças passam isoladas e é a junção
        // que importa.
        var repo = _base.Usuarios();
        var nome = NomeInedito();
        repo.Criar(Dados(nome, NivelAcesso.Administracao), "senha123");

        var r = repo.Autenticar(nome, "senha123");

        Assert.True(r.Autenticado);
        Assert.Equal(NivelAcesso.Administracao, r.Usuario!.Nivel);
        // Já nasce com hash, então não há o que migrar na primeira entrada.
        Assert.False(r.MigrouSenha);
    }

    [Fact]
    public void Nome_repetido_e_recusado_sem_diferenciar_maiusculas()
    {
        // Nome repetido não é só desordem de cadastro: Autenticar busca por UPPER(NOME)
        // esperando um registro só, e com duplicata estoura em vez de recusar o login.
        var repo = _base.Usuarios();
        var nome = NomeInedito();
        repo.Criar(Dados(nome), "senha123");

        var e = Assert.Throws<RegraDeNegocioException>(
            () => repo.Criar(Dados(nome.ToLowerInvariant()), "outra123"));

        Assert.Contains("Já existe um usuário", e.Message);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(4)]
    [InlineData(7)]
    [InlineData(-1)]
    public void Nivel_fora_de_1_a_3_e_recusado(int nivel)
    {
        // O legado aceita qualquer inteiro em NIVEL, e um nível 7 passaria em toda checagem
        // de "maior ou igual a 2" — virando administrador por acidente.
        var e = Assert.Throws<RegraDeNegocioException>(() => RegrasUsuario.ExigirNivel(nivel));
        Assert.Contains("1 (consulta), 2 (operação) ou 3 (administração)", e.Message);
    }

    [Theory]
    [InlineData(1)]
    [InlineData(2)]
    [InlineData(3)]
    public void Os_tres_niveis_do_legado_sao_aceitos(int nivel)
    {
        Assert.Equal((NivelAcesso)nivel, RegrasUsuario.ExigirNivel(nivel));
    }

    [Fact]
    public void Senha_curta_demais_e_recusada()
    {
        var e = Assert.Throws<RegraDeNegocioException>(
            () => _base.Usuarios().Criar(Dados(NomeInedito()), "abc"));

        Assert.Contains("pelo menos 4", e.Message);
    }

    [Fact]
    public void Senha_maior_que_a_coluna_do_legado_e_recusada()
    {
        // O teto de 20 é o tamanho de LOGIN.SENHA. Cai quando o Delphi for desligado.
        var e = Assert.Throws<RegraDeNegocioException>(
            () => _base.Usuarios().Criar(Dados(NomeInedito()), new string('a', 21)));

        Assert.Contains("no máximo 20", e.Message);
    }

    [Fact]
    public void Nome_vazio_e_recusado()
    {
        var e = Assert.Throws<RegraDeNegocioException>(
            () => _base.Usuarios().Criar(Dados("   "), "senha123"));

        Assert.Contains("nome do usuário", e.Message);
    }

    // ---------------- Alteração ----------------

    [Fact]
    public void Alterar_troca_nome_e_nivel_sem_tocar_na_senha()
    {
        // Se a alteração mexesse na senha, corrigir um nome derrubaria o acesso da pessoa.
        var repo = _base.Usuarios();
        var criado = repo.Criar(Dados(NomeInedito()), "senha123");
        var nomeNovo = NomeInedito();

        var alterado = repo.Alterar(
            criado.Id, Dados(nomeNovo, NivelAcesso.Consulta), Administrador());

        Assert.Equal(nomeNovo, alterado.Nome);
        Assert.Equal(NivelAcesso.Consulta, alterado.Nivel);
        Assert.True(repo.Autenticar(nomeNovo, "senha123").Autenticado);
    }

    [Fact]
    public void Alterar_para_um_nome_ja_usado_e_recusado()
    {
        var repo = _base.Usuarios();
        var primeiro = repo.Criar(Dados(NomeInedito()), "senha123");
        var segundo = repo.Criar(Dados(NomeInedito()), "senha123");

        var e = Assert.Throws<RegraDeNegocioException>(
            () => repo.Alterar(segundo.Id, Dados(primeiro.Nome), Administrador()));

        Assert.Contains("Já existe um usuário", e.Message);
    }

    [Fact]
    public void Manter_o_proprio_nome_na_alteracao_nao_e_conflito()
    {
        // Senão trocar só o nível seria impossível.
        var repo = _base.Usuarios();
        var criado = repo.Criar(Dados(NomeInedito()), "senha123");

        var alterado = repo.Alterar(
            criado.Id, Dados(criado.Nome, NivelAcesso.Consulta), Administrador());

        Assert.Equal(NivelAcesso.Consulta, alterado.Nivel);
    }

    [Fact]
    public void O_usuario_1_nao_perde_o_nivel_3()
    {
        // No legado ele é o administrador de fato: único que vê o backup e único que altera
        // lançamento de outra pessoa. Rebaixá-lo trancaria o sistema.
        var e = Assert.Throws<RegraDeNegocioException>(() => RegrasUsuario.ExigirQuePodeAlterar(
            RegrasUsuario.IdDoAdministradorDeFato, NivelAcesso.Operacao, Administrador()));

        Assert.Contains("precisa continuar no nível 3", e.Message);
    }

    [Fact]
    public void Ninguem_rebaixa_o_proprio_nivel()
    {
        // Um administrador sozinho que se rebaixasse deixaria o sistema sem quem cadastre
        // usuários, e a saída seria mexer no banco por fora.
        var quem = Administrador(id: 42);

        var e = Assert.Throws<RegraDeNegocioException>(
            () => RegrasUsuario.ExigirQuePodeAlterar(42, NivelAcesso.Consulta, quem));

        Assert.Contains("rebaixar o seu próprio nível", e.Message);
    }

    [Fact]
    public void Alterar_o_proprio_nome_continua_permitido()
    {
        // A trava é contra perder o nível, não contra se editar.
        var quem = Administrador(id: 42);
        RegrasUsuario.ExigirQuePodeAlterar(42, NivelAcesso.Administracao, quem);
    }

    // ---------------- Exclusão ----------------

    [Fact]
    public void Excluir_apaga_quem_nunca_lancou()
    {
        var repo = _base.Usuarios();
        var criado = repo.Criar(Dados(NomeInedito()), "senha123");

        repo.Excluir(criado.Id, Administrador());

        Assert.DoesNotContain(repo.Listar(), u => u.Id == criado.Id);
    }

    [Fact]
    public void Quem_tem_lancamento_nao_pode_ser_excluido()
    {
        // A regra de verdade é a chave estrangeira FK_REGISTRO_DE_GASTOS_5, no banco. Isto
        // aqui só garante que a mensagem diz o número em vez de vazar o erro do Firebird.
        var repo = _base.Usuarios();
        var criado = repo.Criar(Dados(NomeInedito()), "senha123");

        var lancamentos = _base.Lancamentos();
        lancamentos.Criar(new DadosLancamento
        {
            Descricao = "TESTE DE AUTORIA",
            SubdespesaId = SubdespesaQualquer(),
            ContaId = ContaQualquer(),
            FormaPagamentoId = FormaQualquer(),
            ValorPrevisto = Dinheiro.De(10m),
            DataVencimento = new DateOnly(2026, 1, 10)
        }, criado);

        var e = Assert.Throws<RegraDeNegocioException>(
            () => repo.Excluir(criado.Id, Administrador()));

        Assert.Contains("Não é possível excluir", e.Message);
        Assert.Contains("1 lançamento(s)", e.Message);
    }

    [Fact]
    public void O_usuario_1_nao_pode_ser_excluido()
    {
        var e = Assert.Throws<RegraDeNegocioException>(() => RegrasUsuario.ExigirQuePodeExcluir(
            RegrasUsuario.IdDoAdministradorDeFato, Administrador()));

        Assert.Contains("não pode ser excluído", e.Message);
    }

    [Fact]
    public void Ninguem_exclui_o_proprio_usuario()
    {
        var quem = Administrador(id: 42);

        var e = Assert.Throws<RegraDeNegocioException>(
            () => RegrasUsuario.ExigirQuePodeExcluir(42, quem));

        Assert.Contains("seu próprio usuário", e.Message);
    }

    [Fact]
    public void Excluir_quem_nao_existe_e_recusado_com_a_razao()
    {
        var e = Assert.Throws<RegraDeNegocioException>(
            () => _base.Usuarios().Excluir(999_999, Administrador()));

        Assert.Contains("não encontrado", e.Message);
    }


    [Fact]
    public void Nome_maior_que_a_coluna_e_recusado_sem_estourar()
    {
        // LOGIN.NOME e VARCHAR(20). Comparar um parametro maior faz o Firebird estourar com
        // "string right truncation", e a API devolvia HTTP 500 em vez de recusar o login.
        // Encontrado na instalacao de ensaio: 20 caracteres davam 401, 21 davam 500.
        var repo = _base.Usuarios();

        var r = repo.Autenticar(new string('A', RegrasUsuario.TamanhoMaximoNome + 1), "qualquer");

        Assert.False(r.Autenticado);
        // Mesma mensagem das outras recusas: nao revela quais usuarios existem.
        Assert.Equal("Usuário ou senha inválidos.", r.Motivo);
    }

    [Fact]
    public void Nome_no_tamanho_exato_da_coluna_ainda_e_consultado()
    {
        // A trava e para o que nao cabe; 20 caracteres cabem e precisam chegar ao banco.
        var repo = _base.Usuarios();
        var nome = new string('B', RegrasUsuario.TamanhoMaximoNome);

        var r = repo.Autenticar(nome, "qualquer");

        Assert.False(r.Autenticado);
        Assert.Equal("Usuário ou senha inválidos.", r.Motivo);
    }
    // ---------------- Apoio ----------------

    private int SubdespesaQualquer()
    {
        using var con = _base.Conexao.Abrir();
        return con.ExecuteScalar<int>("SELECT FIRST 1 SUBCATEGORIA_ID FROM SUBCATEGORIA");
    }

    private int ContaQualquer()
    {
        using var con = _base.Conexao.Abrir();
        return con.ExecuteScalar<int>("SELECT FIRST 1 CONTA_ID FROM CONTAS");
    }

    private int FormaQualquer()
    {
        using var con = _base.Conexao.Abrir();
        return con.ExecuteScalar<int>("SELECT FIRST 1 FORMA_DE_PAGAMENTO_ID FROM FORMA_DE_PAGAMENTO");
    }
}
