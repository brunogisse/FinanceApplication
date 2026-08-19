using AgendaFinanceira.Dominio;
using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Api;

public sealed record DescricaoDto(string Descricao);
public sealed record SubdespesaDto(string Descricao, int DespesaId);
public sealed record CredenciaisDto(string Usuario, string Senha);
public sealed record TrocaSenhaDto(int UsuarioId, string SenhaNova);

public static class EndpointsCadastros
{
    public static void MapearCadastros(this WebApplication app)
    {
        // ---------------- Sessão ----------------

        app.MapPost("/sessao", (RepositorioUsuarios repo, CredenciaisDto dto) =>
        {
            var r = repo.Autenticar(dto.Usuario, dto.Senha);
            if (!r.Autenticado)
                return Results.Json(new { erro = r.Motivo }, statusCode: StatusCodes.Status401Unauthorized);

            var u = r.Usuario!;
            return Results.Ok(new
            {
                u.Id,
                u.Nome,
                Nivel = u.Nivel.ToString(),
                u.PodeLancar,
                u.PodeImportarPlanilha,
                u.PodeCadastrarUsuarios,
                SenhaMigradaAgora = r.MigrouSenha
            });
        })
        .WithTags("Sessão")
        .WithSummary("Autentica um usuário")
        .WithDescription(
            "Durante a convivência com o legado, quem ainda não tem hash é validado contra a " +
            "senha em texto plano e tem o hash gravado nesse momento — a base migra sozinha " +
            "conforme as pessoas entram. Ver ADR 0010.\n\n" +
            "A recusa é sempre a mesma mensagem, para não revelar quais usuários existem.");

        app.MapPost("/sessao/trocar-senha", (RepositorioUsuarios repo, TrocaSenhaDto dto) =>
        {
            repo.TrocarSenha(dto.UsuarioId, dto.SenhaNova);
            return Results.Ok(new { mensagem = "Senha alterada." });
        })
        .WithTags("Sessão")
        .WithSummary("Troca a senha de um usuário")
        .WithDescription(
            "Grava nas duas colunas: o hash para a API e o texto plano para o Delphi continuar " +
            "funcionando. Por isso o limite de 20 caracteres, que é o tamanho da coluna do legado.");

        app.MapGet("/usuarios", (RepositorioUsuarios repo) =>
            Results.Ok(repo.Listar().Select(u => new
            {
                u.Id, u.Nome, Nivel = u.Nivel.ToString(), u.AindaSemHash
            })))
        .WithTags("Sessão")
        .WithSummary("Lista os usuários")
        .WithDescription("`aindaSemHash` mostra quem ainda não entrou pela API e portanto " +
                         "continua dependendo da senha em texto plano do legado.");

        // ---------------- Contas ----------------

        var contas = app.MapGroup("/contas").WithTags("Cadastros");

        contas.MapGet("/", (RepositorioCadastros repo) => Results.Ok(repo.ListarContas()))
              .WithSummary("Lista as contas");

        contas.MapPost("/", (RepositorioCadastros repo, DescricaoDto dto) =>
        {
            var c = repo.CriarConta(dto.Descricao);
            return Results.Created($"/contas/{c.Id}", c);
        }).WithSummary("Cria uma conta");

        contas.MapPut("/{id:int}", (RepositorioCadastros repo, int id, DescricaoDto dto) =>
            Results.Ok(repo.AlterarConta(id, dto.Descricao)))
              .WithSummary("Altera uma conta");

        contas.MapDelete("/{id:int}", (RepositorioCadastros repo, int id) =>
        {
            repo.ExcluirConta(id);
            return Results.NoContent();
        }).WithSummary("Exclui uma conta")
          .WithDescription("Recusa com explicação em português se houver lançamentos usando a conta.");

        // ---------------- Formas de pagamento ----------------

        var formas = app.MapGroup("/formas-pagamento").WithTags("Cadastros");

        formas.MapGet("/", (RepositorioCadastros repo) => Results.Ok(repo.ListarFormasPagamento()))
              .WithSummary("Lista as formas de pagamento");

        formas.MapPost("/", (RepositorioCadastros repo, DescricaoDto dto) =>
        {
            var f = repo.CriarFormaPagamento(dto.Descricao);
            return Results.Created($"/formas-pagamento/{f.Id}", f);
        }).WithSummary("Cria uma forma de pagamento");

        formas.MapPut("/{id:int}", (RepositorioCadastros repo, int id, DescricaoDto dto) =>
            Results.Ok(repo.AlterarFormaPagamento(id, dto.Descricao)))
              .WithSummary("Altera uma forma de pagamento");

        formas.MapDelete("/{id:int}", (RepositorioCadastros repo, int id) =>
        {
            repo.ExcluirFormaPagamento(id);
            return Results.NoContent();
        }).WithSummary("Exclui uma forma de pagamento");

        // ---------------- Despesas e subdespesas ----------------

        var despesas = app.MapGroup("/despesas").WithTags("Cadastros");

        despesas.MapGet("/", (RepositorioCadastros repo) => Results.Ok(repo.ListarDespesas()))
                .WithSummary("Lista as despesas")
                .WithDescription("Despesa é o que a tabela chama de CATEGORIA. Funciona como centro de custo.");

        despesas.MapPost("/", (RepositorioCadastros repo, DescricaoDto dto) =>
        {
            var d = repo.CriarDespesa(dto.Descricao);
            return Results.Created($"/despesas/{d.Id}", d);
        }).WithSummary("Cria uma despesa");

        despesas.MapPut("/{id:int}", (RepositorioCadastros repo, int id, DescricaoDto dto) =>
            Results.Ok(repo.AlterarDespesa(id, dto.Descricao)))
                .WithSummary("Altera uma despesa");

        despesas.MapDelete("/{id:int}", (RepositorioCadastros repo, int id) =>
        {
            repo.ExcluirDespesa(id);
            return Results.NoContent();
        }).WithSummary("Exclui uma despesa");

        var subs = app.MapGroup("/subdespesas").WithTags("Cadastros");

        subs.MapGet("/", (RepositorioCadastros repo, int? despesaId) =>
            Results.Ok(repo.ListarSubdespesas(despesaId)))
            .WithSummary("Lista as subdespesas")
            .WithDescription("Informe `despesaId` para trazer apenas as de uma despesa.");

        subs.MapPost("/", (RepositorioCadastros repo, SubdespesaDto dto) =>
        {
            var s = repo.CriarSubdespesa(dto.Descricao, dto.DespesaId);
            return Results.Created($"/subdespesas/{s.Id}", s);
        }).WithSummary("Cria uma subdespesa")
          .WithDescription("A subdespesa sempre nasce ligada a uma despesa. Nomes iguais em " +
                           "despesas diferentes são permitidos — o legado tem MANUTENÇÃO em mais de uma.");

        subs.MapPut("/{id:int}", (RepositorioCadastros repo, int id, SubdespesaDto dto) =>
            Results.Ok(repo.AlterarSubdespesa(id, dto.Descricao, dto.DespesaId)))
            .WithSummary("Altera uma subdespesa");

        subs.MapDelete("/{id:int}", (RepositorioCadastros repo, int id) =>
        {
            repo.ExcluirSubdespesa(id);
            return Results.NoContent();
        }).WithSummary("Exclui uma subdespesa");
    }
}
