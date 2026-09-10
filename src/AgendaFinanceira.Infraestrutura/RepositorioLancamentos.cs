using System.Data;
using Dapper;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>
/// Leitura de lançamentos do banco legado.
///
/// A junção é a mesma que o Delphi repete oito vezes no código. As colunas de texto livre são
/// lidas como OCTETS e decodificadas com a página 1252; os valores monetários vêm de colunas
/// FLOAT e são convertidos na borda.
///
/// Todo filtro entra por parâmetro. O legado monta SQL por concatenação de string.
///
/// **Toda consulta daqui recebe o setor de fora, e nenhuma o adivinha.** O recorte é do
/// servidor, nunca da tela — ver ADR 0011 e docs/unificacao-das-bases.md. Só a tabela de
/// lançamentos é filtrada: os cadastros entram por junção de identificador e já são do mesmo
/// setor, e filtrá-los de novo só criaria a chance de derrubar linha por cadastro órfão.
/// </summary>
public sealed partial class RepositorioLancamentos
{
    private readonly ConexaoFirebird _conexao;

    public RepositorioLancamentos(ConexaoFirebird conexao) => _conexao = conexao;

    private const string Selecao = @"
SELECT
    REG.GASTOS_ID                                              AS Id,
    CAST(REG.DESCRICAO AS VARCHAR(200) CHARACTER SET OCTETS)   AS DescricaoBytes,
    CAST(REG.OBS       AS VARCHAR(200) CHARACTER SET OCTETS)   AS ObsBytes,
    REG.CATEGORIA_ID          AS DespesaId,          C.DESCRICAO  AS Despesa,
    REG.SUBCATEGORIA_ID       AS SubdespesaId,       S.DESCRICAO  AS Subdespesa,
    REG.CONTA_ID              AS ContaId,            CT.DESCRICAO AS Conta,
    REG.FORMA_DE_PAGAMENTO_ID AS FormaPagamentoId,   FP.DESCRICAO AS FormaPagamento,
    REG.VALOR_PREVISTO    AS ValorPrevisto,
    REG.VALOR_PAGO        AS ValorPago,
    REG.PAGO              AS Pago,
    REG.DATA_VENCIMENTO   AS DataVencimento,
    REG.DATA_PAGAMENTO    AS DataPagamento,
    REG.DATA_CADASTRO     AS DataCadastro,
    REG.NOTA_FISCAL       AS NotaFiscal,
    REG.CHEQUE            AS Cheque,
    REG.CHEQUE_COMPENSADO AS ChequeCompensado,
    REG.SITUACAO_STATUS   AS Situacao,
    REG.USERID            AS UsuarioId,
    REG.ENTRADA_ID        AS EntradaId
FROM REGISTRO_DE_GASTOS REG
     JOIN CATEGORIA          C  ON C.CATEGORIA_ID          = REG.CATEGORIA_ID
     JOIN SUBCATEGORIA       S  ON S.SUBCATEGORIA_ID       = REG.SUBCATEGORIA_ID
     JOIN CONTAS             CT ON CT.CONTA_ID             = REG.CONTA_ID
     JOIN FORMA_DE_PAGAMENTO FP ON FP.FORMA_DE_PAGAMENTO_ID = REG.FORMA_DE_PAGAMENTO_ID";

    /// <summary>Consulta com os filtros das duas abas do legado, dentro de um setor.</summary>
    public ResultadoConsulta Consultar(ConsultaLancamentos criterio, Setor setor)
    {
        var (where, parametros) = MontarFiltro(criterio, setor);
        var sql = $"{Selecao} WHERE {where} ORDER BY REG.DATA_VENCIMENTO, REG.GASTOS_ID";

        using var con = _conexao.Abrir();
        var linhas = con.Query<LinhaLancamento>(sql, parametros).Select(Converter).ToList();
        return ResultadoConsulta.De(linhas);
    }

