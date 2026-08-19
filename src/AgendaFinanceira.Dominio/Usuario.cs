namespace AgendaFinanceira.Dominio;

/// <summary>
/// Nível de acesso, como o legado usa a coluna LOGIN.NIVEL.
/// </summary>
public enum NivelAcesso
{
    /// <summary>Só consulta. No legado, perde os menus de Cadastros, Lançamentos e Usuários.</summary>
    Consulta = 1,
    /// <summary>Operação normal: lançar, alterar, excluir.</summary>
    Operacao = 2,
    /// <summary>Tudo, mais cadastro de usuários e importação por planilha.</summary>
    Administracao = 3
}

/// <summary>Usuário do sistema — tabela LOGIN.</summary>
public sealed record Usuario
{
    public required int Id { get; init; }
    public required string Nome { get; init; }
    public required NivelAcesso Nivel { get; init; }

    /// <summary>
    /// Verdadeiro enquanto este usuário ainda depende da senha em texto plano do legado.
    /// Vira falso assim que ele entra uma vez pela API e o hash é gravado.
    /// </summary>
    public required bool AindaSemHash { get; init; }

    /// <summary>
    /// No legado, o usuário 1 é o administrador de fato: é o único que enxerga o backup e o
    /// único que pode alterar ou excluir lançamento de outra pessoa.
    /// </summary>
    public bool EhAdministradorDeFato => Id == 1;

    public bool PodeCadastrarUsuarios => Nivel == NivelAcesso.Administracao;
    public bool PodeImportarPlanilha => Nivel == NivelAcesso.Administracao;
    public bool PodeLancar => Nivel >= NivelAcesso.Operacao;

    /// <summary>
    /// Só quem lançou pode alterar ou excluir, com o usuário 1 podendo tudo.
    ///
    /// A regra existe no legado mas está **comentada** no botão Alterar, valendo apenas no
    /// Excluir — ver docs/dominio.md. Aqui ela vale para os dois, e essa divergência é
    /// correção intencional que precisa constar do relatório de paridade.
    /// </summary>
    public bool PodeModificarLancamentoDe(int autorId) =>
        EhAdministradorDeFato || autorId == Id;
}

/// <summary>Gera e confere hash de senha.</summary>
public interface IServicoSenha
{
    string GerarHash(string senha);
    bool Confere(string senha, string hash);
}
