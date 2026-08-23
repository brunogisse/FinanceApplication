using Dapper;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>Hash de senha com BCrypt.</summary>
public sealed class ServicoSenhaBCrypt : IServicoSenha
{
    public string GerarHash(string senha) => BCrypt.Net.BCrypt.HashPassword(senha);

    public bool Confere(string senha, string hash)
    {
        try { return BCrypt.Net.BCrypt.Verify(senha, hash); }
        catch (BCrypt.Net.SaltParseException) { return false; }
    }
}

/// <summary>Resultado de uma tentativa de autenticação.</summary>
public sealed record ResultadoAutenticacao
{
    public required bool Autenticado { get; init; }
    public Usuario? Usuario { get; init; }
    public string? Motivo { get; init; }

    /// <summary>Verdadeiro quando esta entrada migrou a senha do texto plano para o hash.</summary>
    public bool MigrouSenha { get; init; }

    public static ResultadoAutenticacao Recusado(string motivo) =>
        new() { Autenticado = false, Motivo = motivo };
}

/// <summary>
/// Autenticação sobre a tabela LOGIN do legado.
///
/// Estratégia de convivência do ADR 0010: a coluna SENHA_HASH é nova e o Delphi não a conhece.
/// Quem ainda não tem hash é validado contra o texto plano e tem o hash gravado naquele
/// momento, de modo que a base migra sozinha conforme as pessoas entram.
/// </summary>
public sealed class RepositorioUsuarios
{
    private readonly ConexaoFirebird _conexao;
    private readonly IServicoSenha _senhas;

    public RepositorioUsuarios(ConexaoFirebird conexao, IServicoSenha senhas)
    {
        _conexao = conexao;
        _senhas = senhas;
    }

