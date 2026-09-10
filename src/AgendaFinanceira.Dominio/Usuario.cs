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
    /// O setor desta pessoa — o que ela enxerga.
    ///
    /// **Nível e setor são coisas diferentes:** o nível diz o que ela pode fazer, o setor diz
    /// sobre quais registros. Um nível 3 do financeiro administra tudo, dentro do financeiro.
    ///
    /// É `required` de propósito: sem isso, uma construção esquecida sairia com o valor padrão
    /// da estrutura e o filtro passaria a valer contra o setor nenhum.
    /// </summary>
    public required Setor Setor { get; init; }

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


/// <summary>Dados para criar ou alterar um usuário.</summary>
public sealed record DadosUsuario
{
    public required string Nome { get; init; }
    public required NivelAcesso Nivel { get; init; }

    /// <summary>
    /// O setor de quem está sendo cadastrado.
    ///
    /// A tabela LOGIN é **compartilhada pelos dois setores** — foi ela que permitiu unificar as
    /// bases sem duplicar ninguém —, então o setor é escolhido no cadastro e não herdado de
    /// quem cadastra.
    /// </summary>
    public required Setor Setor { get; init; }
}

/// <summary>
/// Regras do cadastro de usuários.
///
/// **Nenhuma delas existe no legado.** A tela de lá é um TDBNavigator sobre
/// `select * from LOGIN`, sem validação alguma, com a senha visível num campo comum. Cada
/// regra aqui fecha um buraco concreto, anotado no comentário de cada uma.
/// </summary>
public static class RegrasUsuario
{
    /// <summary>Tamanho de LOGIN.NOME e LOGIN.SENHA no legado — VARCHAR(20) as duas.</summary>
    public const int TamanhoMaximoNome = 20;
    public const int TamanhoMaximoSenha = 20;

    /// <summary>
    /// Mínimo de 4. As senhas do legado têm de 3 a 6 caracteres; o teto de 20 vem da coluna,
    /// e some quando o Delphi for desligado.
    /// </summary>
    public const int TamanhoMinimoSenha = 4;

    /// <summary>
    /// No legado o usuário 1 é o administrador de fato: único que enxerga o backup e único
    /// que altera lançamento de outra pessoa. Rebaixá-lo ou excluí-lo trancaria o sistema.
    /// </summary>
    public const int IdDoAdministradorDeFato = 1;

    public static string ExigirNome(string? valor) =>
        ValidacaoCadastro.ExigirDescricao(valor, TamanhoMaximoNome, "nome do usuário");

    /// <summary>
    /// A senha é obrigatória na criação — a coluna LOGIN.SENHA é NOT NULL, e sem texto plano
    /// o Delphi não consegue autenticar quem foi criado pela API.
    /// </summary>
    public static string ExigirSenha(string? valor)
    {
        if (string.IsNullOrEmpty(valor))
            throw new RegraDeNegocioException("Informe a senha.");

        if (valor.Length < TamanhoMinimoSenha)
            throw new RegraDeNegocioException(
                $"A senha precisa de pelo menos {TamanhoMinimoSenha} caracteres.");

        // O limite é do legado, não nosso: a senha também vai para a coluna em texto plano,
        // que tem 20 caracteres. Cai quando o Delphi for desligado.
        if (valor.Length > TamanhoMaximoSenha)
            throw new RegraDeNegocioException(
                "Enquanto o sistema antigo estiver em uso, a senha pode ter no máximo " +
                $"{TamanhoMaximoSenha} caracteres.");

        return valor;
    }

    /// <summary>
    /// O legado aceita qualquer inteiro em NIVEL — um usuário com nível 7 passaria em toda
    /// checagem de "maior ou igual a 2" e viraria administrador por acidente.
    /// </summary>
    public static NivelAcesso ExigirNivel(int valor)
    {
        if (!Enum.IsDefined(typeof(NivelAcesso), valor))
            throw new RegraDeNegocioException(
                "O nível precisa ser 1 (consulta), 2 (operação) ou 3 (administração).");

        return (NivelAcesso)valor;
    }

    /// <summary>
    /// Recusa a alteração que trancaria alguém para fora do sistema.
    ///
    /// Duas travas: o administrador de fato não perde o nível 3, e ninguém se rebaixa a si
    /// mesmo — um administrador sozinho que se rebaixasse deixaria o sistema sem quem
    /// cadastre usuários, e a única saída seria mexer no banco por fora.
    /// </summary>
    public static void ExigirQuePodeAlterar(int alvoId, NivelAcesso nivelNovo, Usuario quemAltera)
    {
        if (alvoId == IdDoAdministradorDeFato && nivelNovo != NivelAcesso.Administracao)
            throw new RegraDeNegocioException(
                "O usuário 1 é o administrador do sistema e precisa continuar no nível 3.");

        if (alvoId == quemAltera.Id && nivelNovo != NivelAcesso.Administracao)
            throw new RegraDeNegocioException(
                "Você não pode rebaixar o seu próprio nível — ficaria sem como voltar atrás.");
    }

    /// <summary>Mesma preocupação da alteração: ninguém se apaga, e o usuário 1 não se apaga.</summary>
    public static void ExigirQuePodeExcluir(int alvoId, Usuario quemExclui)
    {
        if (alvoId == IdDoAdministradorDeFato)
            throw new RegraDeNegocioException(
                "O usuário 1 é o administrador do sistema e não pode ser excluído.");

        if (alvoId == quemExclui.Id)
            throw new RegraDeNegocioException("Você não pode excluir o seu próprio usuário.");
    }
}

/// <summary>Gera e confere hash de senha.</summary>
public interface IServicoSenha
{
    string GerarHash(string senha);
    bool Confere(string senha, string hash);
}
