using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Dapper;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Testes;

/// <summary>
/// Prova que uma sessão de um setor não alcança nada do outro.
///
/// **É o teste que existe porque o compilador não consegue provar isto.** Ele garante que toda
/// consulta recebe o setor; não garante que o `WHERE` foi escrito lá dentro. Com Dapper não há
/// filtro global como o `HasQueryFilter` do EF, então quem esquece a condição não recebe aviso
/// nenhum — recebe os registros do outro setor.
///
/// A base é uma cópia da unificada de verdade, com os dois setores dentro: 18.249 lançamentos
/// do financeiro e 15.664 do faturamento. **Nada foi fundido por semelhança**, então os 9.251
/// lançamentos que existiam nas duas bases existem duas vezes aqui, um em cada setor — e é por
/// isso que um mês pode dar exatamente o mesmo total nos dois lados sem que haja vazamento
/// nenhum. Ver docs/unificacao-das-bases.md.
///
/// As senhas dos usuários reais foram apagadas do molde; os usuários deste teste são criados
/// aqui, com senha conhecida.
/// </summary>
public class VazamentoEntreSetoresTeste : IClassFixture<VazamentoEntreSetoresTeste.ApiDoisSetores>
{
    /// <summary>Cópia descartável da base unificada, com os dois setores.</summary>
    public sealed class BaseDoisSetores : IDisposable
    {
        private const string Molde = @"C:\PROGRAMAS\AgendaFinanceira-paridade\MOLDE_DOIS_SETORES.FDB";

        public string Caminho { get; }
        public ConexaoFirebird Conexao { get; }

        public BaseDoisSetores()
        {
            Assert.True(File.Exists(Molde),
                $"Molde de dois setores não encontrado em {Molde}. " +
                "Gere-o com instalacao\\unificacao\\UNIFICAR.cmd e apague as senhas de LOGIN.");

            Caminho = Path.Combine(Path.GetTempPath(), $"agenda-setores-{Guid.NewGuid():N}.fdb");
            File.Copy(Molde, Caminho);
            Conexao = new ConexaoFirebird(Caminho);
        }

        public void Dispose()
        {
            for (var tentativa = 0; tentativa < 10; tentativa++)
            {
                try
                {
                    if (File.Exists(Caminho)) File.Delete(Caminho);
                    return;
                }
                catch (IOException) { Thread.Sleep(200); }
                catch (UnauthorizedAccessException) { Thread.Sleep(200); }
            }
        }
    }

    public sealed class ApiDoisSetores : WebApplicationFactory<Program>
    {
        public BaseDoisSetores Banco { get; } = new();

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

    private const int Financeiro = 1;
    private const int Faturamento = 2;

    private readonly ApiDoisSetores _api;
    public VazamentoEntreSetoresTeste(ApiDoisSetores api) => _api = api;

    // ---------------- Apoio ----------------

    /// <summary>Cria um usuário nível 3 no setor pedido e devolve um cliente já autenticado.</summary>
    private async Task<HttpClient> ClienteDoSetor(int setor)
    {
        var nome = "SET" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
        using (var con = _api.Banco.Conexao.Abrir())
            con.Execute("INSERT INTO LOGIN (NOME, SENHA, NIVEL, SETOR_ID) VALUES (@n, 'set123', 3, @s)",
                        new { n = nome, s = setor });

        var anonimo = _api.CreateClient();
        var r = await anonimo.PostAsJsonAsync("/sessao", new { usuario = nome, senha = "set123" });
        r.EnsureSuccessStatusCode();
        var corpo = await r.Content.ReadFromJsonAsync<Dictionary<string, JsonElement>>();

        Assert.Equal(setor, corpo!["setor"].GetInt32());

        var cliente = _api.CreateClient();
        cliente.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", corpo["token"].GetString());
        return cliente;
    }

    private static async Task<JsonElement> Ler(HttpClient cliente, string rota)
    {
        var r = await cliente.GetAsync(rota);
        r.EnsureSuccessStatusCode();
        return JsonDocument.Parse(await r.Content.ReadAsStringAsync()).RootElement;
    }

