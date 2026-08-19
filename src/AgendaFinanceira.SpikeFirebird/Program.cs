using System.Globalization;
using FirebirdSql.Data.FirebirdClient;

// Spike de acesso a dados — Etapa 1 do roadmap.
// Responde: o .NET conversa com o Firebird 2.5? Como chegam os valores FLOAT,
// as datas e a acentuação? Inserção sem ID funciona?
//
// Roda SEMPRE contra a cópia de trabalho, nunca contra produção.

var caminhoBanco = args.Length > 0
    ? args[0]
    : @"C:\Users\bruno\AppData\Local\Temp\claude\c--PROGRAMAS-V-OFICIAL\28e688ab-efb2-463a-831e-819f0706699c\scratchpad\COPIA_TRABALHO.FDB";

if (!File.Exists(caminhoBanco))
{
    Console.WriteLine($"ERRO: banco não encontrado em {caminhoBanco}");
    return 1;
}

if (caminhoBanco.Contains("AGENDA FINANCEIRA ITAPUA", StringComparison.OrdinalIgnoreCase))
{
    Console.WriteLine("ERRO: este spike não roda contra o banco de produção. Use uma cópia.");
    return 1;
}

var conexao = new FbConnectionStringBuilder
{
    DataSource = "localhost",
    Database = caminhoBanco,
    UserID = "SYSDBA",
    Password = "masterkey",
    Charset = "ISO8859_1",
    Dialect = 3,
    ServerType = FbServerType.Default,
    Pooling = false
}.ToString();

var ptBR = CultureInfo.GetCultureInfo("pt-BR");
Console.OutputEncoding = System.Text.Encoding.UTF8;
Console.WriteLine("=== SPIKE: acesso ao Firebird 2.5 pelo .NET 8 ===");
Console.WriteLine($"Banco: {Path.GetFileName(caminhoBanco)}");
Console.WriteLine();

