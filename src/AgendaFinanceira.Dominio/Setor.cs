namespace AgendaFinanceira.Dominio;

/// <summary>
/// O setor a que um registro pertence — a separação que a base unificada carrega.
///
/// As duas bases que viviam separadas viraram uma só em 08/09/2026, e **nada foi fundido por
/// semelhança**: o que era do financeiro continua do financeiro, o que era do faturamento
/// continua do faturamento, e os 9.251 lançamentos que existiam nas duas existem duas vezes,
/// um em cada setor. Ver docs/unificacao-das-bases.md.
///
/// É um tipo próprio, e não um `int`, por um motivo prático: numa assinatura como
/// `Alterar(int id, ..., Setor setor)` o compilador impede a troca de posição entre o
/// identificador e o setor. Com dois inteiros, trocá-los compila — e a consulta iria buscar o
/// registro errado no setor errado, calada.
/// </summary>
public readonly record struct Setor
{
    public int Id { get; }

    private Setor(int id) => Id = id;

    /// <summary>Setor 1 — a base original, da Juliana.</summary>
    public static readonly Setor Financeiro = new(1);

    /// <summary>Setor 2 — o que veio da base da aline.</summary>
    public static readonly Setor Faturamento = new(2);

    /// <summary>
    /// Falso para o valor padrão da estrutura, que é o que sobra quando alguém esquece de
    /// informar o setor. Nenhuma consulta aceita esse valor: ver <c>FiltroDeSetor</c>.
    /// </summary>
    public bool EhValido => Id > 0;

    public static Setor De(int id) =>
        id > 0 ? new Setor(id)
               : throw new RegraDeNegocioException(
                     "O setor informado não é válido. Cada usuário precisa pertencer a um setor.");

    /// <summary>Lê o valor gravado na coluna, que pode ser nulo em registro criado pelo Delphi.</summary>
    public static Setor? DeOuNulo(int? id) => id is null or <= 0 ? null : new Setor(id.Value);

    public override string ToString() => Id.ToString();
}
