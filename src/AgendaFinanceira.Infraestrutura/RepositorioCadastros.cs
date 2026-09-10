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
///
/// **Os cadastros também têm setor, e não só os lançamentos.** Casar "CHACARA 2" de uma base
/// com "CHACARA 2" da outra seria assumir que são a mesma propriedade — e a regra da unificação
/// foi não assumir nada. Cada operadora vê a lista dela, sem nome repetido no seletor.
///
/// A consequência prática está na checagem de nome repetido: ela vale **dentro do setor**. As
/// duas listas podem ter uma conta com o mesmo nome, e recusar por causa da outra seria recusar
/// por um registro que quem cadastra não enxerga — nada explicaria a mensagem na tela.
/// </summary>
public sealed class RepositorioCadastros
{
    private readonly ConexaoFirebird _conexao;

    public RepositorioCadastros(ConexaoFirebird conexao) => _conexao = conexao;

    // ---------------- Contas ----------------

    public IReadOnlyList<Conta> ListarContas(Setor setor)
    {
        using var con = _conexao.Abrir();
        return con.Query("SELECT CONTA_ID, DESCRICAO FROM CONTAS WHERE " +
                         FiltroDeSetor.Condicao() + " ORDER BY DESCRICAO",
                         Apenas(setor))
                  .Select(l => new Conta { Id = l.CONTA_ID, Descricao = ConexaoFirebird.TextoDoLegado(l.DESCRICAO) ?? "" })
                  .ToList();
    }