    /// <summary>Um identificador que existe SÓ no outro setor — o alvo das tentativas de escrita.</summary>
    private int UmLancamentoDoOutroSetor(int meuSetor)
    {
        var outro = meuSetor == Financeiro ? Faturamento : Financeiro;
        using var con = _api.Banco.Conexao.Abrir();
        return con.QuerySingle<int>(
            "SELECT MIN(GASTOS_ID) FROM REGISTRO_DE_GASTOS A WHERE A.SETOR_ID = @outro " +
            "  AND NOT EXISTS (SELECT 1 FROM REGISTRO_DE_GASTOS B " +
            "                  WHERE B.GASTOS_ID = A.GASTOS_ID AND B.SETOR_ID = @meu)",
            new { outro, meu = meuSetor });
    }

    private int ContarNoBanco(string sql, object? p = null)
    {
        using var con = _api.Banco.Conexao.Abrir();
        return con.ExecuteScalar<int>(sql, p);
    }

    // ---------------- O molde é mesmo de dois setores ----------------

    [Fact]
    public void A_base_de_teste_tem_mesmo_os_dois_setores_com_identificadores_separados()
    {
        Assert.True(ContarNoBanco("SELECT COUNT(*) FROM REGISTRO_DE_GASTOS WHERE SETOR_ID = 1") > 0);
        Assert.True(ContarNoBanco("SELECT COUNT(*) FROM REGISTRO_DE_GASTOS WHERE SETOR_ID = 2") > 0);

        // Nas bases de ORIGEM, 6.127 identificadores existiam nos dois lados apontando para
        // lançamentos sem parentesco nenhum: o generator continuou correndo nas duas depois que
        // elas se separaram. A unificação resolveu isso somando um deslocamento a tudo que veio
        // do faturamento, e é por isso que aqui não sobra nenhum repetido.
        //
        // Esta conferência existe para o dia em que alguém mexer no deslocamento: se voltarem a
        // colidir, um lançamento passa a ser alcançável pelo número nos dois setores.
        var repetidos = ContarNoBanco(
            "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS A JOIN REGISTRO_DE_GASTOS B " +
            "  ON B.GASTOS_ID = A.GASTOS_ID AND B.SETOR_ID = 2 WHERE A.SETOR_ID = 1");
        Assert.True(repetidos == 0,
            $"{repetidos} identificadores existem nos dois setores. O deslocamento da " +
            "unificação deveria ter separado as faixas.");
    }

    // ---------------- Leitura ----------------

    [Theory]
    [InlineData(Financeiro)]
    [InlineData(Faturamento)]
    public async Task Consulta_de_lancamentos_traz_so_o_do_proprio_setor(int setor)
    {
        var cliente = await ClienteDoSetor(setor);

        // Período largo de propósito: a intenção é varrer a base inteira.
        var corpo = await Ler(cliente, "/lancamentos?inicio=2000-01-01&fim=2099-12-31");

        var quantidade = corpo.GetProperty("quantidade").GetInt32();

        // O oráculo repete o mesmo período. Sem isso ele erra por 30 lançamentos do financeiro
        // com vencimento fora de 2000-2099 — data digitada torta no legado, não vazamento.
        var esperado = ContarNoBanco(
            "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS WHERE SETOR_ID = @s " +
            "  AND DATA_VENCIMENTO BETWEEN '2000-01-01' AND '2099-12-31'", new { s = setor });

        Assert.Equal(esperado, quantidade);
        Assert.True(quantidade > 0);

        // E, linha a linha, nenhum identificador de fora.
        var doOutroSetor = new HashSet<int>(IdsDoSetor(setor == Financeiro ? Faturamento : Financeiro));
        var meus = new HashSet<int>(IdsDoSetor(setor));

        foreach (var l in corpo.GetProperty("lancamentos").EnumerateArray())
        {
            var id = l.GetProperty("id").GetInt32();
            Assert.Contains(id, meus);
            if (!meus.Contains(id)) Assert.DoesNotContain(id, doOutroSetor);
        }
    }

    private IEnumerable<int> IdsDoSetor(int setor)
    {
        using var con = _api.Banco.Conexao.Abrir();
        return con.Query<int>("SELECT GASTOS_ID FROM REGISTRO_DE_GASTOS WHERE SETOR_ID = @s",
                              new { s = setor }).ToList();
    }

