using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using ClosedXML.Excel;
using Dapper;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Exportação da consulta para planilha, pelo endpoint, com o arquivo lido de volta.
///
/// Conferir a planilha abrindo o arquivo, e não só o código de resposta, é o que prova que a
/// pessoa vai encontrar os números certos — que é o ponto todo da exportação.
/// </summary>
public class ExportacaoApiTeste : IClassFixture<ExportacaoApiTeste.Api>
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
    public ExportacaoApiTeste(Api api) => _api = api;

    private async Task<HttpClient> ClienteAutenticado()
    {
        var nome = "EXP" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
        using (var con = _api.Banco.Conexao.Abrir())
            con.Execute("INSERT INTO LOGIN (NOME, SENHA, NIVEL) VALUES (@n, 'exp123', 1)",
                        new { n = nome });

        var anonimo = _api.CreateClient();
        var r = await anonimo.PostAsJsonAsync("/sessao", new { usuario = nome, senha = "exp123" });
        r.EnsureSuccessStatusCode();
        var corpo = await r.Content.ReadFromJsonAsync<Dictionary<string, object>>();

        var cliente = _api.CreateClient();
        cliente.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", corpo!["token"].ToString());
        return cliente;
    }

    /// <summary>Período largo o bastante para pegar a base inteira.</summary>
    private const string PeriodoInteiro = "inicio=2000-01-01&fim=2099-12-31";

    private static async Task<IXLWorksheet> AbaDa(HttpResponseMessage resposta)
    {
        var bytes = await resposta.Content.ReadAsByteArrayAsync();
        var memoria = new MemoryStream(bytes);
        return new XLWorkbook(memoria).Worksheets.First();
    }

    [Fact]
    public async Task Exporta_com_as_colunas_do_legado_na_mesma_ordem()
    {
        var cliente = await ClienteAutenticado();

        var r = await cliente.GetAsync($"/lancamentos/exportar?{PeriodoInteiro}");

        Assert.Equal(HttpStatusCode.OK, r.StatusCode);
        Assert.Equal(ExportadorDeLancamentos.TipoConteudo, r.Content.Headers.ContentType?.MediaType);
        Assert.Contains(".xlsx", r.Content.Headers.ContentDisposition?.FileName);

        var aba = await AbaDa(r);

        // As oito colunas do legado, na mesma ordem: LANCAMENTO, VALOR_PAGO, VALOR_PREVISTO,
        // NOTA_FISCAL, CHEQUE, DATA_VENCIMENTO, DATA_PAGAMENTO, CONTA.
        Assert.Equal("Descrição", aba.Cell(1, 1).GetString());
        Assert.Equal("Valor pago", aba.Cell(1, 2).GetString());
        Assert.Equal("Valor previsto", aba.Cell(1, 3).GetString());
        Assert.Equal("Nota fiscal", aba.Cell(1, 4).GetString());
        Assert.Equal("Cheque", aba.Cell(1, 5).GetString());
        Assert.Equal("Vencimento", aba.Cell(1, 6).GetString());
        Assert.Equal("Pagamento", aba.Cell(1, 7).GetString());
        Assert.Equal("Conta", aba.Cell(1, 8).GetString());
    }

    [Fact]
    public async Task Os_totais_da_planilha_batem_com_os_da_consulta()
    {
        var cliente = await ClienteAutenticado();

        // A mesma consulta pelos dois caminhos. Se divergirem, a planilha mente sobre a tela.
        var json = await cliente.GetStringAsync($"/lancamentos?{PeriodoInteiro}");
        var consulta = JsonDocument.Parse(json).RootElement;
        var quantidade = consulta.GetProperty("quantidade").GetInt32();
        var totalPrevisto = consulta.GetProperty("totalPrevisto").GetDecimal();
        var totalPago = consulta.GetProperty("totalPago").GetDecimal();

        var aba = await AbaDa(await cliente.GetAsync($"/lancamentos/exportar?{PeriodoInteiro}"));

        // Cabeçalho, os dados, uma linha em branco e a linha de total.
        var linhaDoTotal = quantidade + 3;
        Assert.Equal("TOTAL", aba.Cell(linhaDoTotal, 1).GetString());
        Assert.Equal(totalPago, (decimal)aba.Cell(linhaDoTotal, 2).Value.GetNumber());
        Assert.Equal(totalPrevisto, (decimal)aba.Cell(linhaDoTotal, 3).Value.GetNumber());

        // E o total tem de ser a soma do que está escrito, não um número à parte.
        decimal somaPago = 0, somaPrevisto = 0;
        for (var l = 2; l < linhaDoTotal - 1; l++)
        {
            somaPago += (decimal)aba.Cell(l, 2).Value.GetNumber();
            somaPrevisto += (decimal)aba.Cell(l, 3).Value.GetNumber();
        }
        Assert.Equal(totalPago, somaPago);
        Assert.Equal(totalPrevisto, somaPrevisto);
    }

    [Fact]
    public async Task Datas_saem_como_data_e_dinheiro_com_a_mascara_brasileira()
    {
        var cliente = await ClienteAutenticado();
        var aba = await AbaDa(await cliente.GetAsync($"/lancamentos/exportar?{PeriodoInteiro}"));

        // Data de verdade, não texto: é o que permite ordenar e filtrar no Excel.
        Assert.True(aba.Cell(2, 6).Value.IsDateTime, "o vencimento deveria ser uma data");
        Assert.Equal("dd/MM/yyyy", aba.Cell(2, 6).Style.DateFormat.Format);

        // A mesma máscara que o legado aplica.
        Assert.True(aba.Cell(2, 3).Value.IsNumber, "o valor previsto deveria ser um número");
        Assert.Equal("[$R$-416] #,##0.00", aba.Cell(2, 3).Style.NumberFormat.Format);
    }

    [Fact]
    public async Task Consulta_sem_resultado_recusa_em_vez_de_gerar_planilha_vazia()
    {
        var cliente = await ClienteAutenticado();

        var r = await cliente.GetAsync("/lancamentos/exportar?inicio=1990-01-01&fim=1990-01-31");

        // Um arquivo só com cabeçalho parece exportação bem-sucedida e não é.
        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        Assert.Contains("Não há lançamentos", await r.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Exportar_exige_sessao()
    {
        var anonimo = _api.CreateClient();

        var r = await anonimo.GetAsync($"/lancamentos/exportar?{PeriodoInteiro}");

        Assert.Equal(HttpStatusCode.Unauthorized, r.StatusCode);
    }
}