    public Conta CriarConta(string descricao, Setor setor)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Conta.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "CONTAS", limpa, "conta", setor);

        var id = con.ExecuteScalar<int>(
            "INSERT INTO CONTAS (DESCRICAO, SETOR_ID) VALUES (@d, @setor) RETURNING CONTA_ID",
            new { d = limpa, setor = FiltroDeSetor.Numero(setor) });
        return new Conta { Id = id, Descricao = limpa };
    }

    public Conta AlterarConta(int id, string descricao, Setor setor)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Conta.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "CONTAS", limpa, "conta", setor, exceto: ("CONTA_ID", id));

        if (con.Execute("UPDATE CONTAS SET DESCRICAO = @d WHERE CONTA_ID = @id"
                            + FiltroDeSetor.ECondicao(),
                        new { d = limpa, id, setor = FiltroDeSetor.Numero(setor) }) == 0)
            throw new RegraDeNegocioException("Conta não encontrada.");
        return new Conta { Id = id, Descricao = limpa };
    }

    public void ExcluirConta(int id, Setor setor) =>
        Excluir("CONTAS", "CONTA_ID", id, "conta", setor);

    // ---------------- Formas de pagamento ----------------

    public IReadOnlyList<FormaPagamento> ListarFormasPagamento(Setor setor)
    {
        using var con = _conexao.Abrir();
        return con.Query("SELECT FORMA_DE_PAGAMENTO_ID, DESCRICAO FROM FORMA_DE_PAGAMENTO " +
                         "WHERE " + FiltroDeSetor.Condicao() + " ORDER BY DESCRICAO",
                         Apenas(setor))
                  .Select(l => new FormaPagamento
                  {
                      Id = l.FORMA_DE_PAGAMENTO_ID,
                      Descricao = ConexaoFirebird.TextoDoLegado(l.DESCRICAO) ?? ""
                  }).ToList();
    }

    public FormaPagamento CriarFormaPagamento(string descricao, Setor setor)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, FormaPagamento.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "FORMA_DE_PAGAMENTO", limpa, "forma de pagamento", setor);

        var id = con.ExecuteScalar<int>(
            "INSERT INTO FORMA_DE_PAGAMENTO (DESCRICAO, SETOR_ID) VALUES (@d, @setor) " +
            "RETURNING FORMA_DE_PAGAMENTO_ID",
            new { d = limpa, setor = FiltroDeSetor.Numero(setor) });
        return new FormaPagamento { Id = id, Descricao = limpa };
    }

    public FormaPagamento AlterarFormaPagamento(int id, string descricao, Setor setor)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, FormaPagamento.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "FORMA_DE_PAGAMENTO", limpa, "forma de pagamento", setor,
                               exceto: ("FORMA_DE_PAGAMENTO_ID", id));

        if (con.Execute("UPDATE FORMA_DE_PAGAMENTO SET DESCRICAO = @d " +
                        "WHERE FORMA_DE_PAGAMENTO_ID = @id" + FiltroDeSetor.ECondicao(),
                        new { d = limpa, id, setor = FiltroDeSetor.Numero(setor) }) == 0)
            throw new RegraDeNegocioException("Forma de pagamento não encontrada.");
        return new FormaPagamento { Id = id, Descricao = limpa };
    }

    public void ExcluirFormaPagamento(int id, Setor setor) =>
        Excluir("FORMA_DE_PAGAMENTO", "FORMA_DE_PAGAMENTO_ID", id, "forma de pagamento", setor);

    // ---------------- Despesas ----------------

    public IReadOnlyList<Despesa> ListarDespesas(Setor setor)
    {
        using var con = _conexao.Abrir();
        return con.Query("SELECT CATEGORIA_ID, DESCRICAO FROM CATEGORIA WHERE " +
                         FiltroDeSetor.Condicao() + " ORDER BY DESCRICAO",
                         Apenas(setor))
                  .Select(l => new Despesa { Id = l.CATEGORIA_ID, Descricao = ConexaoFirebird.TextoDoLegado(l.DESCRICAO) ?? "" })
                  .ToList();
    }

    public Despesa CriarDespesa(string descricao, Setor setor)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Despesa.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "CATEGORIA", limpa, "despesa", setor);

        var id = con.ExecuteScalar<int>(
            "INSERT INTO CATEGORIA (DESCRICAO, SETOR_ID) VALUES (@d, @setor) RETURNING CATEGORIA_ID",
            new { d = limpa, setor = FiltroDeSetor.Numero(setor) });
        return new Despesa { Id = id, Descricao = limpa };
    }

    public Despesa AlterarDespesa(int id, string descricao, Setor setor)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Despesa.TamanhoMaximoDescricao);
        using var con = _conexao.Abrir();
        ExigirDescricaoInedita(con, "CATEGORIA", limpa, "despesa", setor, exceto: ("CATEGORIA_ID", id));

        if (con.Execute("UPDATE CATEGORIA SET DESCRICAO = @d WHERE CATEGORIA_ID = @id"
                            + FiltroDeSetor.ECondicao(),
                        new { d = limpa, id, setor = FiltroDeSetor.Numero(setor) }) == 0)
            throw new RegraDeNegocioException("Despesa não encontrada.");
        return new Despesa { Id = id, Descricao = limpa };
    }

    public void ExcluirDespesa(int id, Setor setor) =>
        Excluir("CATEGORIA", "CATEGORIA_ID", id, "despesa", setor);

    // ---------------- Subdespesas ----------------

    public IReadOnlyList<Subdespesa> ListarSubdespesas(Setor setor, int? despesaId = null)
    {
        var filtro = despesaId is null ? "" : " AND S.CATEGORIA_ID = @despesaId";
        var sql = "SELECT S.SUBCATEGORIA_ID, S.DESCRICAO, S.CATEGORIA_ID, S.VALOR_MAXIMO, " +
                  "       C.DESCRICAO AS DESPESA " +
                  "FROM SUBCATEGORIA S JOIN CATEGORIA C ON C.CATEGORIA_ID = S.CATEGORIA_ID" +
                  " WHERE " + FiltroDeSetor.Condicao("S") +
                  filtro + " ORDER BY C.DESCRICAO, S.DESCRICAO";

        using var con = _conexao.Abrir();
        return con.Query(sql, new { despesaId, setor = FiltroDeSetor.Numero(setor) })
                  .Select(l => new Subdespesa
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
    public Subdespesa CriarSubdespesa(string descricao, int despesaId, Setor setor)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Subdespesa.TamanhoMaximoDescricao);

        using var con = _conexao.Abrir();
        ExigirDespesaExistente(con, despesaId, setor);

        // Duas subdespesas de mesmo nome em despesas diferentes são legítimas: o legado tem
        // "MANUTENÇÃO" em mais de um centro de custo. A checagem é dentro da despesa.
        var repetida = con.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM SUBCATEGORIA WHERE CATEGORIA_ID = @despesaId " +
            "AND UPPER(DESCRICAO) = @d" + FiltroDeSetor.ECondicao(),
            new { despesaId, d = limpa.ToUpperInvariant(), setor = FiltroDeSetor.Numero(setor) });
        if (repetida > 0)
            throw new RegraDeNegocioException($"Já existe a subdespesa \"{limpa}\" nessa despesa.");

        var id = con.ExecuteScalar<int>(
            "INSERT INTO SUBCATEGORIA (DESCRICAO, CATEGORIA_ID, VALOR_MAXIMO, SETOR_ID) " +
            "VALUES (@d, @despesaId, 0, @setor) RETURNING SUBCATEGORIA_ID",
            new { d = limpa, despesaId, setor = FiltroDeSetor.Numero(setor) });

        return new Subdespesa { Id = id, Descricao = limpa, DespesaId = despesaId };
    }

    public Subdespesa AlterarSubdespesa(int id, string descricao, int despesaId, Setor setor)
    {
        var limpa = ValidacaoCadastro.ExigirDescricao(descricao, Subdespesa.TamanhoMaximoDescricao);

        using var con = _conexao.Abrir();
        ExigirDespesaExistente(con, despesaId, setor);

        var repetida = con.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM SUBCATEGORIA " +
            "WHERE CATEGORIA_ID = @despesaId AND UPPER(DESCRICAO) = @d AND SUBCATEGORIA_ID <> @id"
                + FiltroDeSetor.ECondicao(),
            new { despesaId, d = limpa.ToUpperInvariant(), id, setor = FiltroDeSetor.Numero(setor) });
        if (repetida > 0)
            throw new RegraDeNegocioException($"Já existe a subdespesa \"{limpa}\" nessa despesa.");

        if (con.Execute("UPDATE SUBCATEGORIA SET DESCRICAO = @d, CATEGORIA_ID = @despesaId " +
                        "WHERE SUBCATEGORIA_ID = @id" + FiltroDeSetor.ECondicao(),
                        new { d = limpa, despesaId, id, setor = FiltroDeSetor.Numero(setor) }) == 0)
            throw new RegraDeNegocioException("Subdespesa não encontrada.");

        return new Subdespesa { Id = id, Descricao = limpa, DespesaId = despesaId };
    }

    public void ExcluirSubdespesa(int id, Setor setor) =>
        Excluir("SUBCATEGORIA", "SUBCATEGORIA_ID", id, "subdespesa", setor);

    // ---------------- Apoio ----------------

    /// <summary>O parâmetro do setor sozinho, para as consultas que não têm outro.</summary>
    private static object Apenas(Setor setor) => new { setor = FiltroDeSetor.Numero(setor) };

    /// <summary>
    /// A despesa precisa existir **no setor de quem cadastra**. Sem isso, uma subdespesa poderia
    /// nascer pendurada na despesa do outro setor e aparecer, na lista de lá, classificada sob
    /// um nome que ninguém daquele lado criou.
    /// </summary>
    private static void ExigirDespesaExistente(IDbConnection con, int despesaId, Setor setor)
    {
        var existe = con.ExecuteScalar<int>(
            "SELECT COUNT(*) FROM CATEGORIA WHERE CATEGORIA_ID = @id" + FiltroDeSetor.ECondicao(),
            new { id = despesaId, setor = FiltroDeSetor.Numero(setor) });
        if (existe == 0)
            throw new RegraDeNegocioException("A despesa informada não existe.");
    }

    private static void ExigirDescricaoInedita(IDbConnection con, string tabela, string descricao,
                                               string rotulo, Setor setor,
                                               (string Coluna, int Id)? exceto = null)
    {
        var sql = $"SELECT COUNT(*) FROM {tabela} WHERE UPPER(DESCRICAO) = @d"
                  + FiltroDeSetor.ECondicao();
        if (exceto is not null) sql += $" AND {exceto.Value.Coluna} <> @id";

        var repetida = con.ExecuteScalar<int>(sql,
            new
            {
                d = descricao.ToUpperInvariant(),
                id = exceto?.Id ?? 0,
                setor = FiltroDeSetor.Numero(setor)
            });

        if (repetida > 0)
            throw new RegraDeNegocioException($"Já existe uma {rotulo} chamada \"{descricao}\".");
    }

    /// <summary>
    /// Exclui traduzindo a violação de chave estrangeira em explicação para o operador —
    /// mesma gentileza do legado, que diz "este registro está sendo referenciado em outra
    /// tabela" em vez de mostrar o erro técnico.
    /// </summary>
    private void Excluir(string tabela, string coluna, int id, string rotulo, Setor setor)
    {
        using var con = _conexao.Abrir();
        try
        {
            if (con.Execute($"DELETE FROM {tabela} WHERE {coluna} = @id" + FiltroDeSetor.ECondicao(),
                            new { id, setor = FiltroDeSetor.Numero(setor) }) == 0)
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