    [Theory]
    [InlineData(Financeiro)]
    [InlineData(Faturamento)]
    public async Task Painel_soma_so_o_proprio_setor(int setor)
    {
        var cliente = await ClienteDoSetor(setor);
        var corpo = await Ler(cliente, "/painel?mes=2023-06");

        var quantidade = corpo.GetProperty("previstoNoMes").GetProperty("quantidade").GetInt32();
        var esperado = ContarNoBanco(
            "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS " +
            "WHERE SETOR_ID = @s AND DATA_VENCIMENTO BETWEEN '2023-06-01' AND '2023-06-30'",
            new { s = setor });

        Assert.Equal(esperado, quantidade);
    }

    [Fact]
    public async Task Os_dois_paineis_somados_dao_o_mes_inteiro_e_nenhum_deles_sozinho()
    {
        /*
         * A conferência é de partição, e não de "os números são diferentes".
         *
         * Em junho de 2023 os dois setores dão exatamente 433 lançamentos e R$ 657.945,64 cada
         * — e isso é o esperado, não vazamento: são os lançamentos que já existiam nas duas
         * bases antes de elas se separarem, e a unificação os manteve nos dois lados, um por
         * setor. Um teste de "tem de dar diferente" reprovaria o comportamento correto.
         *
         * **É aqui que mora a advertência do documento:** somar os dois setores conta em dobro
         * o que é compartilhado. Não existe tela que faça isso hoje, e um "total da empresa"
         * nunca poderá ser soma simples.
         */
        var doFinanceiro = await Ler(await ClienteDoSetor(Financeiro), "/painel?mes=2023-06");
        var doFaturamento = await Ler(await ClienteDoSetor(Faturamento), "/painel?mes=2023-06");

        int Quantidade(JsonElement p) =>
            p.GetProperty("previstoNoMes").GetProperty("quantidade").GetInt32();

        var noMesInteiro = ContarNoBanco(
            "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS " +
            "WHERE DATA_VENCIMENTO BETWEEN '2023-06-01' AND '2023-06-30'");

        Assert.Equal(noMesInteiro, Quantidade(doFinanceiro) + Quantidade(doFaturamento));
        Assert.True(Quantidade(doFinanceiro) < noMesInteiro, "O financeiro está vendo o mês inteiro.");
        Assert.True(Quantidade(doFaturamento) < noMesInteiro, "O faturamento está vendo o mês inteiro.");
    }

    [Theory]
    [InlineData(Financeiro)]
    [InlineData(Faturamento)]
    public async Task Vencimentos_traz_so_o_do_proprio_setor(int setor)
    {
        var cliente = await ClienteDoSetor(setor);
        var corpo = await Ler(cliente, "/lancamentos/vencimentos?ate=2099-12-31");

        var esperado = ContarNoBanco(
            "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS WHERE SETOR_ID = @s AND PAGO = 0",
            new { s = setor });

        Assert.Equal(esperado, corpo.GetProperty("quantidade").GetInt32());
    }

    [Theory]
    [InlineData("/contas", "CONTAS", "CONTA_ID")]
    [InlineData("/formas-pagamento", "FORMA_DE_PAGAMENTO", "FORMA_DE_PAGAMENTO_ID")]
    [InlineData("/despesas", "CATEGORIA", "CATEGORIA_ID")]
    [InlineData("/subdespesas", "SUBCATEGORIA", "SUBCATEGORIA_ID")]
    public async Task Cadastros_trazem_so_a_lista_do_proprio_setor(string rota, string tabela, string chave)
    {
        foreach (var setor in new[] { Financeiro, Faturamento })
        {
            var cliente = await ClienteDoSetor(setor);
            var lista = await Ler(cliente, rota);

            var esperado = ContarNoBanco(
                $"SELECT COUNT(*) FROM {tabela} WHERE SETOR_ID = @s", new { s = setor });

            Assert.Equal(esperado, lista.GetArrayLength());
            Assert.True(lista.GetArrayLength() > 0, $"{rota} do setor {setor} veio vazia.");

            var doOutro = new HashSet<int>(IdsDeCadastro(tabela, chave,
                setor == Financeiro ? Faturamento : Financeiro));

            foreach (var item in lista.EnumerateArray())
                Assert.DoesNotContain(item.GetProperty("id").GetInt32(), doOutro);
        }
    }

    private IEnumerable<int> IdsDeCadastro(string tabela, string chave, int setor)
    {
        using var con = _api.Banco.Conexao.Abrir();
        return con.Query<int>($"SELECT {chave} FROM {tabela} WHERE SETOR_ID = @s",
                              new { s = setor }).ToList();
    }

