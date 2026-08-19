using System.Data;
using Dapper;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>
/// Gravação de lançamentos.
///
/// Cada operação é **uma transação**. No legado, `UpdateOptions.AutoCommitUpdates = True` faz
/// cada Post confirmar sozinho, e por isso o parcelamento não é atômico — ver docs/fluxos.md.
/// </summary>
public sealed partial class RepositorioLancamentos
{
    /// <summary>Um lançamento pelo identificador, ou nulo se não existir.</summary>
    public Lancamento? PorId(int id)
    {
        using var con = _conexao.Abrir();
        var linha = con.QuerySingleOrDefault<LinhaLancamento>(
            $"{Selecao} WHERE REG.GASTOS_ID = @id", new { id });
        return linha is null ? null : Converter(linha);
    }

    /// <summary>
    /// Cria um lançamento.
    ///
    /// A despesa não é informada: vem da subdespesa escolhida, como no legado, onde escolher a
    /// subdespesa preenche os dois campos juntos. A autoria e a data de cadastro são carimbadas
    /// aqui, não pelo chamador, para que nenhum caminho de gravação possa esquecer.
    /// </summary>
    public Lancamento Criar(DadosLancamento dados, Usuario autor, DateOnly? hoje = null)
    {
        var referencia = hoje ?? DateOnly.FromDateTime(DateTime.Today);
        var validos = dados.Validar(referencia);

        using var con = _conexao.Abrir();
        using var tx = con.BeginTransaction();
        try
        {
            var despesaId = DespesaDaSubdespesa(con, tx, validos.SubdespesaId);
            ExigirExistencia(con, tx, "CONTAS", "CONTA_ID", validos.ContaId, "conta");
            ExigirExistencia(con, tx, "FORMA_DE_PAGAMENTO", "FORMA_DE_PAGAMENTO_ID",
                             validos.FormaPagamentoId, "forma de pagamento");

            // O identificador não é informado: a trigger o atribui a partir do generator, que
            // é atômico e permite Delphi e API inserindo ao mesmo tempo sem colidir.
            var id = con.ExecuteScalar<int>(@"
INSERT INTO REGISTRO_DE_GASTOS
    (CATEGORIA_ID, SUBCATEGORIA_ID, CONTA_ID, FORMA_DE_PAGAMENTO_ID, USERID,
     DESCRICAO, VALOR_PREVISTO, VALOR_PAGO, PAGO,
     DATA_VENCIMENTO, DATA_PAGAMENTO, DATA_CADASTRO,
     NOTA_FISCAL, CHEQUE, CHEQUE_COMPENSADO, SITUACAO_STATUS, OBS)
VALUES
    (@despesaId, @subdespesaId, @contaId, @formaId, @usuarioId,
     @descricao, @valorPrevisto, @valorPago, @pago,
     @dataVencimento, @dataPagamento, @dataCadastro,
     @notaFiscal, @cheque, @chequeCompensado, @situacao, @obs)
RETURNING GASTOS_ID",
                Parametros(validos, despesaId, autor.Id, referencia), tx);

            tx.Commit();
            return PorId(id)!;
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }

    /// <summary>
    /// Altera um lançamento existente.
    ///
    /// Só o autor pode alterar, com o usuário 1 podendo tudo. **No legado essa verificação
    /// está comentada no botão Alterar** e vale apenas no Excluir — divergência intencional,
    /// declarada em docs/arquitetura-alvo.md.
    ///
    /// A data de cadastro e a autoria originais são preservadas: alterar não muda quem lançou.
    /// </summary>
    public Lancamento Alterar(int id, DadosLancamento dados, Usuario quem, DateOnly? hoje = null)
    {
        var referencia = hoje ?? DateOnly.FromDateTime(DateTime.Today);
        var validos = dados.Validar(referencia);

        var atual = PorId(id) ?? throw new RegraDeNegocioException("Lançamento não encontrado.");
        ExigirPermissao(quem, atual);

        using var con = _conexao.Abrir();
        using var tx = con.BeginTransaction();
        try
        {
            var despesaId = DespesaDaSubdespesa(con, tx, validos.SubdespesaId);
            ExigirExistencia(con, tx, "CONTAS", "CONTA_ID", validos.ContaId, "conta");
            ExigirExistencia(con, tx, "FORMA_DE_PAGAMENTO", "FORMA_DE_PAGAMENTO_ID",
                             validos.FormaPagamentoId, "forma de pagamento");

            var p = Parametros(validos, despesaId, atual.UsuarioId, referencia);
            p.Add("id", id);

            con.Execute(@"
UPDATE REGISTRO_DE_GASTOS SET
    CATEGORIA_ID = @despesaId, SUBCATEGORIA_ID = @subdespesaId,
    CONTA_ID = @contaId, FORMA_DE_PAGAMENTO_ID = @formaId,
    DESCRICAO = @descricao, VALOR_PREVISTO = @valorPrevisto, VALOR_PAGO = @valorPago,
    PAGO = @pago, DATA_VENCIMENTO = @dataVencimento, DATA_PAGAMENTO = @dataPagamento,
    NOTA_FISCAL = @notaFiscal, CHEQUE = @cheque, CHEQUE_COMPENSADO = @chequeCompensado,
    SITUACAO_STATUS = @situacao, OBS = @obs
WHERE GASTOS_ID = @id", p, tx);

            tx.Commit();
            return PorId(id)!;
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }

    /// <summary>Exclui um lançamento, respeitando a mesma regra de autoria.</summary>
    public void Excluir(int id, Usuario quem)
    {
        var atual = PorId(id) ?? throw new RegraDeNegocioException("Lançamento não encontrado.");
        ExigirPermissao(quem, atual);

        using var con = _conexao.Abrir();
        using var tx = con.BeginTransaction();
        try
        {
            con.Execute("DELETE FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = @id", new { id }, tx);
            tx.Commit();
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }

    /// <summary>Marca a situação de liberação, como o botão de status do legado.</summary>
    public Lancamento DefinirSituacao(int id, SituacaoStatus situacao, Usuario quem)
    {
        var atual = PorId(id) ?? throw new RegraDeNegocioException("Lançamento não encontrado.");
        ExigirPermissao(quem, atual);

        using var con = _conexao.Abrir();
        con.Execute("UPDATE REGISTRO_DE_GASTOS SET SITUACAO_STATUS = @s WHERE GASTOS_ID = @id",
                    new { s = TextoDaSituacao(situacao), id });
        return PorId(id)!;
    }

    // ---------------- Apoio ----------------

    private static void ExigirPermissao(Usuario quem, Lancamento lancamento)
    {
        if (quem.PodeModificarLancamentoDe(lancamento.UsuarioId)) return;

        throw new RegraDeNegocioException(
            "Não há permissão para alterar este lançamento. " +
            "Apenas quem o cadastrou pode alterá-lo ou excluí-lo.");
    }

    private static int DespesaDaSubdespesa(IDbConnection con, IDbTransaction tx, int subdespesaId)
    {
        var despesaId = con.ExecuteScalar<int?>(
            "SELECT CATEGORIA_ID FROM SUBCATEGORIA WHERE SUBCATEGORIA_ID = @id",
            new { id = subdespesaId }, tx);

        return despesaId ?? throw new RegraDeNegocioException("A subdespesa informada não existe.");
    }

    private static void ExigirExistencia(IDbConnection con, IDbTransaction tx,
                                         string tabela, string coluna, int id, string rotulo)
    {
        var existe = con.ExecuteScalar<int>(
            $"SELECT COUNT(*) FROM {tabela} WHERE {coluna} = @id", new { id }, tx);
        if (existe == 0)
            throw new RegraDeNegocioException($"A {rotulo} informada não existe.");
    }

    private static string? TextoDaSituacao(SituacaoStatus s) => s switch
    {
        SituacaoStatus.Aguardando => "AGUARDANDO",
        SituacaoStatus.Liberada => "LIBERADA",
        _ => null
    };

    private static DynamicParameters Parametros(DadosLancamento d, int despesaId,
                                                int usuarioId, DateOnly hoje)
    {
        var p = new DynamicParameters();
        p.Add("despesaId", despesaId);
        p.Add("subdespesaId", d.SubdespesaId);
        p.Add("contaId", d.ContaId);
        p.Add("formaId", d.FormaPagamentoId);
        p.Add("usuarioId", usuarioId);
        p.Add("descricao", ConexaoFirebird.NormalizarParaGravar(d.Descricao));

        // As colunas de valor são FLOAT no legado. Grava-se o decimal já arredondado, que é o
        // melhor que a coluna comporta — ver ADR 0006.
        p.Add("valorPrevisto", (double)d.ValorPrevisto.Valor);
        p.Add("valorPago", (double)(d.ValorPago ?? Dinheiro.Zero).Valor);

        p.Add("pago", d.Pago ? 1 : 0);
        p.Add("dataVencimento", d.DataVencimento.ToDateTime(TimeOnly.MinValue));
        p.Add("dataPagamento", d.DataPagamento?.ToDateTime(TimeOnly.MinValue));
        p.Add("dataCadastro", hoje.ToDateTime(TimeOnly.MinValue));
        p.Add("notaFiscal", d.NotaFiscal ?? 0);
        p.Add("cheque", d.Cheque ?? 0);
        // O legado grava 'N' quando o campo fica vazio.
        p.Add("chequeCompensado", d.ChequeCompensado ? "S" : "N");
        p.Add("situacao", TextoDaSituacao(d.Situacao));
        p.Add("obs", ConexaoFirebird.NormalizarParaGravar(d.Observacao));
        return p;
    }
}
