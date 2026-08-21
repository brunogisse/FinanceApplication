using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Dapper;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Os números da tela inicial.
///
/// O painel agrega por um caminho próprio o que outros endpoints já calculam de outro jeito, e
/// é aí que mora o risco: uma soma que diverge da grade faz a tela inicial mentir sem ninguém
/// perceber. Estes testes comparam os dois caminhos.
/// </summary>
public class PainelApiTeste : IClassFixture<PainelApiTeste.Api>
{
    public sealed class Api : WebApplicationFactory<Program>
    {
        public BaseDescartavel Banco { get; } = new();

        protected override IHost CreateHost(IHostBuilder builder)
        {
            builder.ConfigureHostConfiguration(c => c.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Banco:Caminho"] = Banco.Caminho,
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
    public PainelApiTeste(Api api) => _api = api;

    /// <summary>Um mês com bastante movimento na base de paridade.</summary>
    private const string MesCheio = "2023-06";

    private async Task<HttpClient> ClienteAutenticado()
    {
        var nome = "PNL" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
        using (var con = _api.Banco.Conexao.Abrir())
            con.Execute("INSERT INTO LOGIN (NOME, SENHA, NIVEL) VALUES (@n, 'pnl123', 1)",
                        new { n = nome });

        var anonimo = _api.CreateClient();
        var r = await anonimo.PostAsJsonAsync("/sessao", new { usuario = nome, senha = "pnl123" });
        r.EnsureSuccessStatusCode();
        var corpo = await r.Content.ReadFromJsonAsync<Dictionary<string, object>>();

        var cliente = _api.CreateClient();
        cliente.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", corpo!["token"].ToString());
        return cliente;
    }

    private static async Task<JsonElement> Ler(HttpClient cliente, string rota) =>
        JsonDocument.Parse(await cliente.GetStringAsync(rota)).RootElement;

    [Fact]
    public async Task Os_dias_do_calendario_somam_o_previsto_do_mes()
    {
        var cliente = await ClienteAutenticado();
        var p = await Ler(cliente, $"/painel?mes={MesCheio}");

        var previsto = p.GetProperty("previstoNoMes");
        var quantidade = previsto.GetProperty("quantidade").GetInt32();
        Assert.True(quantidade > 0, $"o mês {MesCheio} deveria ter vencimentos na base de paridade");

        decimal somaDosDias = 0;
        var contagemDosDias = 0;
        foreach (var dia in p.GetProperty("dias").EnumerateArray())
        {
            somaDosDias += dia.GetProperty("total").GetDecimal();
            contagemDosDias += dia.GetProperty("quantidade").GetInt32();
        }

        // O calendário e o card falam do mesmo conjunto; se divergirem, um dos dois mente.
        Assert.Equal(previsto.GetProperty("total").GetDecimal(), somaDosDias);
        Assert.Equal(quantidade, contagemDosDias);
    }

    [Fact]
    public async Task O_vencido_do_painel_bate_com_o_aviso_de_vencimentos()
    {
        var cliente = await ClienteAutenticado();

        // Dois caminhos independentes para o mesmo número: o card do painel e o endpoint que
        // já existia, que por sua vez reproduz o aviso do legado ao abrir o sistema.
        var painel = (await Ler(cliente, "/painel")).GetProperty("vencido");
        var aviso = await Ler(cliente, "/lancamentos/vencimentos");

        Assert.Equal(aviso.GetProperty("quantidade").GetInt32(),
                     painel.GetProperty("quantidade").GetInt32());
        Assert.Equal(aviso.GetProperty("totalPrevisto").GetDecimal(),
                     painel.GetProperty("total").GetDecimal());
    }

    [Fact]
    public async Task O_pago_do_mes_bate_com_a_consulta_por_data_de_pagamento()
    {
        var cliente = await ClienteAutenticado();

        var painel = (await Ler(cliente, $"/painel?mes={MesCheio}")).GetProperty("pagoNoMes");
        var consulta = await Ler(cliente,
            $"/lancamentos?inicio={MesCheio}-01&fim={MesCheio}-30&porData=pagamento&pagamento=pagos");

        Assert.Equal(consulta.GetProperty("quantidade").GetInt32(),
                     painel.GetProperty("quantidade").GetInt32());
        Assert.Equal(consulta.GetProperty("totalPago").GetDecimal(),
                     painel.GetProperty("total").GetDecimal());
    }

    [Fact]
    public async Task A_serie_traz_doze_meses_terminando_no_mes_pedido()
    {
        var cliente = await ClienteAutenticado();
        var p = await Ler(cliente, $"/painel?mes={MesCheio}");

        var meses = p.GetProperty("serie").EnumerateArray()
                     .Select(m => m.GetProperty("mes").GetString())
                     .ToList();

        Assert.Equal(12, meses.Count);
        Assert.Equal(MesCheio, meses[^1]);
        Assert.Equal("2022-07", meses[0]);

        // Mês sem movimento aparece zerado, não sumido: buraco no meio da série engana os olhos.
        Assert.All(meses, m => Assert.Matches(@"^\d{4}-\d{2}$", m!));
    }

    [Fact]
    public async Task O_previsto_da_serie_bate_com_a_consulta_do_mesmo_mes()
    {
        var cliente = await ClienteAutenticado();
        var p = await Ler(cliente, $"/painel?mes={MesCheio}");

        var ultimo = p.GetProperty("serie").EnumerateArray().Last();
        var consulta = await Ler(cliente,
            $"/lancamentos?inicio={MesCheio}-01&fim={MesCheio}-30&porData=vencimento");

        Assert.Equal(consulta.GetProperty("totalPrevisto").GetDecimal(),
                     ultimo.GetProperty("previsto").GetDecimal());
    }

    [Fact]
    public async Task Sem_mes_usa_o_corrente()
    {
        var cliente = await ClienteAutenticado();
        var p = await Ler(cliente, "/painel");

        Assert.Equal(DateTime.Today.ToString("yyyy-MM"), p.GetProperty("mes").GetString());
    }

    [Fact]
    public async Task Painel_exige_sessao()
    {
        var anonimo = _api.CreateClient();

        var r = await anonimo.GetAsync("/painel");

        Assert.Equal(HttpStatusCode.Unauthorized, r.StatusCode);
    }
}
