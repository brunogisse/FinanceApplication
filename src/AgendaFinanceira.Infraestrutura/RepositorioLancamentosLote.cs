using Dapper;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>
/// Operações em lote: parcelamento e pagamento de vários lançamentos.
///
/// São os fluxos com mais defeito conhecido no legado, e por isso os últimos a migrar.
/// Ver docs/roadmap.md, Etapa 5.
/// </summary>
public sealed partial class RepositorioLancamentos
{
    /// <summary>
    /// Divide um lançamento em N parcelas e exclui o original.
    ///
    /// Duas diferenças em relação ao legado, ambas intencionais:
    ///
    /// 1. **A soma das parcelas é exatamente o valor original.** O legado divide direto e
    ///    perde: R$ 20.000,00 em 12 vira doze parcelas de R$ 1.666,666626, somando
    ///    R$ 19.999,9995. Há 200 parcelas nessa condição na base.
    /// 2. **É uma transação só.** No legado, cada Post confirma sozinho, então uma falha no
    ///    meio deixa parcelas gravadas e o original ainda presente.
    /// </summary>
    public ResultadoParcelamento Parcelar(int id, int parcelas, Usuario quem, DateOnly? hoje = null)
    {
        RegrasParcelamento.ExigirQuantidadeValida(parcelas);

        var original = PorId(id) ?? throw new RegraDeNegocioException("Lançamento não encontrado.");
        ExigirPermissao(quem, original);

        if (original.ValorPrevisto.EhZero)
            throw new RegraDeNegocioException("Não é possível parcelar um lançamento sem valor.");

        if (original.DataVencimento is null)
            throw new RegraDeNegocioException(
                "Não é possível parcelar um lançamento sem data de vencimento.");

        var referencia = hoje ?? DateOnly.FromDateTime(DateTime.Today);
        var valores = original.ValorPrevisto.Dividir(parcelas);
        var vencimentoBase = original.DataVencimento.Value;

        using var con = _conexao.Abrir();
        using var tx = con.BeginTransaction();
        try
        {
            var ids = new List<int>(parcelas);

            for (var numero = 1; numero <= parcelas; numero++)
            {
                var p = new DynamicParameters();
                p.Add("despesaId", original.DespesaId);
                p.Add("subdespesaId", original.SubdespesaId);
                p.Add("contaId", original.ContaId);
                p.Add("formaId", original.FormaPagamentoId);
                // A autoria do original é preservada: parcelar não muda quem lançou.
                p.Add("usuarioId", original.UsuarioId);
                p.Add("descricao", ConexaoFirebird.NormalizarParaGravar(
                    RegrasParcelamento.DescricaoDaParcela(original.Descricao, numero, parcelas)));
                p.Add("valorPrevisto", (double)valores[numero - 1].Valor);
                p.Add("valorPago", (double)(original.Pago ? valores[numero - 1] : Dinheiro.Zero).Valor);
                p.Add("pago", original.Pago ? 1 : 0);
                p.Add("dataVencimento",
                    RegrasParcelamento.VencimentoDaParcela(vencimentoBase, numero)
                                      .ToDateTime(TimeOnly.MinValue));
                p.Add("dataPagamento", original.DataPagamento?.ToDateTime(TimeOnly.MinValue));
                p.Add("dataCadastro",
                    (original.DataCadastro ?? referencia).ToDateTime(TimeOnly.MinValue));
                // Diferente do legado, que copia lixo de memória quando o original tem esses
                // campos nulos, aqui o nulo é preservado como zero, que é o que o banco guarda.
                p.Add("notaFiscal", original.NotaFiscal ?? 0);
                p.Add("cheque", original.Cheque ?? 0);
                p.Add("chequeCompensado", original.ChequeCompensado ? "S" : "N");
                p.Add("situacao", TextoDaSituacao(original.Situacao));
                p.Add("obs", RegrasParcelamento.ObservacaoPadrao);
                p.Add("entradaId", original.EntradaId);

                ids.Add(con.ExecuteScalar<int>(@"
INSERT INTO REGISTRO_DE_GASTOS
    (CATEGORIA_ID, SUBCATEGORIA_ID, CONTA_ID, FORMA_DE_PAGAMENTO_ID, USERID,
     DESCRICAO, VALOR_PREVISTO, VALOR_PAGO, PAGO,
     DATA_VENCIMENTO, DATA_PAGAMENTO, DATA_CADASTRO,
     NOTA_FISCAL, CHEQUE, CHEQUE_COMPENSADO, SITUACAO_STATUS, OBS, ENTRADA_ID)
VALUES
    (@despesaId, @subdespesaId, @contaId, @formaId, @usuarioId,
     @descricao, @valorPrevisto, @valorPago, @pago,
     @dataVencimento, @dataPagamento, @dataCadastro,
     @notaFiscal, @cheque, @chequeCompensado, @situacao, @obs, @entradaId)
RETURNING GASTOS_ID", p, tx));
            }

            // O original só some depois que todas as parcelas entraram, e no mesmo commit.
            con.Execute("DELETE FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = @id", new { id }, tx);

            tx.Commit();

            var geradas = ids.Select(i => PorId(i)!).ToList();
            return new ResultadoParcelamento
            {
                Parcelas = geradas,
                IdOriginalExcluido = id,
                ValorOriginal = original.ValorPrevisto
            };
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }

    /// <summary>
    /// Quita vários lançamentos de uma vez: data de pagamento hoje e valor pago igual ao
    /// previsto, como faz o legado.
    ///
    /// **Um lançamento já pago é simplesmente ignorado.** No legado, o avanço para o próximo
    /// registro está dentro da condição "se não pago", então um item já pago na grade trava a
    /// aplicação em laço infinito — `UfrmLancamentos.pas:426`.
    ///
    /// O resultado diz o que aconteceu com cada identificador, em vez de silenciar.
    /// </summary>
    public ResultadoPagamentoEmLote PagarEmLote(IReadOnlyList<int> ids, Usuario quem,
                                                DateOnly? hoje = null)
    {
        if (ids.Count == 0)
            throw new RegraDeNegocioException("Informe ao menos um lançamento para pagar.");

        var referencia = hoje ?? DateOnly.FromDateTime(DateTime.Today);

        var pagos = new List<int>();
        var jaPagos = new List<int>();
        var semPermissao = new List<int>();
        var naoEncontrados = new List<int>();
        var total = Dinheiro.Zero;

        using var con = _conexao.Abrir();
        using var tx = con.BeginTransaction();
        try
        {
            foreach (var id in ids.Distinct())
            {
                var linha = con.QuerySingleOrDefault(
                    "SELECT GASTOS_ID, PAGO, VALOR_PREVISTO, USERID " +
                    "FROM REGISTRO_DE_GASTOS WHERE GASTOS_ID = @id", new { id }, tx);

                if (linha is null) { naoEncontrados.Add(id); continue; }
                if ((int)linha.PAGO == 1) { jaPagos.Add(id); continue; }
                if (!quem.PodeModificarLancamentoDe((int)linha.USERID)) { semPermissao.Add(id); continue; }

                var valor = Dinheiro.DeFloatDoLegado((double)(linha.VALOR_PREVISTO ?? 0d));

                con.Execute(
                    "UPDATE REGISTRO_DE_GASTOS SET PAGO = 1, DATA_PAGAMENTO = @data, " +
                    "VALOR_PAGO = @valor WHERE GASTOS_ID = @id",
                    new
                    {
                        data = referencia.ToDateTime(TimeOnly.MinValue),
                        valor = (double)valor.Valor,
                        id
                    }, tx);

                pagos.Add(id);
                total += valor;
            }

            tx.Commit();
        }
        catch
        {
            tx.Rollback();
            throw;
        }

        return new ResultadoPagamentoEmLote
        {
            Pagos = pagos,
            JaEstavamPagos = jaPagos,
            SemPermissao = semPermissao,
            NaoEncontrados = naoEncontrados,
            TotalPago = total
        };
    }

    /// <summary>
    /// Grava um lote vindo de planilha. Todo o lote compartilha a mesma subdespesa, conta e
    /// forma de pagamento, e entra **já quitado**, com a data histórica da planilha — é o que
    /// o legado faz, e explica os 10.481 lançamentos com pagamento anterior ao cadastro.
    ///
    /// Diferente do legado, que grava linha a linha com commit individual, o lote inteiro é
    /// uma transação: ou entra tudo, ou não entra nada.
    /// </summary>
    public ResultadoImportacao ImportarLote(IReadOnlyList<LinhaImportada> linhas,
                                            int subdespesaId, int contaId, int formaPagamentoId,
                                            Usuario autor, DateOnly? hoje = null)
    {
        if (linhas.Count == 0)
            throw new RegraDeNegocioException("A planilha não tem nenhuma linha para importar.");

        var referencia = hoje ?? DateOnly.FromDateTime(DateTime.Today);

        using var con = _conexao.Abrir();
        using var tx = con.BeginTransaction();
        try
        {
            var despesaId = DespesaDaSubdespesa(con, tx, subdespesaId);
            ExigirExistencia(con, tx, "CONTAS", "CONTA_ID", contaId, "conta");
            ExigirExistencia(con, tx, "FORMA_DE_PAGAMENTO", "FORMA_DE_PAGAMENTO_ID",
                             formaPagamentoId, "forma de pagamento");

            var ids = new List<int>(linhas.Count);

            foreach (var linha in linhas)
            {
                if (string.IsNullOrWhiteSpace(linha.Descricao))
                    throw new RegraDeNegocioException(
                        $"A linha {linha.NumeroDaLinha} da planilha está sem descrição.");

                if (linha.Valor.EhNegativo)
                    throw new RegraDeNegocioException(
                        $"A linha {linha.NumeroDaLinha} da planilha tem valor negativo.");

                var p = new DynamicParameters();
                p.Add("despesaId", despesaId);
                p.Add("subdespesaId", subdespesaId);
                p.Add("contaId", contaId);
                p.Add("formaId", formaPagamentoId);
                p.Add("usuarioId", autor.Id);
                p.Add("descricao", ConexaoFirebird.NormalizarParaGravar(
                    linha.Descricao.Length > DadosLancamento.TamanhoMaximoDescricao
                        ? linha.Descricao[..DadosLancamento.TamanhoMaximoDescricao]
                        : linha.Descricao));
                p.Add("valor", (double)linha.Valor.Valor);
                p.Add("data", linha.Data.ToDateTime(TimeOnly.MinValue));
                p.Add("dataCadastro", referencia.ToDateTime(TimeOnly.MinValue));

                ids.Add(con.ExecuteScalar<int>(@"
INSERT INTO REGISTRO_DE_GASTOS
    (CATEGORIA_ID, SUBCATEGORIA_ID, CONTA_ID, FORMA_DE_PAGAMENTO_ID, USERID,
     DESCRICAO, VALOR_PREVISTO, VALOR_PAGO, PAGO,
     DATA_VENCIMENTO, DATA_PAGAMENTO, DATA_CADASTRO,
     NOTA_FISCAL, CHEQUE, CHEQUE_COMPENSADO, ENTRADA_ID)
VALUES
    (@despesaId, @subdespesaId, @contaId, @formaId, @usuarioId,
     @descricao, @valor, @valor, 1,
     @data, @data, @dataCadastro,
     0, 0, 'N', 0)
RETURNING GASTOS_ID", p, tx));
            }

            tx.Commit();

            var criados = ids.Select(i => PorId(i)!).ToList();
            return new ResultadoImportacao
            {
                Lancamentos = criados,
                Total = criados.Somar(l => l.ValorPago)
            };
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }
}
