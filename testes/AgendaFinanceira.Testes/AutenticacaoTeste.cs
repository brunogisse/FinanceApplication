using Dapper;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Autenticação durante a convivência com o legado — ADR 0010.
///
/// A base de teste é descartável, e os usuários usados aqui são criados pelo próprio teste,
/// com senha conhecida. Nenhuma senha real do sistema aparece no código.
/// </summary>
public class AutenticacaoTeste : IClassFixture<BaseDescartavel>
{
    private readonly BaseDescartavel _base;
    public AutenticacaoTeste(BaseDescartavel baseDescartavel) => _base = baseDescartavel;

    /// <summary>
    /// Cria um usuário como o legado o criaria: senha em texto plano, sem hash.
    ///
    /// O setor é preenchido porque o Delphi **não** o preenche e quem fica sem setor não
    /// entra — é o que <see cref="Usuario_sem_setor_nao_entra_mesmo_com_a_senha_certa"/> prova.
    /// Aqui o assunto é a migração da senha, então o usuário nasce utilizável.
    /// </summary>
    private (string Nome, string Senha) CriarUsuarioDoLegado(
        string senha = "abc123", int nivel = 2, int? setor = 1)
    {
        var nome = "TESTE" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
        using var con = _base.Conexao.Abrir();
        con.Execute("INSERT INTO LOGIN (NOME, SENHA, NIVEL, SETOR_ID) VALUES (@n, @s, @v, @setor)",
                    new { n = nome, s = senha, v = nivel, setor });
        return (nome, senha);
    }

    private string? HashGravado(string nome)
    {
        using var con = _base.Conexao.Abrir();
        return con.QuerySingleOrDefault<string?>(
            "SELECT SENHA_HASH FROM LOGIN WHERE NOME = @n", new { n = nome });
    }

    private string? SenhaPlanaGravada(string nome)
    {
        using var con = _base.Conexao.Abrir();
        return con.QuerySingleOrDefault<string?>(
            "SELECT SENHA FROM LOGIN WHERE NOME = @n", new { n = nome });
    }

    [Fact]
    public void A_coluna_de_convivencia_existe_na_base()
    {
        Assert.True(_base.Usuarios().ColunaDeHashExiste(),
            "Sem SENHA_HASH a autenticação não roda. Ver ADR 0010.");
    }

    [Fact]
    public void Primeiro_acesso_valida_pelo_texto_plano_do_legado_e_grava_o_hash()
    {
        var (nome, senha) = CriarUsuarioDoLegado();
        Assert.Null(HashGravado(nome));           // nasce sem hash, como todos os do legado

        var r = _base.Usuarios().Autenticar(nome, senha);

        Assert.True(r.Autenticado);
        Assert.True(r.MigrouSenha);
        Assert.NotNull(HashGravado(nome));        // migrou sozinho, sem ninguém pedir
    }

