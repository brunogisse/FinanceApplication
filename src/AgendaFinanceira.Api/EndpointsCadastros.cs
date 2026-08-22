using System.Security.Claims;
using AgendaFinanceira.Dominio;
using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Api;

public sealed record DescricaoDto(string Descricao);
public sealed record SubdespesaDto(string Descricao, int DespesaId);
public sealed record CredenciaisDto(string Usuario, string Senha);
public sealed record TrocaSenhaDto(int UsuarioId, string SenhaNova);
public sealed record UsuarioNovoDto(string Nome, int Nivel, string Senha);
public sealed record UsuarioAlteradoDto(string Nome, int Nivel);

public static class EndpointsCadastros
{
    public static void MapearCadastros(this WebApplication app)
    {
        // ---------------- Sessão ----------------

        app.MapPost("/sessao", (RepositorioUsuarios repo, ServicoToken tokens, CredenciaisDto dto) =>
        {
            var r = repo.Autenticar(dto.Usuario, dto.Senha);
            if (!r.Autenticado)
                return Results.Json(new { erro = r.Motivo }, statusCode: StatusCodes.Status401Unauthorized);

            var u = r.Usuario!;
            var (token, expira) = tokens.Emitir(u);

            return Results.Ok(new
            {
                token,
                expiraEm = expira,
                u.Id,
                u.Nome,
                Nivel = u.Nivel.ToString(),
                u.PodeLancar,
                u.PodeImportarPlanilha,
                u.PodeCadastrarUsuarios,
                SenhaMigradaAgora = r.MigrouSenha
            });
        })
        .AllowAnonymous()
        .WithTags("Sessão")
        .WithSummary("Autentica e devolve o token de acesso")
        .WithDescription(
            "Durante a convivência com o legado, quem ainda não tem hash é validado contra a " +
            "senha em texto plano e tem o hash gravado nesse momento — a base migra sozinha " +
            "conforme as pessoas entram. Ver ADR 0010.\n\n" +
            "A recusa é sempre a mesma mensagem, para não revelar quais usuários existem.\n\n" +
            "O token vale 12 horas. Informe-o em **Authorize**, no topo desta página.");

        app.MapPost("/sessao/trocar-senha", (RepositorioUsuarios repo, ClaimsPrincipal quem,
                                             TrocaSenhaDto dto) =>
        {
            var id = quem.IdDoUsuario();
            var ehAdministrador = int.TryParse(quem.FindFirst("nivel")?.Value, out var n) && n >= 3;

            // Cada um troca a própria senha; só o administrador troca a de outro.
            if (dto.UsuarioId != id && !ehAdministrador)
                throw new RegraDeNegocioException("Você só pode trocar a sua própria senha.");

            repo.TrocarSenha(dto.UsuarioId, dto.SenhaNova);
            return Results.Ok(new { mensagem = "Senha alterada." });
        })
        .RequireAuthorization()
        .WithTags("Sessão")
        .WithSummary("Troca a senha de um usuário")
        .WithDescription(
            "Cada usuário troca a própria senha; o nível 3 pode trocar a de qualquer um.\n\n" +
            "Grava nas duas colunas: o hash para a API e o texto plano para o Delphi continuar " +
            "funcionando. Por isso o limite de 20 caracteres, que é o tamanho da coluna do legado.");

        app.MapGet("/usuarios", (RepositorioUsuarios repo) =>
            Results.Ok(repo.Listar().Select(u => new
            {
                u.Id, u.Nome, Nivel = u.Nivel.ToString(), u.AindaSemHash
            })))
        .RequireAuthorization(Politicas.PodeAdministrar)
        .WithTags("Sessão")
        .WithSummary("Lista os usuários (nível 3)")
        .WithDescription("`aindaSemHash` mostra quem ainda não entrou pela API e portanto " +
                         "continua dependendo da senha em texto plano do legado.");

        app.MapPost("/usuarios", (RepositorioUsuarios repo, UsuarioNovoDto dto) =>
        {
            var u = repo.Criar(
                new DadosUsuario { Nome = dto.Nome, Nivel = RegrasUsuario.ExigirNivel(dto.Nivel) },
                dto.Senha);

            return Results.Created($"/usuarios/{u.Id}",
                new { u.Id, u.Nome, Nivel = u.Nivel.ToString(), u.AindaSemHash });
        })
        .RequireAuthorization(Politicas.PodeAdministrar)
        .WithTags("Sessão")
        .WithSummary("Cria um usuário (nível 3)")
        .WithDescription(
            "A senha é gravada **nas duas colunas**: o hash para a API e o texto plano para o " +
            "Delphi continuar autenticando quem foi criado aqui. Sem isso a pessoa entraria " +
            "pelo sistema novo e seria recusada pelo antigo.\n\n" +
            "⚠️ **Divergências intencionais em relação ao legado**, cuja tela é um " +
            "`TDBNavigator` sobre `select * from LOGIN` sem validação nenhuma:\n\n" +
            "- **Nome único**, sem diferenciar maiúsculas. Nome repetido não é só desordem: a " +
            "autenticação busca por `UPPER(NOME)` esperando um só registro e **estoura em vez " +
            "de recusar o login**.\n" +
            "- **Nível restrito a 1, 2 ou 3.** O legado aceita qualquer inteiro, e um nível 7 " +
            "passaria em toda checagem de \"maior ou igual a 2\".\n" +
            "- **Senha de 4 a 20 caracteres.** O teto é o tamanho da coluna do legado.");

        app.MapPut("/usuarios/{id:int}", (RepositorioUsuarios repo, ClaimsPrincipal quem,
                                          int id, UsuarioAlteradoDto dto) =>
        {
            var u = repo.Alterar(
                id,
                new DadosUsuario { Nome = dto.Nome, Nivel = RegrasUsuario.ExigirNivel(dto.Nivel) },
                quem.Autenticado());

            return Results.Ok(new { u.Id, u.Nome, Nivel = u.Nivel.ToString(), u.AindaSemHash });
        })
        .RequireAuthorization(Politicas.PodeAdministrar)
        .WithTags("Sessão")
        .WithSummary("Altera o nome e o nível de um usuário (nível 3)")
        .WithDescription(
            "A senha **não** passa por aqui — quem troca senha é `POST /sessao/trocar-senha`. " +
            "Misturar as duas coisas faria uma correção de nome reescrever a senha por descuido.\n\n" +
            "Duas travas contra alguém se trancar para fora: o usuário 1 é o administrador de " +
            "fato do legado e precisa continuar no nível 3, e ninguém rebaixa o próprio nível.");

        app.MapDelete("/usuarios/{id:int}", (RepositorioUsuarios repo, ClaimsPrincipal quem,
                                             int id) =>
        {
            repo.Excluir(id, quem.Autenticado());
            return Results.NoContent();
        })
        .RequireAuthorization(Politicas.PodeAdministrar)
        .WithTags("Sessão")
        .WithSummary("Exclui um usuário (nível 3)")
        .WithDescription(
            "Quem já lançou não pode ser excluído, e **a regra está no banco**: existe a chave " +
            "estrangeira `FK_REGISTRO_DE_GASTOS_5`, de `USERID` para `LOGIN`. A contagem feita " +
            "antes serve só para a mensagem dizer quantos lançamentos são, em vez de vazar o " +
            "erro cru do Firebird.\n\n" +
            "O usuário 1 não pode ser excluído, e ninguém exclui a si mesmo.");

        // ---------------- Contas ----------------

        var contas = app.MapGroup("/contas").WithTags("Cadastros").RequireAuthorization();

        contas.MapGet("/", (RepositorioCadastros repo) => Results.Ok(repo.ListarContas()))
              .WithSummary("Lista as contas");

        contas.MapPost("/", (RepositorioCadastros repo, DescricaoDto dto) =>
        {
            var c = repo.CriarConta(dto.Descricao);
            return Results.Created($"/contas/{c.Id}", c);
        }).RequireAuthorization(Politicas.PodeOperar).WithSummary("Cria uma conta");

        contas.MapPut("/{id:int}", (RepositorioCadastros repo, int id, DescricaoDto dto) =>
            Results.Ok(repo.AlterarConta(id, dto.Descricao)))
              .RequireAuthorization(Politicas.PodeOperar).WithSummary("Altera uma conta");

        contas.MapDelete("/{id:int}", (RepositorioCadastros repo, int id) =>
        {
            repo.ExcluirConta(id);
            return Results.NoContent();
        }).RequireAuthorization(Politicas.PodeOperar).WithSummary("Exclui uma conta")
          .WithDescription("Recusa com explicação em português se houver lançamentos usando a conta.");

        // ---------------- Formas de pagamento ----------------

        var formas = app.MapGroup("/formas-pagamento").WithTags("Cadastros").RequireAuthorization();

        formas.MapGet("/", (RepositorioCadastros repo) => Results.Ok(repo.ListarFormasPagamento()))
              .WithSummary("Lista as formas de pagamento");

        formas.MapPost("/", (RepositorioCadastros repo, DescricaoDto dto) =>
        {
            var f = repo.CriarFormaPagamento(dto.Descricao);
            return Results.Created($"/formas-pagamento/{f.Id}", f);
        }).RequireAuthorization(Politicas.PodeOperar).WithSummary("Cria uma forma de pagamento");

        formas.MapPut("/{id:int}", (RepositorioCadastros repo, int id, DescricaoDto dto) =>
            Results.Ok(repo.AlterarFormaPagamento(id, dto.Descricao)))
              .RequireAuthorization(Politicas.PodeOperar).WithSummary("Altera uma forma de pagamento");

        formas.MapDelete("/{id:int}", (RepositorioCadastros repo, int id) =>
        {
            repo.ExcluirFormaPagamento(id);
            return Results.NoContent();
        }).RequireAuthorization(Politicas.PodeOperar).WithSummary("Exclui uma forma de pagamento");

        // ---------------- Despesas e subdespesas ----------------

        var despesas = app.MapGroup("/despesas").WithTags("Cadastros").RequireAuthorization();

        despesas.MapGet("/", (RepositorioCadastros repo) => Results.Ok(repo.ListarDespesas()))
                .WithSummary("Lista as despesas")
                .WithDescription("Despesa é o que a tabela chama de CATEGORIA. Funciona como centro de custo.");

        despesas.MapPost("/", (RepositorioCadastros repo, DescricaoDto dto) =>
        {
            var d = repo.CriarDespesa(dto.Descricao);
            return Results.Created($"/despesas/{d.Id}", d);
        }).RequireAuthorization(Politicas.PodeOperar).WithSummary("Cria uma despesa");

        despesas.MapPut("/{id:int}", (RepositorioCadastros repo, int id, DescricaoDto dto) =>
            Results.Ok(repo.AlterarDespesa(id, dto.Descricao)))
                .RequireAuthorization(Politicas.PodeOperar).WithSummary("Altera uma despesa");

        despesas.MapDelete("/{id:int}", (RepositorioCadastros repo, int id) =>
        {
            repo.ExcluirDespesa(id);
            return Results.NoContent();
        }).RequireAuthorization(Politicas.PodeOperar).WithSummary("Exclui uma despesa");

        var subs = app.MapGroup("/subdespesas").WithTags("Cadastros").RequireAuthorization();

        subs.MapGet("/", (RepositorioCadastros repo, int? despesaId) =>
            Results.Ok(repo.ListarSubdespesas(despesaId)))
            .WithSummary("Lista as subdespesas")
            .WithDescription("Informe `despesaId` para trazer apenas as de uma despesa.");

        subs.MapPost("/", (RepositorioCadastros repo, SubdespesaDto dto) =>
        {
            var s = repo.CriarSubdespesa(dto.Descricao, dto.DespesaId);
            return Results.Created($"/subdespesas/{s.Id}", s);
        }).RequireAuthorization(Politicas.PodeOperar).WithSummary("Cria uma subdespesa")
          .WithDescription("A subdespesa sempre nasce ligada a uma despesa. Nomes iguais em " +
                           "despesas diferentes são permitidos — o legado tem MANUTENÇÃO em mais de uma.");

        subs.MapPut("/{id:int}", (RepositorioCadastros repo, int id, SubdespesaDto dto) =>
            Results.Ok(repo.AlterarSubdespesa(id, dto.Descricao, dto.DespesaId)))
            .RequireAuthorization(Politicas.PodeOperar).WithSummary("Altera uma subdespesa");

        subs.MapDelete("/{id:int}", (RepositorioCadastros repo, int id) =>
        {
            repo.ExcluirSubdespesa(id);
            return Results.NoContent();
        }).RequireAuthorization(Politicas.PodeOperar).WithSummary("Exclui uma subdespesa");
    }
}