    [Fact]
    public async Task Lancamento_do_outro_setor_responde_nao_encontrado()
    {
        var cliente = await ClienteDoSetor(Faturamento);
        var alheio = UmLancamentoDoOutroSetor(Faturamento);

        var r = await cliente.GetAsync($"/lancamentos/{alheio}");

        Assert.Equal(HttpStatusCode.NotFound, r.StatusCode);
    }

    [Fact]
    public async Task Consolidado_do_outro_setor_nao_traz_valor()
    {
        // Uma despesa que só existe no financeiro, pedida por quem é do faturamento.
        string despesaSoDoFinanceiro;
        using (var con = _api.Banco.Conexao.Abrir())
            despesaSoDoFinanceiro = con.QuerySingle<string>(@"
SELECT FIRST 1 TRIM(C.DESCRICAO) FROM CATEGORIA C
WHERE C.SETOR_ID = 1
  AND EXISTS (SELECT 1 FROM REGISTRO_DE_GASTOS R
              WHERE R.CATEGORIA_ID = C.CATEGORIA_ID AND R.PAGO = 1)
  AND NOT EXISTS (SELECT 1 FROM CATEGORIA C2
                  WHERE C2.SETOR_ID = 2 AND TRIM(C2.DESCRICAO) = TRIM(C.DESCRICAO))");

        var doFaturamento = await ClienteDoSetor(Faturamento);
        var vazio = await Ler(doFaturamento,
            $"/relatorios/por-despesa?despesa={Uri.EscapeDataString(despesaSoDoFinanceiro)}" +
            "&inicio=2000-01-01&fim=2099-12-31&pagos=true");
        Assert.Equal(0, vazio.GetArrayLength());

        // E a mesma pergunta, feita por quem é do financeiro, traz resultado — senão o teste
        // acima passaria por a despesa simplesmente não ter movimento.
        var doFinanceiro = await ClienteDoSetor(Financeiro);
        var cheio = await Ler(doFinanceiro,
            $"/relatorios/por-despesa?despesa={Uri.EscapeDataString(despesaSoDoFinanceiro)}" +
            "&inicio=2000-01-01&fim=2099-12-31&pagos=true");
        Assert.True(cheio.GetArrayLength() > 0);
    }

    // ---------------- Escrita ----------------

    [Fact]
    public async Task Nao_altera_lancamento_do_outro_setor()
    {
        var cliente = await ClienteDoSetor(Faturamento);
        var alheio = UmLancamentoDoOutroSetor(Faturamento);
        var descricaoAntes = DescricaoDe(alheio, Financeiro);

        var r = await cliente.PutAsJsonAsync($"/lancamentos/{alheio}", new
        {
            descricao = "INVASAO",
            subdespesaId = PrimeiroCadastro("SUBCATEGORIA", "SUBCATEGORIA_ID", Faturamento),
            contaId = PrimeiroCadastro("CONTAS", "CONTA_ID", Faturamento),
            formaPagamentoId = PrimeiroCadastro("FORMA_DE_PAGAMENTO", "FORMA_DE_PAGAMENTO_ID", Faturamento),
            valorPrevisto = 1m,
            dataVencimento = "2026-01-01"
        });

        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        Assert.Equal(descricaoAntes, DescricaoDe(alheio, Financeiro));
    }

    [Fact]
    public async Task Nao_exclui_lancamento_do_outro_setor()
    {
        var cliente = await ClienteDoSetor(Faturamento);
        var alheio = UmLancamentoDoOutroSetor(Faturamento);

        var r = await cliente.DeleteAsync($"/lancamentos/{alheio}");

        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        Assert.Equal(1, ContarNoBanco(
            "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = @id AND SETOR_ID = 1",
            new { id = alheio }));
    }

    [Fact]
    public async Task Nao_paga_em_lote_lancamento_do_outro_setor()
    {
        var cliente = await ClienteDoSetor(Faturamento);

        // Um lançamento do financeiro ainda em aberto, cujo número não existe do lado de cá.
        int alheio;
        using (var con = _api.Banco.Conexao.Abrir())
            alheio = con.QuerySingle<int>(
                "SELECT MIN(GASTOS_ID) FROM REGISTRO_DE_GASTOS A " +
                "WHERE A.SETOR_ID = 1 AND A.PAGO = 0 " +
                "  AND NOT EXISTS (SELECT 1 FROM REGISTRO_DE_GASTOS B " +
                "                  WHERE B.GASTOS_ID = A.GASTOS_ID AND B.SETOR_ID = 2)");

        var r = await cliente.PostAsJsonAsync("/lancamentos/pagar-em-lote", new { ids = new[] { alheio } });
        r.EnsureSuccessStatusCode();
        var corpo = JsonDocument.Parse(await r.Content.ReadAsStringAsync()).RootElement;

        // Cai em "não encontrado", junto com os que realmente não existem.
        Assert.Equal(0, corpo.GetProperty("pagos").GetArrayLength());
        Assert.Equal(1, corpo.GetProperty("naoEncontrados").GetArrayLength());

        Assert.Equal(1, ContarNoBanco(
            "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = @id AND SETOR_ID = 1 AND PAGO = 0",
            new { id = alheio }));
    }

    [Fact]
    public async Task Nao_parcela_lancamento_do_outro_setor()
    {
        var cliente = await ClienteDoSetor(Faturamento);
        var alheio = UmLancamentoDoOutroSetor(Faturamento);
        var antes = ContarNoBanco("SELECT COUNT(*) FROM REGISTRO_DE_GASTOS");

        var r = await cliente.PostAsJsonAsync($"/lancamentos/{alheio}/parcelar", new { parcelas = 3 });

        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        Assert.Equal(antes, ContarNoBanco("SELECT COUNT(*) FROM REGISTRO_DE_GASTOS"));
    }

    [Fact]
    public async Task Nao_altera_cadastro_do_outro_setor()
    {
        var cliente = await ClienteDoSetor(Faturamento);

        int contaAlheia;
        using (var con = _api.Banco.Conexao.Abrir())
            contaAlheia = con.QuerySingle<int>(
                "SELECT MIN(CONTA_ID) FROM CONTAS A WHERE A.SETOR_ID = 1 " +
                "  AND NOT EXISTS (SELECT 1 FROM CONTAS B " +
                "                  WHERE B.CONTA_ID = A.CONTA_ID AND B.SETOR_ID = 2)");

        var r = await cliente.PutAsJsonAsync($"/contas/{contaAlheia}", new { descricao = "INVADIDA" });

        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
        Assert.Equal(0, ContarNoBanco(
            "SELECT COUNT(*) FROM CONTAS WHERE CONTA_ID = @id AND DESCRICAO = 'INVADIDA'",
            new { id = contaAlheia }));
    }

    [Fact]
    public async Task Lancamento_criado_nasce_no_setor_de_quem_criou()
    {
        var cliente = await ClienteDoSetor(Faturamento);

        var r = await cliente.PostAsJsonAsync("/lancamentos", new
        {
            descricao = "NASCIDO NO FATURAMENTO " + Guid.NewGuid().ToString("N")[..6],
            subdespesaId = PrimeiroCadastro("SUBCATEGORIA", "SUBCATEGORIA_ID", Faturamento),
            contaId = PrimeiroCadastro("CONTAS", "CONTA_ID", Faturamento),
            formaPagamentoId = PrimeiroCadastro("FORMA_DE_PAGAMENTO", "FORMA_DE_PAGAMENTO_ID", Faturamento),
            valorPrevisto = 10m,
            dataVencimento = "2026-01-01"
        });

        r.EnsureSuccessStatusCode();
        var criado = JsonDocument.Parse(await r.Content.ReadAsStringAsync()).RootElement;
        var id = criado.GetProperty("id").GetInt32();

        Assert.Equal(1, ContarNoBanco(
            "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = @id AND SETOR_ID = 2",
            new { id }));
    }

    [Fact]
    public async Task Nao_lanca_usando_cadastro_do_outro_setor()
    {
        // A cadeia toda tem de ser do mesmo setor: senão o lançamento apareceria classificado
        // com um nome que quem lançou nunca viu.
        var cliente = await ClienteDoSetor(Faturamento);

        var r = await cliente.PostAsJsonAsync("/lancamentos", new
        {
            descricao = "SUBDESPESA ALHEIA",
            subdespesaId = PrimeiroCadastro("SUBCATEGORIA", "SUBCATEGORIA_ID", Financeiro),
            contaId = PrimeiroCadastro("CONTAS", "CONTA_ID", Faturamento),
            formaPagamentoId = PrimeiroCadastro("FORMA_DE_PAGAMENTO", "FORMA_DE_PAGAMENTO_ID", Faturamento),
            valorPrevisto = 10m,
            dataVencimento = "2026-01-01"
        });

        Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
    }

    [Fact]
    public async Task Cadastro_criado_nasce_no_setor_de_quem_criou_e_nome_repetido_no_outro_e_aceito()
    {
        var nome = "CONTA DE DOIS SETORES " + Guid.NewGuid().ToString("N")[..6];

        var doFinanceiro = await ClienteDoSetor(Financeiro);
        var primeira = await doFinanceiro.PostAsJsonAsync("/contas", new { descricao = nome });
        primeira.EnsureSuccessStatusCode();

        // O mesmo nome, do outro lado, é legítimo: são listas diferentes, e recusar seria
        // recusar por causa de um registro que quem cadastra não enxerga.
        var doFaturamento = await ClienteDoSetor(Faturamento);
        var segunda = await doFaturamento.PostAsJsonAsync("/contas", new { descricao = nome });
        segunda.EnsureSuccessStatusCode();

        Assert.Equal(1, ContarNoBanco(
            "SELECT COUNT(*) FROM CONTAS WHERE DESCRICAO = @d AND SETOR_ID = 1", new { d = nome }));
        Assert.Equal(1, ContarNoBanco(
            "SELECT COUNT(*) FROM CONTAS WHERE DESCRICAO = @d AND SETOR_ID = 2", new { d = nome }));

        // E repetir dentro do próprio setor continua recusado.
        var repetida = await doFaturamento.PostAsJsonAsync("/contas", new { descricao = nome });
        Assert.Equal(HttpStatusCode.BadRequest, repetida.StatusCode);
    }

    // ---------------- A rede de segurança do Delphi ----------------

    [Fact]
    public void Trigger_deduz_o_setor_do_lancamento_gravado_como_o_Delphi_grava()
    {
        // O Delphi não conhece a coluna. Sem a trigger, o registro nasceria sem setor e não
        // apareceria para ninguém — inclusive para quem acabou de digitá-lo.
        using var con = _api.Banco.Conexao.Abrir();

        var autorDoFaturamento = con.QuerySingle<int>(
            "SELECT MIN(LOGIN_ID) FROM LOGIN WHERE SETOR_ID = 2");

        var id = con.ExecuteScalar<int>(@"
INSERT INTO REGISTRO_DE_GASTOS
    (CATEGORIA_ID, SUBCATEGORIA_ID, CONTA_ID, FORMA_DE_PAGAMENTO_ID, USERID,
     DESCRICAO, VALOR_PREVISTO, VALOR_PAGO, PAGO, DATA_VENCIMENTO, DATA_CADASTRO)
VALUES
    ((SELECT MIN(CATEGORIA_ID) FROM CATEGORIA WHERE SETOR_ID = 2),
     (SELECT MIN(SUBCATEGORIA_ID) FROM SUBCATEGORIA WHERE SETOR_ID = 2),
     (SELECT MIN(CONTA_ID) FROM CONTAS WHERE SETOR_ID = 2),
     (SELECT MIN(FORMA_DE_PAGAMENTO_ID) FROM FORMA_DE_PAGAMENTO WHERE SETOR_ID = 2),
     @autor, 'GRAVADO PELO DELPHI', 1, 0, 0, '2026-01-01', '2026-01-01')
RETURNING GASTOS_ID", new { autor = autorDoFaturamento });

        var setor = con.QuerySingle<int?>(
            "SELECT SETOR_ID FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = @id", new { id });

        Assert.Equal(Faturamento, setor);
    }

    private int PrimeiroCadastro(string tabela, string chave, int setor)
    {
        using var con = _api.Banco.Conexao.Abrir();
        return con.QuerySingle<int>($"SELECT MIN({chave}) FROM {tabela} WHERE SETOR_ID = @s",
                                    new { s = setor });
    }

    private string DescricaoDe(int id, int setor)
    {
        using var con = _api.Banco.Conexao.Abrir();
        return con.QuerySingle<string>(
            "SELECT DESCRICAO FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = @id AND SETOR_ID = @s",
            new { id, s = setor });
    }
}