try
{
    using var con = new FbConnection(conexao);
    con.Open();
    Console.WriteLine($"[1] Conexão OK. Servidor: {con.ServerVersion}");

    // --- 2. Como o provider mapeia os tipos das colunas ---
    Console.WriteLine();
    Console.WriteLine("[2] Tipos que o provider devolve:");
    using (var cmd = new FbCommand(
        "SELECT VALOR_PREVISTO, VALOR_PAGO, DATA_VENCIMENTO, PAGO, DESCRICAO " +
        "FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = 19035", con))
    using (var r = cmd.ExecuteReader())
    {
        if (r.Read())
            for (var i = 0; i < r.FieldCount; i++)
                Console.WriteLine($"    {r.GetName(i),-16} -> {r.GetFieldType(i).Name}");
    }

    // --- 3. O caso do valor impreciso ---
    Console.WriteLine();
    Console.WriteLine("[3] Leitura do lançamento 19035 (valor sabidamente impreciso):");
    using (var cmd = new FbCommand(
        "SELECT VALOR_PREVISTO FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = 19035", con))
    using (var r = cmd.ExecuteReader())
    {
        if (r.Read())
        {
            var cru = r.GetValue(0);
            var comoDouble = Convert.ToDouble(cru, CultureInfo.InvariantCulture);
            var comoDecimal = Math.Round((decimal)comoDouble, 2, MidpointRounding.AwayFromZero);

            Console.WriteLine($"    cru do banco ....: {cru} ({cru.GetType().Name})");
            Console.WriteLine($"    como double .....: {comoDouble:R}");
            Console.WriteLine($"    arredondado 2 casas: {comoDecimal.ToString("C", ptBR)}");
            Console.WriteLine($"    esperado ........: {147059.77m.ToString("C", ptBR)}");
            Console.WriteLine(comoDecimal == 147059.77m
                ? "    RESULTADO: conversão na borda funciona."
                : "    RESULTADO: ATENÇÃO — conversão não bateu com o esperado.");
        }
    }

    // --- 4. Data de calendário ---
    Console.WriteLine();
    Console.WriteLine("[4] Data de calendário (sem fuso):");
    using (var cmd = new FbCommand(
        "SELECT DATA_VENCIMENTO FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = 19035", con))
    using (var r = cmd.ExecuteReader())
    {
        if (r.Read())
        {
            var dt = r.GetDateTime(0);
            var somenteData = DateOnly.FromDateTime(dt);
            Console.WriteLine($"    DateTime ...: {dt:yyyy-MM-dd HH:mm:ss} (Kind={dt.Kind})");
            Console.WriteLine($"    DateOnly ...: {somenteData:dd/MM/yyyy}");
            Console.WriteLine(dt.TimeOfDay == TimeSpan.Zero
                ? "    RESULTADO: chega sem componente de hora, como esperado."
                : "    RESULTADO: ATENÇÃO — veio com hora embutida.");
        }
    }

    // --- 5. Acentuação (charset WIN1252) ---
    Console.WriteLine();
    Console.WriteLine("[5] Acentuação vinda do banco WIN1252:");
    using (var cmd = new FbCommand(
        "SELECT DESCRICAO FROM CONTAS WHERE DESCRICAO LIKE '%REPRESENTA%' ORDER BY CONTA_ID", con))
    using (var r = cmd.ExecuteReader())
        while (r.Read())
            Console.WriteLine($"    [{r.GetString(0).Trim()}]");

    // --- 6. Total conferido contra o número conhecido ---
    Console.WriteLine();
    Console.WriteLine("[6] Total pago acumulado (oráculo de paridade):");
    using (var cmd = new FbCommand(
        "SELECT SUM(CAST(VALOR_PAGO AS NUMERIC(15,2))) FROM REGISTRO_DE_GASTOS", con))
    {
        var total = Convert.ToDecimal(cmd.ExecuteScalar(), CultureInfo.InvariantCulture);
        Console.WriteLine($"    lido ....: {total.ToString("C", ptBR)}");
        Console.WriteLine($"    esperado : {34501459.68m.ToString("C", ptBR)}");
        Console.WriteLine(total == 34501459.68m
            ? "    RESULTADO: bate com o levantado na Fase 2."
            : "    RESULTADO: ATENÇÃO — divergiu do levantamento.");
    }

    // --- 7. Inserção sem informar o ID (a trigger precisa atribuir) ---
    Console.WriteLine();
    Console.WriteLine("[7] Inserção sem informar o ID, em transação revertida ao final:");
    // Busca uma combinação de chaves que realmente exista, em vez de supor.
    int catId, subId, contaId, formaId, userId;
    using (var cmd = new FbCommand(
        "SELECT FIRST 1 S.CATEGORIA_ID, S.SUBCATEGORIA_ID, " +
        "  (SELECT MIN(CONTA_ID) FROM CONTAS), " +
        "  (SELECT MIN(FORMA_DE_PAGAMENTO_ID) FROM FORMA_DE_PAGAMENTO), " +
        "  (SELECT MIN(LOGIN_ID) FROM LOGIN) " +
        "FROM SUBCATEGORIA S", con))
    using (var r = cmd.ExecuteReader())
    {
        r.Read();
        catId = r.GetInt32(0); subId = r.GetInt32(1);
        contaId = r.GetInt32(2); formaId = r.GetInt32(3); userId = r.GetInt32(4);
    }
    Console.WriteLine($"    chaves usadas: categoria={catId} subcategoria={subId} conta={contaId} forma={formaId} usuario={userId}");

    using (var tx = con.BeginTransaction())
    {
        try
        {
            using var cmd = new FbCommand(
                "INSERT INTO REGISTRO_DE_GASTOS " +
                "(CATEGORIA_ID, SUBCATEGORIA_ID, CONTA_ID, FORMA_DE_PAGAMENTO_ID, USERID, " +
                " DESCRICAO, VALOR_PREVISTO, VALOR_PAGO, PAGO, DATA_VENCIMENTO, DATA_CADASTRO) " +
                "VALUES (@cat, @sub, @conta, @forma, @user, @desc, @prev, 0, 0, @venc, @cad) " +
                "RETURNING GASTOS_ID", con, tx);

            cmd.Parameters.AddWithValue("@cat", catId);
            cmd.Parameters.AddWithValue("@sub", subId);
            cmd.Parameters.AddWithValue("@conta", contaId);
            cmd.Parameters.AddWithValue("@forma", formaId);
            cmd.Parameters.AddWithValue("@user", userId);
            cmd.Parameters.AddWithValue("@desc", "SPIKE - REGISTRO DE TESTE");
            cmd.Parameters.AddWithValue("@prev", 1234.56m);
            cmd.Parameters.AddWithValue("@venc", new DateTime(2026, 8, 19));
            cmd.Parameters.AddWithValue("@cad", new DateTime(2026, 8, 19));

            var novoId = cmd.ExecuteScalar();
            Console.WriteLine($"    INSERT aceito. ID atribuído pela trigger: {novoId}");
            Console.WriteLine("    RESULTADO: a API pode inserir sem gerar o ID por conta própria.");
        }
        finally
        {
            tx.Rollback();
            Console.WriteLine("    Transação revertida — nada foi gravado.");
        }
    }

    // --- 8. Confirma que a reversão funcionou ---
    Console.WriteLine();
    using (var cmd = new FbCommand(
        "SELECT COUNT(*) FROM REGISTRO_DE_GASTOS WHERE DESCRICAO = 'SPIKE - REGISTRO DE TESTE'", con))
    {
        var sobrou = Convert.ToInt32(cmd.ExecuteScalar(), CultureInfo.InvariantCulture);
        Console.WriteLine($"[8] Registros de teste remanescentes: {sobrou} (esperado 0)");
    }

    // --- 9. WIN1252 x ISO-8859-1: procurar bytes na faixa divergente ---
    // O provider NÃO aceita WIN1252. ISO8859_1 é idêntico de 0xA0 a 0xFF (os acentos do
    // português), mas diverge de 0x80 a 0x9F, onde o WIN1252 põe travessões, aspas curvas e
    // reticências — caracteres que Word e Excel inserem sozinhos.
    Console.WriteLine();
    Console.WriteLine("[9] Textos que usam a faixa 0x80-0x9F (onde ISO8859_1 diverge de WIN1252):");
    System.Text.Encoding.RegisterProvider(System.Text.CodePagesEncodingProvider.Instance);
    var win1252 = System.Text.Encoding.GetEncoding(1252);

    var colunas = new (string Tabela, string Coluna, int Tamanho)[]
    {
        ("REGISTRO_DE_GASTOS", "DESCRICAO", 200), ("REGISTRO_DE_GASTOS", "OBS", 200),
        ("CONTAS", "DESCRICAO", 50), ("CATEGORIA", "DESCRICAO", 100),
        ("SUBCATEGORIA", "DESCRICAO", 100), ("PROPRIEDADE", "DESCRICAO", 35),
        ("FORNECEDOR", "NOME_FANTASIA", 40), ("FORNECEDOR", "RAZAO_SOCIAL", 40),
    };

    var divergentes = 0;
    foreach (var (tabela, coluna, tamanho) in colunas)
    {
        using var cmd = new FbCommand(
            $"SELECT CAST({coluna} AS VARCHAR({tamanho}) CHARACTER SET OCTETS) " +
            $"FROM {tabela} WHERE {coluna} IS NOT NULL", con);
        using var r = cmd.ExecuteReader();
        while (r.Read())
        {
            if (r.GetValue(0) is not byte[] b) continue;
            if (!b.Any(x => x >= 0x80 && x <= 0x9F)) continue;
            divergentes++;
            if (divergentes <= 2)
                Console.WriteLine($"    {tabela}.{coluna}: [{win1252.GetString(b).Trim().Replace("\n", " / ")}]");
        }
    }

    Console.WriteLine($"    total na faixa divergente: {divergentes}");
    Console.WriteLine(divergentes == 0
        ? "    RESULTADO: ISO8859_1 seria suficiente nesta base."
        : "    RESULTADO: ISO8859_1 corromperia esses textos. Ver ADR 0009.");

    Console.WriteLine();
    Console.WriteLine("=== SPIKE CONCLUÍDO ===");
    return 0;
}
catch (Exception ex)
{
    Console.WriteLine();
    Console.WriteLine($"FALHOU: {ex.GetType().Name}");
    Console.WriteLine(ex.Message);
    return 1;
}