    /// <summary>
    /// O que está vencido ou vence hoje e ainda não foi pago — o aviso da tela principal.
    /// Reproduz "DATA_VENCIMENTO &lt;= :hoje AND PAGO = 0".
    /// </summary>
    public ResultadoConsulta Vencimentos(DateOnly hoje, Setor setor)
    {
        var sql = $"{Selecao} WHERE REG.DATA_VENCIMENTO <= @hoje AND REG.PAGO = 0" +
                  FiltroDeSetor.ECondicao("REG") +
                  " ORDER BY REG.DATA_VENCIMENTO, REG.GASTOS_ID";

        using var con = _conexao.Abrir();
        var linhas = con.Query<LinhaLancamento>(sql, new
                        {
                            hoje = hoje.ToDateTime(TimeOnly.MinValue),
                            setor = FiltroDeSetor.Numero(setor)
                        })
                        .Select(Converter).ToList();
        return ResultadoConsulta.De(linhas);
    }

    /// <summary>
    /// Consolidado de uma despesa, agrupado por subdespesa.
    ///
    /// A troca da coluna de data entre os modos é a regra central deste relatório:
    /// pago filtra por DATA_PAGAMENTO, não pago filtra por DATA_VENCIMENTO.
    ///
    /// <paramref name="conta"/> é opcional e recorta o consolidado a uma conta só —
    /// "quanto saiu desta conta, nesta despesa". Sem ela, o resultado é o de sempre.
    /// </summary>
    public IReadOnlyList<TotalPorSubdespesa> ConsolidarPorDespesa(
        string despesa, Periodo periodo, bool apenasPagos, Setor setor, string? conta = null)
    {
        var coluna = apenasPagos ? "REG.DATA_PAGAMENTO" : "REG.DATA_VENCIMENTO";
        var condicaoPago = apenasPagos ? "REG.PAGO = 1" : "REG.PAGO = 0";

        // O JOIN em CONTAS só entra quando há conta a filtrar. Deixá-lo fixo mudaria o
        // resultado de quem não filtra: um lançamento com CONTA_ID órfão sairia da soma
        // sem ninguém pedir.
        var filtrarConta = !string.IsNullOrWhiteSpace(conta);
        var juncaoConta = filtrarConta
            ? "\n     JOIN CONTAS CT ON CT.CONTA_ID = REG.CONTA_ID"
            : "";
        var condicaoConta = filtrarConta ? "\n  AND CT.DESCRICAO = @conta" : "";

        var sql = $@"
SELECT S.SUBCATEGORIA_ID AS SubdespesaId, S.DESCRICAO AS Subdespesa, C.DESCRICAO AS Despesa,
       COUNT(*) AS Quantidade,
       SUM(CAST(REG.VALOR_PREVISTO AS NUMERIC(15,2))) AS TotalPrevisto,
       SUM(CAST(REG.VALOR_PAGO     AS NUMERIC(15,2))) AS TotalPago
FROM REGISTRO_DE_GASTOS REG
     JOIN CATEGORIA    C ON C.CATEGORIA_ID    = REG.CATEGORIA_ID
     JOIN SUBCATEGORIA S ON S.SUBCATEGORIA_ID = REG.SUBCATEGORIA_ID{juncaoConta}
WHERE C.DESCRICAO = @despesa
  AND {coluna} BETWEEN @inicio AND @fim
  AND {condicaoPago}{condicaoConta}
  AND {FiltroDeSetor.Condicao("REG")}
GROUP BY S.SUBCATEGORIA_ID, S.DESCRICAO, C.DESCRICAO
ORDER BY S.DESCRICAO";

        using var con = _conexao.Abrir();
        return con.Query(sql, new
        {
            despesa,
            conta = conta?.Trim(),
            inicio = periodo.Inicio.ToDateTime(TimeOnly.MinValue),
            fim = periodo.Fim.ToDateTime(TimeOnly.MinValue),
            setor = FiltroDeSetor.Numero(setor)
        }).Select(l => new TotalPorSubdespesa
        {
            SubdespesaId = (int)l.SUBDESPESAID,
            Subdespesa = ConexaoFirebird.TextoDoLegado(l.SUBDESPESA) ?? "",
            Despesa = ConexaoFirebird.TextoDoLegado(l.DESPESA) ?? "",
            Quantidade = (int)l.QUANTIDADE,
            TotalPrevisto = Dinheiro.De(l.TOTALPREVISTO ?? 0m),
            TotalPago = Dinheiro.De(l.TOTALPAGO ?? 0m)
        }).ToList();
    }

