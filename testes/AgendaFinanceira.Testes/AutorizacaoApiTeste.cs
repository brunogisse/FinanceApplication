using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Dapper;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Sobe a API de verdade contra uma cópia descartável e confere quem pode o quê.
///
/// O legado apenas esconde menus na tela — quem alcançasse o banco fazia o que quisesse.
/// Aqui a regra é verificada no servidor, e estes testes existem para que ela não se perca.
/// </summary>
public class AutorizacaoApiTeste : IClassFixture<AutorizacaoApiTeste.Api>, IDisposable
{
    public sealed class Api : WebApplicationFactory<Program>
    {
        public BaseDescartavel Banco { get; } = new();

        protected override IHost CreateHost(IHostBuilder builder)
        {
            builder.ConfigureHostConfiguration(c => c.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Banco:Caminho"] = Banco.Caminho,
                // Chave só deste teste. A de desenvolvimento vive em user-secrets, fora do repositório.
                ["Jwt:Chave"] = "chave-exclusiva-de-teste-com-tamanho-suficiente-para-hmac-sha256"
            }));
            return base.CreateHost(builder);
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            if (disposing) Banco.Dispose();
        }
    }

    private readonly Api _api;
    private readonly HttpClient _cliente;

    public AutorizacaoApiTeste(Api api)
    {
        _api = api;
        _cliente = api.CreateClient();
    }

    public void Dispose() => _cliente.Dispose();

    private string CriarUsuario(int nivel, string senha = "seg123")
    {
        var nome = "API" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
        using var con = _api.Banco.Conexao.Abrir();
        con.Execute("INSERT INTO LOGIN (NOME, SENHA, NIVEL) VALUES (@n, @s, @v)",
                    new { n = nome, s = senha, v = nivel });
        return nome;
    }

    private async Task<string> TokenDe(int nivel)
    {
        var nome = CriarUsuario(nivel);
        var r = await _cliente.PostAsJsonAsync("/sessao", new { usuario = nome, senha = "seg123" });
        r.EnsureSuccessStatusCode();
        var corpo = await r.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        return corpo!["token"].ToString()!;
    }

    private HttpClient ComToken(string token)
    {
        var c = _api.CreateClient();
        c.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return c;
    }

    // ---- Sem token ----

    [Theory]
    [InlineData("/contas")]
    [InlineData("/formas-pagamento")]
    [InlineData("/despesas")]
    [InlineData("/subdespesas")]
    [InlineData("/lancamentos")]
    [InlineData("/usuarios")]
    public async Task Sem_token_tudo_que_toca_dados_e_recusado(string rota)
    {
        var r = await _cliente.GetAsync(rota);
        Assert.Equal(HttpStatusCode.Unauthorized, r.StatusCode);
    }

    [Fact]
    public async Task Sem_token_nao_da_para_criar_cadastro()
    {
        var r = await _cliente.PostAsJsonAsync("/contas", new { descricao = "INVASOR" });
        Assert.Equal(HttpStatusCode.Unauthorized, r.StatusCode);
    }

    [Theory]
    [InlineData("/saude")]
    [InlineData("/swagger/index.html")]
    public async Task Diagnostico_e_documentacao_seguem_abertos(string rota)
    {
        var r = await _cliente.GetAsync(rota);
        Assert.Equal(HttpStatusCode.OK, r.StatusCode);
    }

    [Fact]
    public async Task Token_adulterado_e_recusado()
    {
        var token = await TokenDe(3);
        using var cliente = ComToken(token + "alteracao");

        var r = await cliente.GetAsync("/contas");
        Assert.Equal(HttpStatusCode.Unauthorized, r.StatusCode);
    }

    // ---- Nível 1: só consulta ----

    [Fact]
    public async Task Nivel_de_consulta_le_mas_nao_escreve()
    {
        using var cliente = ComToken(await TokenDe(1));

        Assert.Equal(HttpStatusCode.OK, (await cliente.GetAsync("/contas")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await cliente.GetAsync("/lancamentos")).StatusCode);

        var criar = await cliente.PostAsJsonAsync("/contas", new { descricao = "NAO DEVE ENTRAR" });
        Assert.Equal(HttpStatusCode.Forbidden, criar.StatusCode);

        var excluir = await cliente.DeleteAsync("/contas/1");
        Assert.Equal(HttpStatusCode.Forbidden, excluir.StatusCode);
    }

    [Fact]
    public async Task Nivel_de_consulta_nao_lista_usuarios()
    {
        using var cliente = ComToken(await TokenDe(1));
        Assert.Equal(HttpStatusCode.Forbidden, (await cliente.GetAsync("/usuarios")).StatusCode);
    }

    [Fact]
    public async Task O_que_o_nivel_1_tentou_criar_nao_foi_criado()
    {
        using var consulta = ComToken(await TokenDe(1));
        await consulta.PostAsJsonAsync("/contas", new { descricao = "FANTASMA" });

        using var admin = ComToken(await TokenDe(3));
        var contas = await admin.GetStringAsync("/contas");

        Assert.DoesNotContain("FANTASMA", contas);
    }

    // ---- Nível 2: opera ----

    [Fact]
    public async Task Nivel_de_operacao_cadastra()
    {
        using var cliente = ComToken(await TokenDe(2));

        var r = await cliente.PostAsJsonAsync("/contas",
            new { descricao = "CONTA NIVEL 2 " + Guid.NewGuid().ToString("N")[..6] });

        Assert.Equal(HttpStatusCode.Created, r.StatusCode);
    }

    [Fact]
    public async Task Nivel_de_operacao_nao_lista_usuarios()
    {
        using var cliente = ComToken(await TokenDe(2));
        Assert.Equal(HttpStatusCode.Forbidden, (await cliente.GetAsync("/usuarios")).StatusCode);
    }

    // ---- Nível 3: administra ----

    [Fact]
    public async Task Nivel_de_administracao_faz_tudo()
    {
        using var cliente = ComToken(await TokenDe(3));

        Assert.Equal(HttpStatusCode.OK, (await cliente.GetAsync("/usuarios")).StatusCode);

        var r = await cliente.PostAsJsonAsync("/despesas",
            new { descricao = "DESPESA NIVEL 3 " + Guid.NewGuid().ToString("N")[..6] });
        Assert.Equal(HttpStatusCode.Created, r.StatusCode);
    }

    // ---- Troca de senha ----

    [Fact]
    public async Task Usuario_comum_nao_troca_a_senha_de_outro()
    {
        var nome = CriarUsuario(2);
        var login = await _cliente.PostAsJsonAsync("/sessao", new { usuario = nome, senha = "seg123" });
        var corpo = await login.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        using var cliente = ComToken(corpo!["token"].ToString()!);

        var r = await cliente.PostAsJsonAsync("/sessao/trocar-senha",
            new { usuarioId = 1, senhaNova = "invadida" });   // usuário 1 não é ele

        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        Assert.Contains("própria senha", await r.Content.ReadAsStringAsync());
    }

    // ---- Recusa de credencial ----

    [Fact]
    public async Task Senha_errada_nao_devolve_token()
    {
        var nome = CriarUsuario(2);
        var r = await _cliente.PostAsJsonAsync("/sessao", new { usuario = nome, senha = "errada" });

        Assert.Equal(HttpStatusCode.Unauthorized, r.StatusCode);
        Assert.DoesNotContain("token", await r.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Usuario_inexistente_recebe_a_mesma_recusa_que_senha_errada()
    {
        var inexistente = await _cliente.PostAsJsonAsync("/sessao",
            new { usuario = "NINGUEM" + Guid.NewGuid().ToString("N")[..6], senha = "x" });

        var nome = CriarUsuario(2);
        var senhaErrada = await _cliente.PostAsJsonAsync("/sessao", new { usuario = nome, senha = "x" });

        Assert.Equal(HttpStatusCode.Unauthorized, inexistente.StatusCode);
        Assert.Equal(await senhaErrada.Content.ReadAsStringAsync(),
                     await inexistente.Content.ReadAsStringAsync());
    }
}
