using Dapper;
using AgendaFinanceira.Dominio;

namespace AgendaFinanceira.Infraestrutura;

/// <summary>
/// O recorte por setor, num lugar só.
///
/// Com Dapper não existe filtro global como o `HasQueryFilter` do EF: quem esquece o `WHERE`
/// não recebe aviso nenhum, recebe os registros do outro setor. A defesa é esta classe ser o
/// único jeito de escrever a condição — nenhuma consulta digita `SETOR_ID` por conta própria —
/// mais o teste de vazamento, que percorre os endpoints com uma sessão do faturamento e prova
/// que nada do financeiro sai.
///
/// **Ela falha fechada e falha alto.** Um setor não informado vira o valor padrão da estrutura,
/// que é zero; em vez de virar uma consulta que não devolve nada — e passaria por "não há
/// lançamentos no período" —, vira recusa com mensagem.
/// </summary>
public static class FiltroDeSetor
{
    /// <summary>Nome do parâmetro. Único, para não colidir com os filtros da tela.</summary>
    public const string Parametro = "setor";

    /// <summary>A coluna acrescentada às seis tabelas na unificação.</summary>
    public const string Coluna = "SETOR_ID";

    /// <summary>
    /// A condição, pronta para entrar num `WHERE`.
    /// <paramref name="alias"/> é o apelido da tabela na consulta — vazio quando não houver.
    /// </summary>
    public static string Condicao(string alias = "") =>
        $"{Prefixo(alias)}{Coluna} = @{Parametro}";

    /// <summary>A mesma condição, já com o `AND` na frente, para pendurar no fim de um WHERE.</summary>
    public static string ECondicao(string alias = "") => " AND " + Condicao(alias);

    public static void Adicionar(DynamicParameters p, Setor setor) =>
        p.Add(Parametro, Numero(setor));

    /// <summary>
    /// O número a gravar ou comparar. Recusa o setor não informado, em vez de deixá-lo virar
    /// zero e produzir uma consulta silenciosamente vazia.
    /// </summary>
    public static int Numero(Setor setor) =>
        setor.EhValido
            ? setor.Id
            : throw new RegraDeNegocioException(
                  "Esta sessão não tem setor definido, e sem ele não é possível saber quais " +
                  "registros mostrar. Entre de novo; se persistir, o cadastro do usuário " +
                  "precisa receber um setor.");

    private static string Prefixo(string alias) =>
        string.IsNullOrWhiteSpace(alias) ? "" : alias.Trim() + ".";
}
