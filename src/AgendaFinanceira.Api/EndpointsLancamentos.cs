using System.Security.Claims;
using AgendaFinanceira.Dominio;
using AgendaFinanceira.Infraestrutura;

namespace AgendaFinanceira.Api;

/// <summary>Dados de entrada para criar ou alterar um lançamento.</summary>
public sealed record LancamentoEntradaDto
{
    public required string Descricao { get; init; }
    public required int SubdespesaId { get; init; }
    public required int ContaId { get; init; }
    public required int FormaPagamentoId { get; init; }
    public required decimal ValorPrevisto { get; init; }
    public required DateOnly DataVencimento { get; init; }
    public bool Pago { get; init; }
    public DateOnly? DataPagamento { get; init; }
    public decimal? ValorPago { get; init; }
    public int? NotaFiscal { get; init; }
    public int? Cheque { get; init; }
    public bool ChequeCompensado { get; init; }
    public string? Situacao { get; init; }
    public string? Observacao { get; init; }

    public DadosLancamento ParaDominio() => new()
    {
        Descricao = Descricao,
        SubdespesaId = SubdespesaId,
        ContaId = ContaId,
        FormaPagamentoId = FormaPagamentoId,
        ValorPrevisto = Dinheiro.De(ValorPrevisto),
        DataVencimento = DataVencimento,
        Pago = Pago,
        DataPagamento = DataPagamento,
        ValorPago = ValorPago is null ? null : Dinheiro.De(ValorPago.Value),
        NotaFiscal = NotaFiscal,
        Cheque = Cheque,
        ChequeCompensado = ChequeCompensado,
        Situacao = LerSituacao(Situacao),
        Observacao = Observacao
    };

    public static SituacaoStatus LerSituacao(string? texto) => texto?.ToLowerInvariant() switch
    {
        "aguardando" => SituacaoStatus.Aguardando,
        "liberada" => SituacaoStatus.Liberada,
        _ => SituacaoStatus.Nenhuma
    };
}

public sealed record SituacaoDto(string Situacao);

public static class EndpointsLancamentos
{
    /// <summary>Monta o usuário a partir do token, sem ida ao banco.</summary>
    private static Usuario Autenticado(ClaimsPrincipal quem)
    {
        var nivel = int.TryParse(quem.FindFirst("nivel")?.Value, out var n) ? n : 1;
        return new Usuario
        {
            Id = quem.IdDoUsuario(),
            Nome = quem.Identity?.Name ?? "",
            Nivel = (NivelAcesso)nivel,
            AindaSemHash = false
        };
    }

    public static void MapearLancamentos(this WebApplication app)
    {
        var grupo = app.MapGroup("/lancamentos").WithTags("Lançamentos").RequireAuthorization();

        grupo.MapGet("/{id:int}", (RepositorioLancamentos repo, int id) =>
        {
            var l = repo.PorId(id);
            return l is null
                ? Results.NotFound(new { erro = "Lançamento não encontrado." })
                : Results.Ok(LancamentoDto.De(l));
        })
        .WithSummary("Busca um lançamento pelo identificador");

        grupo.MapPost("/", (RepositorioLancamentos repo, ClaimsPrincipal quem,
                            LancamentoEntradaDto dto) =>
        {
            var criado = repo.Criar(dto.ParaDominio(), Autenticado(quem));
            return Results.Created($"/lancamentos/{criado.Id}", LancamentoDto.De(criado));
        })
        .RequireAuthorization(Politicas.PodeOperar)
        .WithSummary("Lança uma despesa")
        .WithDescription(
            "A **despesa não é informada**: vem da subdespesa escolhida, como no legado, onde " +
            "selecionar a subdespesa preenche os dois campos juntos.\n\n" +
            "A autoria e a data de cadastro são carimbadas pelo servidor, nunca pelo cliente.\n\n" +
            "Com `pago = true` e sem `dataPagamento`, assume hoje; sem `valorPago`, assume o " +
            "valor previsto. Com `pago = false`, o valor pago é zerado e a data limpa — " +
            "exatamente o que o legado faz ao salvar.");

        grupo.MapPut("/{id:int}", (RepositorioLancamentos repo, ClaimsPrincipal quem,
                                   int id, LancamentoEntradaDto dto) =>
            Results.Ok(LancamentoDto.De(repo.Alterar(id, dto.ParaDominio(), Autenticado(quem)))))
        .RequireAuthorization(Politicas.PodeOperar)
        .WithSummary("Altera um lançamento")
        .WithDescription(
            "Só quem cadastrou pode alterar; o usuário 1 pode alterar qualquer um.\n\n" +
            "⚠️ **Divergência intencional em relação ao legado:** lá essa verificação está " +
            "comentada no botão Alterar e vale apenas no Excluir, de modo que hoje qualquer " +
            "usuário edita lançamento de qualquer outro.\n\n" +
            "Alterar não muda quem lançou nem a data de cadastro.");

        grupo.MapDelete("/{id:int}", (RepositorioLancamentos repo, ClaimsPrincipal quem, int id) =>
        {
            repo.Excluir(id, Autenticado(quem));
            return Results.NoContent();
        })
        .RequireAuthorization(Politicas.PodeOperar)
        .WithSummary("Exclui um lançamento")
        .WithDescription("Mesma regra de autoria da alteração.");

        grupo.MapPut("/{id:int}/situacao", (RepositorioLancamentos repo, ClaimsPrincipal quem,
                                            int id, SituacaoDto dto) =>
            Results.Ok(LancamentoDto.De(repo.DefinirSituacao(
                id, LancamentoEntradaDto.LerSituacao(dto.Situacao), Autenticado(quem)))))
        .RequireAuthorization(Politicas.PodeOperar)
        .WithSummary("Define a situação de liberação")
        .WithDescription("`aguardando`, `liberada` ou `nenhuma`. Na grade do legado, aguardando " +
                         "aparece em roxo — a cor é informação para quem opera.");
    }
}
