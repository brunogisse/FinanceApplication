using System.Data;
using Dapper;
using FirebirdSql.Data.FirebirdClient;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>
/// Cadastros de apoio: contas, formas de pagamento, despesas e subdespesas.
///
/// A inserção não informa o identificador — a trigger do banco o atribui a partir do generator,
/// que é atômico. Isso permite que o Delphi e a API insiram ao mesmo tempo sem colidir.
/// </summary>
public sealed class RepositorioCadastros
{
    private readonly ConexaoFirebird _conexao;

    public RepositorioCadastros(ConexaoFirebird conexao) => _conexao = conexao;

    // ---------------- Contas ----------------

    public IReadOnlyList<Conta> ListarContas()
    {
        using var con = _conexao.Abrir();
        return con.Query("SELECT CONTA_ID, DESCRICAO FROM CONTAS ORDER BY DESCRICAO")
                  .Select(l => new Conta { Id = l.CONTA_ID, Descricao = ConexaoFirebird.TextoDoLegado(l.DESCRICAO) ?? "" })
                  .ToList();
    }

    public Conta CriarConta(string descricao)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Conta.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "CONTAS", limpa, "conta");

        var id = con.ExecuteScalar<int>(
            "INSERT INTO CONTAS (DESCRICAO) VALUES (@d) RETURNING CONTA_ID", new { d = limpa });
        return new Conta { Id = id, Descricao = limpa };
    }

    public Conta AlterarConta(int id, string descricao)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Conta.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "CONTAS", limpa, "conta", exceto: ("CONTA_ID", id));

        if (con.Execute("UPDATE CONTAS SET DESCRICAO = @d WHERE CONTA_ID = @id", new { d = limpa, id }) == 0)
            throw new RegraDeNegocioException("Conta não encontrada.");
        return new Conta { Id = id, Descricao = limpa };
    }

    public void ExcluirConta(int id) => Excluir("CONTAS", "CONTA_ID", id, "conta");

    // ---------------- Formas de pagamento ----------------

    public IReadOnlyList<FormaPagamento> ListarFormasPagamento()
    {
        using var con = _conexao.Abrir();
        return con.Query("SELECT FORMA_DE_PAGAMENTO_ID, DESCRICAO FROM FORMA_DE_PAGAMENTO ORDER BY DESCRICAO")
                  .Select(l => new FormaPagamento
                  {
                      Id = l.FORMA_DE_PAGAMENTO_ID,
                      Descricao = ConexaoFirebird.TextoDoLegado(l.DESCRICAO) ?? ""
                  }).ToList();
    }

    public FormaPagamento CriarFormaPagamento(string descricao)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, FormaPagamento.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "FORMA_DE_PAGAMENTO", limpa, "forma de pagamento");

        var id = con.ExecuteScalar<int>(
            "INSERT INTO FORMA_DE_PAGAMENTO (DESCRICAO) VALUES (@d) RETURNING FORMA_DE_PAGAMENTO_ID",
            new { d = limpa });
        return new FormaPagamento { Id = id, Descricao = limpa };
    }

    public FormaPagamento AlterarFormaPagamento(int id, string descricao)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, FormaPagamento.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "FORMA_DE_PAGAMENTO", limpa, "forma de pagamento",
                               exceto: ("FORMA_DE_PAGAMENTO_ID", id));

        if (con.Execute("UPDATE FORMA_DE_PAGAMENTO SET DESCRICAO = @d WHERE FORMA_DE_PAGAMENTO_ID = @id",
                        new { d = limpa, id }) == 0)
            throw new RegraDeNegocioException("Forma de pagamento não encontrada.");
        return new FormaPagamento { Id = id, Descricao = limpa };
    }

    public void ExcluirFormaPagamento(int id) =>
        Excluir("FORMA_DE_PAGAMENTO", "FORMA_DE_PAGAMENTO_ID", id, "forma de pagamento");

    // ---------------- Despesas ----------------

    public IReadOnlyList<Despesa> ListarDespesas()
    {
        using var con = _conexao.Abrir();
        return con.Query("SELECT CATEGORIA_ID, DESCRICAO FROM CATEGORIA ORDER BY DESCRICAO")
                  .Select(l => new Despesa { Id = l.CATEGORIA_ID, Descricao = ConexaoFirebird.TextoDoLegado(l.DESCRICAO) ?? "" })
                  .ToList();
    }

    public Despesa CriarDespesa(string descricao)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Despesa.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "CATEGORIA", limpa, "despesa");

        var id = con.ExecuteScalar<int>(
            "INSERT INTO CATEGORIA (DESCRICAO) VALUES (@d) RETURNING CATEGORIA_ID", new { d = limpa });
        return new Despesa { Id = id, Descricao = limpa };
    }

    public Despesa AlterarDespesa(int id, string descricao)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Despesa.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "CATEGORIA", limpa, "despesa", exceto: ("CATEGORIA_ID", id));

        if (con.Execute("UPDATE CATEGORIA SET DESCRICAO = @d WHERE CATEGORIA_ID = @id",
                        new { d = limpa, id }) == 0)
            throw new RegraDeNegocioException("Despesa não encontrada.");
        return new Despesa { Id = id, Descricao = limpa };
    }

    public void ExcluirDespesa(int id) => Excluir("CATEGORIA", "CATEGORIA_ID", id, "despesa");

    // ---------------- Subdespesas ----------------

    public IReadOnlyList<Subdespesa> ListarSubdespesas(int? despesaId = null)
    {
        var filtro = despesaId is null ? "" : " WHERE S.CATEGORIA_ID = @despesaId";
        var sql = "SELECT S.SUBCATEGORIA_ID, S.DESCRICAO, S.CATEGORIA_ID, S.VALOR_MAXIMO, " +
                  "       C.DESCRICAO AS DESPESA " +
                  "FROM SUBCATEGORIA S JOIN CATEGORIA C ON C.CATEGORIA_ID = S.CATEGORIA_ID" +
                  filtro + " ORDER BY C.DESCRICAO, S.DESCRICAO";

        using var con = _conexao.Abrir();
        return con.Query(sql, new { despesaId }).Select(l => new Subdespesa
        {
            Id = l.SUBCATEGORIA_ID,
            Descricao = ConexaoFirebird.TextoDoLegado(l.DESCRICAO) ?? "",
            DespesaId = l.CATEGORIA_ID,
            Despesa = ConexaoFirebird.TextoDoLegado(l.DESPESA),
            ValorMaximo = l.VALOR_MAXIMO is null ? null : Dinheiro.DeFloatDoLegado((double)l.VALOR_MAXIMO)
        }).ToList();
    }

    /// <summary>
    /// A subdespesa sempre nasce ligada a uma despesa — no legado, à que estiver selecionada na
    /// grade, o que a tela deixa explícito com "[Atribuir para a Despesa: X]".
    /// </summary>
    public Subdespesa CriarSubdespesa(string descricao, int despesaId)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Subdespesa.TamanhoMaximoDescricao);

        using var con = _conexao.Abrir();
        ExigirDespesaExistente(con, despesaId);

        // Duas subdespesas de mesmo nome em despesas diferentes são legítimas: o legado tem
        // "MANUTENÇÃO" em mais de um centro de custo. A checagem é dentro da despesa.
        var repetida = con.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM SUBCATEGORIA WHERE CATEGORIA_ID = @despesaId AND UPPER(DESCRICAO) = @d",
            new { despesaId, d = limpa.ToUpperInvariant() });
        if (repetida > 0)
            throw new RegraDeNegocioException($"Já existe a subdespesa \"{limpa}\" nessa despesa.");

        var id = con.ExecuteScalar<int>(
            "INSERT INTO SUBCATEGORIA (DESCRICAO, CATEGORIA_ID, VALOR_MAXIMO) " +
            "VALUES (@d, @despesaId, 0) RETURNING SUBCATEGORIA_ID",
            new { d = limpa, despesaId });

        return new Subdespesa { Id = id, Descricao = limpa, DespesaId = despesaId };
    }

    public Subdespesa AlterarSubdespesa(int id, string descricao, int despesaId)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Subdespesa.TamanhoMaximoDescricao);

        using var con = _conexao.Abrir();
        ExigirDespesaExistente(con, despesaId);

        var repetida = con.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM SUBCATEGORIA " +
            "WHERE CATEGORIA_ID = @despesaId AND UPPER(DESCRICAO) = @d AND SUBCATEGORIA_ID <> @id",
            new { despesaId, d = limpa.ToUpperInvariant(), id });
        if (repetida > 0)
            throw new RegraDeNegocioException($"Já existe a subdespesa \"{limpa}\" nessa despesa.");

        if (con.Execute("UPDATE SUBCATEGORIA SET DESCRICAO = @d, CATEGORIA_ID = @despesaId " +
                        "WHERE SUBCATEGORIA_ID = @id", new { d = limpa, despesaId, id }) == 0)
            throw new RegraDeNegocioException("Subdespesa não encontrada.");

        return new Subdespesa { Id = id, Descricao = limpa, DespesaId = despesaId };
    }

    public void ExcluirSubdespesa(int id) => Excluir("SUBCATEGORIA", "SUBCATEGORIA_ID", id, "subdespesa");

    // ---------------- Apoio ----------------

    private static void ExigirDespesaExistente(IDbConnection con, int despesaId)
    {
        var existe = con.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM CATEGORIA WHERE CATEGORIA_ID = @id", new { id = despesaId });
        if (existe == 0)
            throw new RegraDeNegocioException("A despesa informada não existe.");
    }

    private static void ExigirDescricaoInedita(IDbConnection con, string tabela, string descricao,
                                               string rotulo, (string Coluna, int Id)? exceto = null)
    {
        var sql = $"SELECT COUNT(*) FROM {tabela} WHERE UPPER(DESCRICAO) = @d";
        if (exceto is not null) sql += $" AND {exceto.Value.Coluna} <> @id";

        var repetida = con.ExecuteScalar<int>(sql,
            new { d = descricao.ToUpperInvariant(), id = exceto?.Id ?? 0 });

        if (repetida > 0)
            throw new RegraDeNegocioException($"Já existe uma {rotulo} chamada \"{descricao}\".");
    }

    /// <summary>
    /// Exclui traduzindo a violação de chave estrangeira em explicação para o operador —
    /// mesma gentileza do legado, que diz "este registro está sendo referenciado em outra
    /// tabela" em vez de mostrar o erro técnico.
    /// </summary>
    private void Excluir(string tabela, string coluna, int id, string rotulo)
    {
        using var con = _conexao.Abrir();
        try
        {
            if (con.Execute($"DELETE FROM {tabela} WHERE {coluna} = @id", new { id }) == 0)
                throw new RegraDeNegocioException(
                    $"{char.ToUpperInvariant(rotulo[0])}{rotulo[1..]} não encontrada.");
        }
        catch (FbException e) when (e.Message.Contains("FOREIGN KEY", StringComparison.OrdinalIgnoreCase)
                                 || e.Message.Contains("still referenced", StringComparison.OrdinalIgnoreCase))
        {
            throw new RegraDeNegocioException(
                $"Não é possível excluir esta {rotulo}: existem lançamentos ou cadastros usando ela. " +
                "Para excluí-la, primeiro remova ou reclassifique o que a referencia.");
        }
    }
}
