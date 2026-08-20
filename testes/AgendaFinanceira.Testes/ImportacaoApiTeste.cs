using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using ClosedXML.Excel;
using Dapper;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Importação de planilha ponta a ponta, pelo endpoint, com upload de arquivo de verdade.
/// </summary>
public class ImportacaoApiTeste : IClassFixture<ImportacaoApiTeste.Api>
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
    public ImportacaoApiTeste(Api api) => _api = api;

    private async Task<HttpClient> ClienteAutenticado(int nivel)
    {
        var nome = "IMP" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
        using (var con = _api.Banco.Conexao.Abrir())
            con.Execute("INSERT INTO LOGIN (NOME, SENHA, NIVEL) VALUES (@n, 'imp123', @v)",
                        new { n = nome, v = nivel });

        var anonimo = _api.CreateClient();
        var r = await anonimo.PostAsJsonAsync("/sessao", new { usuario = nome, senha = "imp123" });
        r.EnsureSuccessStatusCode();
        var corpo = await r.Content.ReadFromJsonAsync<Dictionary<string, object>>();

        var cliente = _api.CreateClient();
        cliente.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", corpo!["token"].ToString());
        return cliente;
    }

    private static byte[] PlanilhaXlsx(params (string Data, string Descricao, decimal? Valor)[] linhas)
    {
        using var arquivo = new XLWorkbook();
        var aba = arquivo.Worksheets.Add("Planilha1");
        aba.Cell(1, 1).Value = "DATA";
        aba.Cell(1, 2).Value = "DESCRICAO";
        aba.Cell(1, 3).Value = "VALOR";

        var n = 2;
        foreach (var (data, descricao, valor) in linhas)
        {
            if (!string.IsNullOrEmpty(data)) aba.Cell(n, 1).Value = data;
            aba.Cell(n, 2).Value = descricao;
            if (valor is not null) aba.Cell(n, 3).Value = valor.Value;
            n++;
        }

        using var memoria = new MemoryStream();
        arquivo.SaveAs(memoria);
        return memoria.ToArray();
    }

    private async Task<(int Sub, int Conta, int Forma)> Chaves(HttpClient cliente)
    {
        using var con = _api.Banco.Conexao.Abrir();
        var c = con.QuerySingle(
            "SELECT FIRST 1 S.SUBCATEGORIA_ID, " +
            "  (SELECT MIN(CONTA_ID) FROM CONTAS) AS CONTA, " +
            "  (SELECT MIN(FORMA_DE_PAGAMENTO_ID) FROM FORMA_DE_PAGAMENTO) AS FORMA " +
            "FROM SUBCATEGORIA S");
        await Task.CompletedTask;
        return ((int)c.SUBCATEGORIA_ID, (int)c.CONTA, (int)c.FORMA);
    }

    private static MultipartFormDataContent Upload(byte[] xlsx)
    {
        var conteudo = new MultipartFormDataContent();
        var arquivo = new ByteArrayContent(xlsx);
        arquivo.Headers.ContentType = new MediaTypeHeaderValue(
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        conteudo.Add(arquivo, "planilha", "lote.xlsx");
        return conteudo;
    }

    [Fact]
    public async Task Importa_a_planilha_pelo_endpoint()
    {
        var cliente = await ClienteAutenticado(3);
        var (sub, conta, forma) = await Chaves(cliente);

        var xlsx = PlanilhaXlsx(
            ("15/03/2026", "COMBUSTIVEL", 150.00m),
            ("", "POSTO CENTRAL", null),          // sem data: anexa à anterior
            ("16/03/2026", "MANUTENCAO", 250.50m));

        var r = await cliente.PostAsync(
            $"/lancamentos/importar?subdespesaId={sub}&contaId={conta}&formaPagamentoId={forma}",
            Upload(xlsx));

        Assert.Equal(HttpStatusCode.OK, r.StatusCode);
        var corpo = await r.Content.ReadAsStringAsync();

        Assert.Contains("\"quantidade\":2", corpo);
        // O JSON traz 400.5, que é o mesmo número que 400,50 — formatar é papel do cliente.
        Assert.Contains("\"total\":400.5", corpo);
        Assert.Contains("COMBUSTIVEL - POSTO CENTRAL", corpo);
        Assert.Contains("\"pago\":true", corpo);
    }

    [Fact]
    public async Task Nivel_de_operacao_nao_importa_planilha()
    {
        // No legado, o botão de planilha só aparece para o nível 3.
        var cliente = await ClienteAutenticado(2);
        var (sub, conta, forma) = await Chaves(cliente);

        var r = await cliente.PostAsync(
            $"/lancamentos/importar?subdespesaId={sub}&contaId={conta}&formaPagamentoId={forma}",
            Upload(PlanilhaXlsx(("15/03/2026", "QUALQUER", 10.00m))));

        Assert.Equal(HttpStatusCode.Forbidden, r.StatusCode);
    }

    [Fact]
    public async Task Planilha_com_linha_invalida_nao_grava_nada()
    {
        var cliente = await ClienteAutenticado(3);
        var (sub, conta, forma) = await Chaves(cliente);
        var antes = Total();

        var xlsx = PlanilhaXlsx(
            ("15/03/2026", "BOA", 100.00m),
            ("data invalida", "RUIM", 100.00m));

        var r = await cliente.PostAsync(
            $"/lancamentos/importar?subdespesaId={sub}&contaId={conta}&formaPagamentoId={forma}",
            Upload(xlsx));

        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        Assert.Contains("linha 3", await r.Content.ReadAsStringAsync());
        Assert.Equal(antes, Total());
    }

    [Fact]
    public async Task Arquivo_que_nao_e_planilha_recebe_recusa_explicada()
    {
        var cliente = await ClienteAutenticado(3);
        var (sub, conta, forma) = await Chaves(cliente);

        var r = await cliente.PostAsync(
            $"/lancamentos/importar?subdespesaId={sub}&contaId={conta}&formaPagamentoId={forma}",
            Upload("isto nao e uma planilha"u8.ToArray()));

        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        Assert.Contains(".xlsx", await r.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Previa_mostra_o_que_seria_gravado_sem_gravar()
    {
        var cliente = await ClienteAutenticado(3);
        var antes = Total();

        var xlsx = PlanilhaXlsx(
            ("15/03/2026", "COMBUSTIVEL", 150.00m),
            ("", "POSTO CENTRAL", null),
            ("16/03/2026", "MANUTENCAO", 250.50m));

        var r = await cliente.PostAsync("/lancamentos/importar/previa", Upload(xlsx));

        Assert.Equal(HttpStatusCode.OK, r.StatusCode);
        var corpo = await r.Content.ReadAsStringAsync();

        // A prévia lê com as mesmas regras da importação, inclusive a linha sem data.
        Assert.Contains("\"quantidade\":2", corpo);
        Assert.Contains("\"total\":400.5", corpo);
        Assert.Contains("COMBUSTIVEL - POSTO CENTRAL", corpo);
        // O número da linha física é o que permite achar o problema na planilha.
        Assert.Contains("\"numeroDaLinha\":2", corpo);

        // O ponto da prévia: nada foi gravado.
        Assert.Equal(antes, Total());
    }

    [Fact]
    public async Task Previa_recusa_planilha_invalida_antes_de_qualquer_escrita()
    {
        var cliente = await ClienteAutenticado(3);
        var antes = Total();

        var r = await cliente.PostAsync("/lancamentos/importar/previa",
                                        Upload(PlanilhaXlsx(("data invalida", "RUIM", 100.00m))));

        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        Assert.Contains("linha 2", await r.Content.ReadAsStringAsync());
        Assert.Equal(antes, Total());
    }

    [Fact]
    public async Task Previa_tambem_e_restrita_ao_nivel_3()
    {
        // Ver a planilha inteira é ver dados financeiros; segue a mesma porta da importação.
        var cliente = await ClienteAutenticado(2);

        var r = await cliente.PostAsync("/lancamentos/importar/previa",
                                        Upload(PlanilhaXlsx(("15/03/2026", "QUALQUER", 10.00m))));

        Assert.Equal(HttpStatusCode.Forbidden, r.StatusCode);
    }

    private int Total()
    {
        using var con = _api.Banco.Conexao.Abrir();
        return con.ExecuteScalar<int>("SELECT COUNT(*) FROM REGISTRO_DE_GASTOS");
    }
}
