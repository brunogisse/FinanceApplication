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
