using Dapper;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>
/// Os números agregados da tela inicial.
///
/// **Toda soma converte para decimal antes de somar.** `SUM(VALOR_PREVISTO)` direto somaria
/// `FLOAT` de precisão simples, acumulando erro linha a linha — que é o defeito central deste
/// banco, agora multiplicado por treze mil registros. O `CAST(... AS NUMERIC(15,2))` dentro do
/// SUM resolve cada valor para duas casas antes de entrar na conta.
///
/// As consultas são todas por período e sem índice de data no banco (ver a etapa 0 do
/// roadmap), então o painel varre a tabela algumas vezes. Numa base de 13.972 linhas isso é
/// instantâneo; se um dia crescer, o índice deixa de ser opcional.
/// </summary>
public sealed class RepositorioPainel
{
    private readonly ConexaoFirebird _conexao;

    public RepositorioPainel(ConexaoFirebird conexao) => _conexao = conexao;

    /// <summary>Soma dos dois valores, já em decimal, mais a contagem.</summary>
    private const string Colunas = @"
       COUNT(*) AS QUANTIDADE,
       COALESCE(SUM(CAST(REG.VALOR_PREVISTO AS NUMERIC(15,2))), 0) AS PREVISTO,
       COALESCE(SUM(CAST(REG.VALOR_PAGO     AS NUMERIC(15,2))), 0) AS PAGO";

    public Painel Montar(DateOnly mes, DateOnly hoje, Setor setor)
    {
        var primeiroDia = new DateOnly(mes.Year, mes.Month, 1);
        var ultimoDia = primeiroDia.AddMonths(1).AddDays(-1);

        // Uma vez só, no alto: um setor não informado é recusado aqui e não vira painel zerado,
        // que passaria por "mês sem movimento".
        var noSetor = FiltroDeSetor.Numero(setor);
        var recorte = FiltroDeSetor.ECondicao("REG");

        using var con = _conexao.Abrir();

        // ---- Vencido: mesma condição do aviso do legado, inclusive o dia de hoje ----
        var vencido = con.QuerySingle($@"
SELECT {Colunas} FROM REGISTRO_DE_GASTOS REG
WHERE REG.PAGO = 0 AND REG.DATA_VENCIMENTO <= @hoje{recorte}",
            new { hoje = Data(hoje), setor = noSetor });

        // ---- Os sete dias seguintes, sem sobrepor o vencido ----
        var proximos = con.QuerySingle($@"
SELECT {Colunas} FROM REGISTRO_DE_GASTOS REG
WHERE REG.PAGO = 0 AND REG.DATA_VENCIMENTO > @hoje AND REG.DATA_VENCIMENTO <= @limite{recorte}",
            new { hoje = Data(hoje), limite = Data(hoje.AddDays(7)), setor = noSetor });

        // ---- Pago no mês, pela data do pagamento ----
        var pagoNoMes = con.QuerySingle($@"
SELECT {Colunas} FROM REGISTRO_DE_GASTOS REG
WHERE REG.PAGO = 1 AND REG.DATA_PAGAMENTO BETWEEN @inicio AND @fim{recorte}",
            new { inicio = Data(primeiroDia), fim = Data(ultimoDia), setor = noSetor });

        var mesAnterior = primeiroDia.AddMonths(-1);
        var pagoAnterior = con.QuerySingle($@"
SELECT {Colunas} FROM REGISTRO_DE_GASTOS REG
WHERE REG.PAGO = 1 AND REG.DATA_PAGAMENTO BETWEEN @inicio AND @fim{recorte}",
            new
            {
                inicio = Data(mesAnterior),
                fim = Data(mesAnterior.AddMonths(1).AddDays(-1)),
                setor = noSetor
            });

        // ---- Compromisso do mês: tudo que vence nele, pago ou não ----
        var previstoNoMes = con.QuerySingle($@"
SELECT {Colunas} FROM REGISTRO_DE_GASTOS REG
WHERE REG.DATA_VENCIMENTO BETWEEN @inicio AND @fim{recorte}",
            new { inicio = Data(primeiroDia), fim = Data(ultimoDia), setor = noSetor });

        // ---- Para onde o dinheiro foi no mês ----
        var porDespesa = con.Query($@"
SELECT C.DESCRICAO AS DESPESA,
       COUNT(*) AS QUANTIDADE,
       COALESCE(SUM(CAST(REG.VALOR_PAGO AS NUMERIC(15,2))), 0) AS TOTAL
FROM REGISTRO_DE_GASTOS REG
     JOIN CATEGORIA C ON C.CATEGORIA_ID = REG.CATEGORIA_ID
WHERE REG.PAGO = 1 AND REG.DATA_PAGAMENTO BETWEEN @inicio AND @fim{recorte}
GROUP BY C.DESCRICAO
ORDER BY 3 DESC",
            new { inicio = Data(primeiroDia), fim = Data(ultimoDia), setor = noSetor })
            .Select(l => new TotalPorDespesa
            {
                Despesa = ConexaoFirebird.TextoDoLegado(l.DESPESA) ?? "",
                Quantidade = (int)l.QUANTIDADE,
                Total = Dinheiro.De((decimal)l.TOTAL)
            }).ToList();

        // ---- Doze meses terminando no mês escolhido ----
        var inicioSerie = primeiroDia.AddMonths(-11);
        var serie = MontarSerie(con, inicioSerie, ultimoDia, noSetor);

        // ---- Dias com vencimento, para o calendário ----
        var dias = con.Query($@"
SELECT REG.DATA_VENCIMENTO AS DIA,
       COUNT(*) AS QUANTIDADE,
       COALESCE(SUM(CAST(REG.VALOR_PREVISTO AS NUMERIC(15,2))), 0) AS TOTAL,
       SUM(CASE WHEN REG.PAGO = 0 THEN 1 ELSE 0 END) AS APAGAR
FROM REGISTRO_DE_GASTOS REG
WHERE REG.DATA_VENCIMENTO BETWEEN @inicio AND @fim{recorte}
GROUP BY REG.DATA_VENCIMENTO
ORDER BY 1",
            new { inicio = Data(primeiroDia), fim = Data(ultimoDia), setor = noSetor })
            .Select(l => new DiaDoMes
            {
                Data = DateOnly.FromDateTime((DateTime)l.DIA),
                Quantidade = (int)l.QUANTIDADE,
                Total = Dinheiro.De((decimal)l.TOTAL),
                APagar = (int)l.APAGAR
            }).ToList();

        return new Painel
        {
            Mes = primeiroDia,
            Vencido = ComPrevisto(vencido),
            VenceEmSeteDias = ComPrevisto(proximos),
            PagoNoMes = ComPago(pagoNoMes),
            PagoNoMesAnterior = ComPago(pagoAnterior),
            PrevistoNoMes = ComPrevisto(previstoNoMes),
            PorDespesa = porDespesa,
            Serie = serie,
            Dias = dias
        };
    }