    private static (string Where, DynamicParameters Parametros) MontarFiltro(
        ConsultaLancamentos c, Setor setor)
    {
        var p = new DynamicParameters();
        var condicoes = new List<string>();

        // O setor entra primeiro, antes de qualquer filtro da tela, e não depende de nenhum
        // deles. Uma consulta sem período, sem descrição e sem nada continua recortada.
        condicoes.Add(FiltroDeSetor.Condicao("REG"));
        FiltroDeSetor.Adicionar(p, setor);

        var coluna = c.FiltrarPorData switch
        {
            ColunaDeData.Pagamento => "REG.DATA_PAGAMENTO",
            ColunaDeData.Cadastro => "REG.DATA_CADASTRO",
            _ => "REG.DATA_VENCIMENTO"
        };
        condicoes.Add($"{coluna} BETWEEN @inicio AND @fim");
        p.Add("inicio", c.Periodo.Inicio.ToDateTime(TimeOnly.MinValue));
        p.Add("fim", c.Periodo.Fim.ToDateTime(TimeOnly.MinValue));

        if (c.Pagamento != FiltroPagamento.Todos)
        {
            condicoes.Add("REG.PAGO = @pago");
            p.Add("pago", c.Pagamento == FiltroPagamento.Pagos ? 1 : 0);
        }

        if (!string.IsNullOrWhiteSpace(c.Descricao))
        {
            condicoes.Add("UPPER(REG.DESCRICAO) LIKE @descricao");
            p.Add("descricao", $"%{c.Descricao.ToUpperInvariant()}%");
        }

        if (!string.IsNullOrWhiteSpace(c.Subdespesa))
        {
            condicoes.Add("S.DESCRICAO = @subdespesa");
            p.Add("subdespesa", c.Subdespesa);
        }

        if (!string.IsNullOrWhiteSpace(c.Despesa))
        {
            condicoes.Add("C.DESCRICAO = @despesa");
            p.Add("despesa", c.Despesa);
        }

        if (!string.IsNullOrWhiteSpace(c.Conta))
        {
            condicoes.Add("CT.DESCRICAO = @conta");
            p.Add("conta", c.Conta);
        }

        if (c.NotaFiscal is not null)
        {
            condicoes.Add("REG.NOTA_FISCAL = @nf");
            p.Add("nf", c.NotaFiscal);
        }

        if (c.Cheque is not null)
        {
            condicoes.Add("REG.CHEQUE = @cheque");
            p.Add("cheque", c.Cheque);
        }

        if (c.ChequeCompensado is not null)
        {
            // UPPER resolve os 9 registros gravados com 's' minúsculo, que a busca do
            // legado nunca encontra por ser sensível a caixa.
            condicoes.Add(c.ChequeCompensado.Value
                ? "UPPER(REG.CHEQUE_COMPENSADO) = 'S'"
                : "(REG.CHEQUE_COMPENSADO IS NULL OR UPPER(REG.CHEQUE_COMPENSADO) <> 'S')");
        }

        if (c.Situacao is not null)
        {
            if (c.Situacao == SituacaoStatus.Nenhuma)
                condicoes.Add("REG.SITUACAO_STATUS IS NULL");
            else
            {
                condicoes.Add("REG.SITUACAO_STATUS = @situacao");
                p.Add("situacao", c.Situacao == SituacaoStatus.Aguardando ? "AGUARDANDO" : "LIBERADA");
            }
        }

        if (c.ValorMinimo is not null || c.ValorMaximo is not null)
        {
            var colunaValor = c.FaixaSobreValorPago ? "REG.VALOR_PAGO" : "REG.VALOR_PREVISTO";
            if (c.ValorMinimo is not null)
            {
                condicoes.Add($"{colunaValor} >= @valorMin");
                p.Add("valorMin", c.ValorMinimo.Value.Valor);
            }
            if (c.ValorMaximo is not null)
            {
                condicoes.Add($"{colunaValor} <= @valorMax");
                p.Add("valorMax", c.ValorMaximo.Value.Valor);
            }
        }

        return (string.Join(" AND ", condicoes), p);
    }

