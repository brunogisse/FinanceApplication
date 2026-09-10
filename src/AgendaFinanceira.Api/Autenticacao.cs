using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Api;

/// <summary>
/// Emite os tokens de acesso.
///
/// A chave de assinatura **nunca** vive em arquivo versionado. Ela vem da configuração
/// (variável de ambiente ou user-secrets) e, se faltar, a API se recusa a subir — falhar
/// fechada é melhor do que subir com uma chave que qualquer um com acesso ao código conhece.
/// </summary>
public sealed class ServicoToken
{
    public const string Emissor = "agenda-financeira";
    private readonly SymmetricSecurityKey _chave;
    private readonly TimeSpan _validade;

    public ServicoToken(string chave, TimeSpan validade)
    {
        _chave = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(chave));
        _validade = validade;
    }

    public (string Token, DateTime Expira) Emitir(Usuario usuario)
    {
        var expira = DateTime.UtcNow.Add(_validade);

        var token = new JwtSecurityToken(
            issuer: Emissor,
            audience: Emissor,
            claims:
            [
                new Claim(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
                new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
                new Claim(ClaimTypes.Name, usuario.Nome),
                new Claim(ClaimTypes.Role, usuario.Nivel.ToString()),
                new Claim("nivel", ((int)usuario.Nivel).ToString()),
                // O setor viaja no token, assinado, e não é escolhido pelo cliente. Uma tela
                // que pedisse "me mostre o setor 1" seria só um parâmetro a mais para mexer.
                new Claim("setor", usuario.Setor.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            ],
            expires: expira,
            signingCredentials: new SigningCredentials(_chave, SecurityAlgorithms.HmacSha256));

        return (new JwtSecurityTokenHandler().WriteToken(token), expira);
    }

    public SymmetricSecurityKey Chave => _chave;

    /// <summary>Gera uma chave aleatória, para quem precisar configurar a sua.</summary>
    public static string GerarChaveAleatoria() =>
        Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
}

/// <summary>Nomes das políticas de autorização, espelhando os níveis do legado.</summary>
public static class Politicas
{
    /// <summary>Nível 2 ou 3. No legado, o nível 1 perde o menu de Cadastros.</summary>
    public const string PodeOperar = "PodeOperar";

    /// <summary>Nível 3. No legado, é quem enxerga o cadastro de usuários.</summary>
    public const string PodeAdministrar = "PodeAdministrar";
}

public static class ConfiguracaoAutenticacao
{
    /// <summary>Lê a chave da configuração e recusa subir sem ela.</summary>
    public static string ExigirChave(IConfiguration config)
    {
        var chave = config["Jwt:Chave"];

        if (string.IsNullOrWhiteSpace(chave))
            throw new InvalidOperationException(
                "A chave de assinatura dos tokens não está configurada, e a API não sobe sem ela.\n\n" +
                "Defina 'Jwt:Chave' fora do repositório, por variável de ambiente:\n" +
                "    setx Jwt__Chave \"" + ServicoToken.GerarChaveAleatoria() + "\"\n\n" +
                "ou por user-secrets, na pasta do projeto:\n" +
                "    dotnet user-secrets set \"Jwt:Chave\" \"<chave>\"\n\n" +
                "Nunca grave a chave no appsettings.json: ele é versionado e acompanha " +
                "qualquer cópia do repositório.");

        // 32 bytes é o mínimo para HMAC-SHA256 não ser o elo fraco.
        if (Encoding.UTF8.GetByteCount(chave) < 32)
            throw new InvalidOperationException(
                "A chave de assinatura precisa ter pelo menos 32 bytes. " +
                "Gere uma com: " + ServicoToken.GerarChaveAleatoria());

        return chave;
    }

    public static void AdicionarAutenticacao(this IServiceCollection servicos, string chave)
    {
        var servicoToken = new ServicoToken(chave, TimeSpan.FromHours(12));
        servicos.AddSingleton(servicoToken);

        servicos.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(opcoes =>
                {
                    opcoes.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = ServicoToken.Emissor,
                        ValidAudience = ServicoToken.Emissor,
                        IssuerSigningKey = servicoToken.Chave,
                        ClockSkew = TimeSpan.FromMinutes(1)
                    };
                });

        servicos.AddAuthorization(opcoes =>
        {
            opcoes.AddPolicy(Politicas.PodeOperar, p => p.RequireAssertion(c =>
                int.TryParse(c.User.FindFirst("nivel")?.Value, out var n) && n >= 2));

            opcoes.AddPolicy(Politicas.PodeAdministrar, p => p.RequireAssertion(c =>
                int.TryParse(c.User.FindFirst("nivel")?.Value, out var n) && n >= 3));
        });
    }

    /// <summary>Identificador do usuário autenticado, extraído do token.</summary>
    public static int IdDoUsuario(this ClaimsPrincipal usuario) =>
        int.TryParse(usuario.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : 0;

    /// <summary>
    /// Monta o usuário a partir do token, sem ida ao banco.
    ///
    /// Mora aqui, e não em um arquivo de endpoints, porque mais de um grupo precisa dele —
    /// duas cópias divergiriam no dia em que o token ganhasse um campo.
    /// </summary>
    public static Usuario Autenticado(this ClaimsPrincipal quem)
    {
        var nivel = int.TryParse(quem.FindFirst("nivel")?.Value, out var n) ? n : 1;
        return new Usuario
        {
            Id = quem.IdDoUsuario(),
            Nome = quem.Identity?.Name ?? "",
            Nivel = (NivelAcesso)nivel,
            Setor = quem.SetorDaSessao(),
            AindaSemHash = false
        };
    }

    /// <summary>
    /// O setor gravado no token.
    ///
    /// Token sem a informação — emitido antes desta versão — devolve o setor inválido, e a
    /// primeira consulta recusa com a mensagem pedindo para entrar de novo. É melhor do que
    /// escolher um setor por padrão, que mostraria a alguém a lista da outra pessoa.
    /// </summary>
    public static Setor SetorDaSessao(this ClaimsPrincipal quem) =>
        int.TryParse(quem.FindFirst("setor")?.Value, out var s) && s > 0
            ? Setor.De(s)
            : default;
}