    [Fact]
    public void Usuario_sem_setor_nao_entra_mesmo_com_a_senha_certa()
    {
        // É o que acontece com quem for cadastrado pela tela do Delphi, que não conhece a
        // coluna. Sem setor não há o que mostrar: nem tudo, que vazaria o outro lado, nem
        // nada, que pareceria uma base vazia. A recusa é no login, com o motivo escrito.
        var (nome, senha) = CriarUsuarioDoLegado(setor: null);

        var r = _base.Usuarios().Autenticar(nome, senha);

        Assert.False(r.Autenticado);
        Assert.Contains("setor", r.Motivo!, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Segundo_acesso_ja_usa_o_hash()
    {
        var (nome, senha) = CriarUsuarioDoLegado();
        _base.Usuarios().Autenticar(nome, senha);

        var r = _base.Usuarios().Autenticar(nome, senha);

        Assert.True(r.Autenticado);
        Assert.False(r.MigrouSenha);              // dessa vez não precisou migrar nada
    }

    [Fact]
    public void O_texto_plano_continua_la_para_o_legado_seguir_funcionando()
    {
        var (nome, senha) = CriarUsuarioDoLegado();
        _base.Usuarios().Autenticar(nome, senha);

        // É o preço da convivência, registrado como risco aceito no ADR 0010:
        // o Delphi compara texto plano e continuaria quebrado sem esta coluna.
        Assert.Equal(senha, SenhaPlanaGravada(nome));
    }

    [Fact]
    public void O_hash_gravado_nao_e_a_senha()
    {
        var (nome, senha) = CriarUsuarioDoLegado();
        _base.Usuarios().Autenticar(nome, senha);

        var hash = HashGravado(nome);
        Assert.NotNull(hash);
        Assert.DoesNotContain(senha, hash);
        Assert.StartsWith("$2", hash);            // formato do BCrypt
    }

    [Fact]
    public void Senha_errada_e_recusada_antes_da_migracao()
    {
        var (nome, _) = CriarUsuarioDoLegado();

        var r = _base.Usuarios().Autenticar(nome, "senha-errada");

        Assert.False(r.Autenticado);
        Assert.Null(HashGravado(nome));           // e não migra nada com senha errada
    }

    [Fact]
    public void Senha_errada_e_recusada_depois_da_migracao()
    {
        var (nome, senha) = CriarUsuarioDoLegado();
        _base.Usuarios().Autenticar(nome, senha);

        Assert.False(_base.Usuarios().Autenticar(nome, "senha-errada").Autenticado);
    }

    [Fact]
    public void Usuario_inexistente_recebe_a_mesma_recusa_que_senha_errada()
    {
        var r = _base.Usuarios().Autenticar("NAO_EXISTE_" + Guid.NewGuid().ToString("N")[..6], "x");

        Assert.False(r.Autenticado);
        // Mensagem idêntica de propósito: não entrega quais usuários existem.
        Assert.Equal("Usuário ou senha inválidos.", r.Motivo);
    }

    [Fact]
    public void Nome_de_usuario_nao_diferencia_maiusculas_como_no_legado()
    {
        var (nome, senha) = CriarUsuarioDoLegado();

        Assert.True(_base.Usuarios().Autenticar(nome.ToLowerInvariant(), senha).Autenticado);
    }

    [Fact]
    public void Senha_diferencia_maiusculas()
    {
        var (nome, _) = CriarUsuarioDoLegado("Senha123");

        Assert.False(_base.Usuarios().Autenticar(nome, "senha123").Autenticado);
    }

    [Fact]
    public void Campos_vazios_sao_recusados_sem_ir_ao_banco()
    {
        var repo = _base.Usuarios();
        Assert.False(repo.Autenticar("", "x").Autenticado);
        Assert.False(repo.Autenticar("alguem", "").Autenticado);
    }

    [Fact]
    public void Troca_de_senha_grava_nas_duas_colunas()
    {
        var (nome, senha) = CriarUsuarioDoLegado();
        var repo = _base.Usuarios();
        var usuario = repo.Autenticar(nome, senha).Usuario!;

        repo.TrocarSenha(usuario.Id, "novaSenha1");

        Assert.Equal("novaSenha1", SenhaPlanaGravada(nome));       // o Delphi continua entrando
        Assert.True(repo.Autenticar(nome, "novaSenha1").Autenticado);
        Assert.False(repo.Autenticar(nome, senha).Autenticado);    // a antiga não vale mais
    }

    [Fact]
    public void Troca_de_senha_respeita_o_limite_da_coluna_do_legado()
    {
        var (nome, senha) = CriarUsuarioDoLegado();
        var usuario = _base.Usuarios().Autenticar(nome, senha).Usuario!;

        var e = Assert.Throws<RegraDeNegocioException>(
            () => _base.Usuarios().TrocarSenha(usuario.Id, new string('x', 21)));
        Assert.Contains("20 caracteres", e.Message);
    }

    [Fact]
    public void Troca_de_senha_de_usuario_inexistente_e_recusada()
    {
        Assert.Throws<RegraDeNegocioException>(() => _base.Usuarios().TrocarSenha(999999, "qualquer"));
    }

    // ---- Níveis de acesso e autoria ----

    [Fact]
    public void Nivel_define_o_que_o_usuario_pode()
    {
        var (nomeConsulta, s1) = CriarUsuarioDoLegado(nivel: 1);
        var (nomeAdmin, s2) = CriarUsuarioDoLegado(nivel: 3);
        var repo = _base.Usuarios();

        var consulta = repo.Autenticar(nomeConsulta, s1).Usuario!;
        var admin = repo.Autenticar(nomeAdmin, s2).Usuario!;

        Assert.False(consulta.PodeLancar);
        Assert.False(consulta.PodeImportarPlanilha);
        Assert.True(admin.PodeLancar);
        Assert.True(admin.PodeImportarPlanilha);
        Assert.True(admin.PodeCadastrarUsuarios);
    }

    [Fact]
    public void So_quem_lancou_pode_modificar_com_o_usuario_um_podendo_tudo()
    {
        var usuario5 = new Usuario
        {
            Id = 5, Nome = "aline", Nivel = NivelAcesso.Operacao,
            Setor = Setor.Faturamento, AindaSemHash = false
        };
        var usuario1 = new Usuario
        {
            Id = 1, Nome = "JULIANA", Nivel = NivelAcesso.Administracao,
            Setor = Setor.Financeiro, AindaSemHash = false
        };

        Assert.True(usuario5.PodeModificarLancamentoDe(5));
        Assert.False(usuario5.PodeModificarLancamentoDe(1));   // no legado isto é permitido: a
                                                               // checagem está comentada no Alterar
        Assert.True(usuario1.PodeModificarLancamentoDe(5));    // o usuário 1 pode tudo
    }

    [Fact]
    public void Listar_mostra_quem_ainda_nao_migrou_a_senha()
    {
        var (nome, senha) = CriarUsuarioDoLegado();
        var repo = _base.Usuarios();

        Assert.True(repo.Listar().Single(u => u.Nome == nome).AindaSemHash);

        repo.Autenticar(nome, senha);

        Assert.False(repo.Listar().Single(u => u.Nome == nome).AindaSemHash);
    }
}