    /// <summary>Confirma se a coluna de convivência existe. Sem ela, a autenticação não roda.</summary>
    public bool ColunaDeHashExiste()
    {
        using var con = _conexao.Abrir();
        var qtd = con.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM RDB$RELATION_FIELDS " +
            "WHERE TRIM(RDB$RELATION_NAME) = 'LOGIN' AND TRIM(RDB$FIELD_NAME) = 'SENHA_HASH'");
        return qtd > 0;
    }

    /// <summary>
    /// Autentica pelo nome, sem diferenciar maiúsculas — igual ao legado, que usa Locate
    /// com loCaseInsensitive.
    /// </summary>
    public ResultadoAutenticacao Autenticar(string nome, string senha)
    {
        if (string.IsNullOrWhiteSpace(nome))
            return ResultadoAutenticacao.Recusado("Informe o usuário.");
        if (string.IsNullOrEmpty(senha))
            return ResultadoAutenticacao.Recusado("Informe a senha.");

        /*
         * Nome maior que a coluna é recusado aqui, antes de chegar ao banco.
         *
         * `LOGIN.NOME` é VARCHAR(20), e comparar um parâmetro maior faz o Firebird estourar
         * com "string right truncation" — que vira **HTTP 500** em vez de recusa. Medido na
         * instalação de ensaio em 22/08/2026: 20 caracteres devolvem 401, 21 devolvem 500.
         *
         * Nenhum usuário pode ter nome maior que isso, então não há o que procurar. A
         * mensagem é a mesma das outras recusas, para não revelar quais usuários existem.
         */
        if (nome.Trim().Length > RegrasUsuario.TamanhoMaximoNome)
            return ResultadoAutenticacao.Recusado("Usuário ou senha inválidos.");

        using var con = _conexao.Abrir();

        // Diferente do legado, que traz a tabela LOGIN inteira — com todas as senhas — para a
        // estação a cada abertura, aqui só o usuário informado sai do banco.
        var linha = con.QuerySingleOrDefault(
            "SELECT LOGIN_ID, NOME, SENHA, NIVEL, SENHA_HASH FROM LOGIN WHERE UPPER(NOME) = @nome",
            new { nome = nome.Trim().ToUpperInvariant() });

        if (linha is null)
            return ResultadoAutenticacao.Recusado("Usuário ou senha inválidos.");

        int id = linha.LOGIN_ID;
        string nomeGravado = ConexaoFirebird.TextoDoLegado(linha.NOME) ?? "";
        string senhaPlana = ConexaoFirebird.TextoDoLegado(linha.SENHA) ?? "";
        string? hash = ConexaoFirebird.TextoDoLegado(linha.SENHA_HASH);
        int nivel = linha.NIVEL;

        var migrou = false;

        if (!string.IsNullOrEmpty(hash))
        {
            if (!_senhas.Confere(senha, hash))
                return ResultadoAutenticacao.Recusado("Usuário ou senha inválidos.");
        }
        else
        {
            // Ainda sem hash: valida contra o texto plano do legado e migra na hora.
            if (!string.Equals(senha, senhaPlana, StringComparison.Ordinal))
                return ResultadoAutenticacao.Recusado("Usuário ou senha inválidos.");

            con.Execute("UPDATE LOGIN SET SENHA_HASH = @hash WHERE LOGIN_ID = @id",
                        new { hash = _senhas.GerarHash(senha), id });
            migrou = true;
        }

        return new ResultadoAutenticacao
        {
            Autenticado = true,
            MigrouSenha = migrou,
            Usuario = new Usuario
            {
                Id = id,
                Nome = nomeGravado,
                Nivel = (NivelAcesso)nivel,
                AindaSemHash = false
            }
        };
    }

    /// <summary>
    /// Troca a senha gravando nas duas colunas: o hash para a API e o texto plano para o Delphi
    /// continuar funcionando. Quando o legado for desligado, a coluna SENHA é apagada e este
    /// método deixa de escrever nela.
    /// </summary>
    public void TrocarSenha(int usuarioId, string senhaNova)
    {
        if (string.IsNullOrWhiteSpace(senhaNova))
            throw new RegraDeNegocioException("Informe a nova senha.");

        // A coluna do legado tem 20 caracteres. Enquanto ele existir, a senha cabe nela.
        if (senhaNova.Length > 20)
            throw new RegraDeNegocioException(
                "Enquanto o sistema antigo estiver em uso, a senha pode ter no máximo 20 caracteres.");

        using var con = _conexao.Abrir();
        using var tx = con.BeginTransaction();
        try
        {
            var afetados = con.Execute(
                "UPDATE LOGIN SET SENHA = @plana, SENHA_HASH = @hash WHERE LOGIN_ID = @id",
                new { plana = senhaNova, hash = _senhas.GerarHash(senhaNova), id = usuarioId }, tx);

            if (afetados == 0)
                throw new RegraDeNegocioException("Usuário não encontrado.");

            tx.Commit();
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }


    /// <summary>
    /// Cria um usuário, gravando a senha nas duas colunas.
    ///
    /// O texto plano existe para o Delphi continuar autenticando quem for criado aqui — sem
    /// ele, a pessoa entraria pela API e seria recusada pelo sistema antigo. Some quando o
    /// legado for desligado.
    /// </summary>
    public Usuario Criar(DadosUsuario dados, string senha)
    {
        var nome = RegrasUsuario.ExigirNome(dados.Nome);
        var senhaLimpa = RegrasUsuario.ExigirSenha(senha);

        using var con = _conexao.Abrir();
        ExigirNomeInedito(con, nome, ignorarId: null);

        var id = con.ExecuteScalar<int>(@"
INSERT INTO LOGIN (NOME, SENHA, NIVEL, SENHA_HASH)
VALUES (@nome, @plana, @nivel, @hash)
RETURNING LOGIN_ID",
            new
            {
                nome = ConexaoFirebird.NormalizarParaGravar(nome),
                plana = senhaLimpa,
                nivel = (int)dados.Nivel,
                hash = _senhas.GerarHash(senhaLimpa)
            });

        return new Usuario { Id = id, Nome = nome, Nivel = dados.Nivel, AindaSemHash = false };
    }

    /// <summary>
    /// Altera nome e nível. A senha não passa por aqui: quem troca senha é
    /// <see cref="TrocarSenha"/>, e misturar as duas coisas faria uma alteração de nome
    /// reescrever a senha por descuido.
    /// </summary>
    public Usuario Alterar(int id, DadosUsuario dados, Usuario quemAltera)
    {
        var nome = RegrasUsuario.ExigirNome(dados.Nome);
        RegrasUsuario.ExigirQuePodeAlterar(id, dados.Nivel, quemAltera);

        using var con = _conexao.Abrir();
        ExigirNomeInedito(con, nome, ignorarId: id);

        var afetados = con.Execute(
            "UPDATE LOGIN SET NOME = @nome, NIVEL = @nivel WHERE LOGIN_ID = @id",
            new { nome = ConexaoFirebird.NormalizarParaGravar(nome), nivel = (int)dados.Nivel, id });

        if (afetados == 0)
            throw new RegraDeNegocioException("Usuário não encontrado.");

        return new Usuario { Id = id, Nome = nome, Nivel = dados.Nivel, AindaSemHash = false };
    }

    /// <summary>
    /// Exclui um usuário.
    ///
    /// Quem já lançou não pode ser excluído, e essa regra está no banco: existe a chave
    /// estrangeira FK_REGISTRO_DE_GASTOS_5, de USERID para LOGIN. Aqui a checagem é feita
    /// antes só para a mensagem dizer o número de lançamentos em vez de vazar o erro cru do
    /// Firebird — a recusa de verdade continua sendo do banco, mesmo que este código falhe.
    /// </summary>
    public void Excluir(int id, Usuario quemExclui)
    {
        RegrasUsuario.ExigirQuePodeExcluir(id, quemExclui);

        using var con = _conexao.Abrir();

        var nome = con.QuerySingleOrDefault<string>(
            "SELECT NOME FROM LOGIN WHERE LOGIN_ID = @id", new { id });
        if (nome is null)
            throw new RegraDeNegocioException("Usuário não encontrado.");

        var lancamentos = con.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS WHERE USERID = @id", new { id });

        // Frase neutra de propósito: "excluído/excluída" concordaria com um gênero que o nome
        // do usuário não informa.
        if (lancamentos > 0)
            throw new RegraDeNegocioException(
                $"Não é possível excluir {ConexaoFirebird.TextoDoLegado(nome)?.Trim()}: " +
                $"são {lancamentos:N0} lançamento(s), e a autoria deles se perderia.");

        con.Execute("DELETE FROM LOGIN WHERE LOGIN_ID = @id", new { id });
    }

    /// <summary>
    /// Nome único, sem diferenciar maiúsculas.
    ///
    /// O legado deixa criar dois usuários com o mesmo nome — e aí <see cref="Autenticar"/>,
    /// que busca por UPPER(NOME) esperando um só, **estoura com exceção em vez de recusar o
    /// login**. Nome repetido não é só desordem de cadastro: quebra a entrada no sistema.
    /// </summary>
    private static void ExigirNomeInedito(System.Data.IDbConnection con, string nome, int? ignorarId)
    {
        var existe = con.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM LOGIN WHERE UPPER(NOME) = @nome AND LOGIN_ID <> @ignorar",
            new { nome = nome.ToUpperInvariant(), ignorar = ignorarId ?? 0 });

        if (existe > 0)
            throw new RegraDeNegocioException($"Já existe um usuário chamado {nome}.");
    }
    public IReadOnlyList<Usuario> Listar()
    {
        using var con = _conexao.Abrir();
        return con.Query("SELECT LOGIN_ID, NOME, NIVEL, SENHA_HASH FROM LOGIN ORDER BY LOGIN_ID")
                  .Select(l => new Usuario
                  {
                      Id = l.LOGIN_ID,
                      Nome = ConexaoFirebird.TextoDoLegado(l.NOME) ?? "",
                      Nivel = (NivelAcesso)l.NIVEL,
                      AindaSemHash = string.IsNullOrEmpty(ConexaoFirebird.TextoDoLegado(l.SENHA_HASH))
                  }).ToList();
    }
}