    private static Lancamento Converter(LinhaLancamento l) => new()
    {
        Id = l.Id,
        Descricao = ConexaoFirebird.TextoDoLegado(l.DescricaoBytes) ?? "",
        DespesaId = l.DespesaId,
        Despesa = ConexaoFirebird.TextoDoLegado(l.Despesa) ?? "",
        SubdespesaId = l.SubdespesaId,
        Subdespesa = ConexaoFirebird.TextoDoLegado(l.Subdespesa) ?? "",
        ContaId = l.ContaId,
        Conta = ConexaoFirebird.TextoDoLegado(l.Conta) ?? "",
        FormaPagamentoId = l.FormaPagamentoId,
        FormaPagamento = ConexaoFirebird.TextoDoLegado(l.FormaPagamento) ?? "",
        ValorPrevisto = Dinheiro.DeFloatDoLegado(l.ValorPrevisto ?? 0d),
        ValorPago = Dinheiro.DeFloatDoLegado(l.ValorPago ?? 0d),
        Pago = l.Pago == 1,
        DataVencimento = ConexaoFirebird.DataDoLegado(l.DataVencimento),
        DataPagamento = ConexaoFirebird.DataDoLegado(l.DataPagamento),
        DataCadastro = ConexaoFirebird.DataDoLegado(l.DataCadastro),
        NotaFiscal = l.NotaFiscal == 0 ? null : l.NotaFiscal,
        Cheque = l.Cheque == 0 ? null : l.Cheque,
        ChequeCompensado = string.Equals(l.ChequeCompensado?.Trim(), "S", StringComparison.OrdinalIgnoreCase),
        Situacao = l.Situacao?.Trim().ToUpperInvariant() switch
        {
            "AGUARDANDO" => SituacaoStatus.Aguardando,
            "LIBERADA" => SituacaoStatus.Liberada,
            _ => SituacaoStatus.Nenhuma
        },
        Observacao = ConexaoFirebird.TextoDoLegado(l.ObsBytes),
        UsuarioId = l.UsuarioId,
        EntradaId = l.EntradaId == 0 ? null : l.EntradaId
    };

    /// <summary>Espelho cru de uma linha do banco, antes da conversão para o domínio.</summary>
    private sealed class LinhaLancamento
    {
        public int Id { get; set; }
        public byte[]? DescricaoBytes { get; set; }
        public byte[]? ObsBytes { get; set; }
        public int DespesaId { get; set; }
        public string? Despesa { get; set; }
        public int SubdespesaId { get; set; }
        public string? Subdespesa { get; set; }
        public int ContaId { get; set; }
        public string? Conta { get; set; }
        public int FormaPagamentoId { get; set; }
        public string? FormaPagamento { get; set; }
        public double? ValorPrevisto { get; set; }
        public double? ValorPago { get; set; }
        public int Pago { get; set; }
        public DateTime? DataVencimento { get; set; }
        public DateTime? DataPagamento { get; set; }
        public DateTime? DataCadastro { get; set; }
        public int? NotaFiscal { get; set; }
        public int? Cheque { get; set; }
        public string? ChequeCompensado { get; set; }
        public string? Situacao { get; set; }
        public int UsuarioId { get; set; }
        public int? EntradaId { get; set; }
    }
}
