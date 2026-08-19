namespace AgendaFinanceira.Dominio;

/// <summary>De onde o dinheiro sai. Mistura bancos e pessoas — tabela CONTAS.</summary>
public sealed record Conta
{
    public int Id { get; init; }
    public required string Descricao { get; init; }

    public const int TamanhoMaximoDescricao = 50;
}

/// <summary>Como o dinheiro sai — tabela FORMA_DE_PAGAMENTO.</summary>
public sealed record FormaPagamento
{
    public int Id { get; init; }
    public required string Descricao { get; init; }

    public const int TamanhoMaximoDescricao = 50;
}

/// <summary>
/// Nível mais alto de classificação, que na prática funciona como centro de custo.
/// A tabela chama CATEGORIA; a tela do legado, e as pessoas, chamam Despesa.
/// </summary>
public sealed record Despesa
{
    public int Id { get; init; }
    public required string Descricao { get; init; }

    public const int TamanhoMaximoDescricao = 100;
}

/// <summary>
/// Detalha uma Despesa. Tabela SUBCATEGORIA.
///
/// O campo de teto (VALOR_MAXIMO) existe no banco mas nunca foi preenchido em nenhuma das 148
/// subdespesas — ver docs/dominio.md. Fica aqui apenas para não perder o dado.
/// </summary>
public sealed record Subdespesa
{
    public int Id { get; init; }
    public required string Descricao { get; init; }
    public required int DespesaId { get; init; }
    public string? Despesa { get; init; }
    public Dinheiro? ValorMaximo { get; init; }

    public const int TamanhoMaximoDescricao = 100;
}

/// <summary>
/// Recusa de uma operação por violar uma regra de negócio. Diferente de erro técnico: a
/// mensagem é para o operador ler, e é ela que a API devolve.
/// </summary>
public sealed class RegraDeNegocioException : Exception
{
    public RegraDeNegocioException(string mensagem) : base(mensagem) { }
}

/// <summary>Validações compartilhadas pelos cadastros.</summary>
public static class ValidacaoCadastro
{
    /// <summary>
    /// A descrição é obrigatória e limitada pelo tamanho da coluna.
    ///
    /// O legado não impõe isso no banco — não há constraint nenhuma —, e o resultado é uma
    /// categoria com descrição vazia na base de produção.
    /// </summary>
    public static string ExigirDescricao(string? valor, int tamanhoMaximo, string campo = "descrição")
    {
        var limpo = valor?.Trim();

        if (string.IsNullOrEmpty(limpo))
            throw new RegraDeNegocioException($"Informe a {campo}.");

        if (limpo.Length > tamanhoMaximo)
            throw new RegraDeNegocioException(
                $"A {campo} pode ter no máximo {tamanhoMaximo} caracteres, e tem {limpo.Length}.");

        return limpo;
    }
}