    /// <summary>
    /// Previsto por vencimento e pago por pagamento, mês a mês.
    ///
    /// São duas consultas porque as duas grandezas vivem em colunas de data diferentes — a
    /// mesma regra que separa "quanto devo" de "quanto gastei" no consolidado. Juntar as duas
    /// num único GROUP BY daria um número que não é nem um nem outro.
    /// </summary>
    private static IReadOnlyList<MesDaSerie> MontarSerie(
        System.Data.IDbConnection con, DateOnly inicio, DateOnly fim, int noSetor)
    {
        var sql = @"
SELECT EXTRACT(YEAR FROM {0}) AS ANO, EXTRACT(MONTH FROM {0}) AS MES,
       COALESCE(SUM(CAST({1} AS NUMERIC(15,2))), 0) AS TOTAL
FROM REGISTRO_DE_GASTOS REG
WHERE {0} BETWEEN @inicio AND @fim {2}" + FiltroDeSetor.ECondicao("REG") + @"
GROUP BY 1, 2";

        var parametros = new
        {
            inicio = inicio.ToDateTime(TimeOnly.MinValue),
            fim = fim.ToDateTime(TimeOnly.MinValue),
            setor = noSetor
        };

        var previsto = Indexar(con.Query(
            string.Format(sql, "REG.DATA_VENCIMENTO", "REG.VALOR_PREVISTO", ""), parametros));

        var pago = Indexar(con.Query(
            string.Format(sql, "REG.DATA_PAGAMENTO", "REG.VALOR_PAGO", "AND REG.PAGO = 1"),
            parametros));

        // Meses sem movimento aparecem zerados: buraco no meio de uma série engana os olhos.
        var meses = new List<MesDaSerie>();
        for (var m = new DateOnly(inicio.Year, inicio.Month, 1); m <= fim; m = m.AddMonths(1))
        {
            var chave = (m.Year, m.Month);
            meses.Add(new MesDaSerie
            {
                Mes = m,
                Previsto = Dinheiro.De(previsto.GetValueOrDefault(chave)),
                Pago = Dinheiro.De(pago.GetValueOrDefault(chave))
            });
        }

        return meses;
    }

    private static Dictionary<(int, int), decimal> Indexar(IEnumerable<dynamic> linhas) =>
        linhas.ToDictionary(l => ((int)l.ANO, (int)l.MES), l => (decimal)l.TOTAL);

    private static Montante ComPrevisto(dynamic l) => new()
    {
        Quantidade = (int)l.QUANTIDADE,
        Total = Dinheiro.De((decimal)l.PREVISTO)
    };

    private static Montante ComPago(dynamic l) => new()
    {
        Quantidade = (int)l.QUANTIDADE,
        Total = Dinheiro.De((decimal)l.PAGO)
    };

    private static DateTime Data(DateOnly d) => d.ToDateTime(TimeOnly.MinValue);
}
