using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
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
public sealed record ParcelarDto(int Parcelas);
public sealed record PagarEmLoteDto(IReadOnlyList<int> Ids);

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

        // ---------------- Operações em lote ----------------

        grupo.MapPost("/{id:int}/parcelar", (RepositorioLancamentos repo, ClaimsPrincipal quem,
                                             int id, ParcelarDto dto) =>
        {
            var r = repo.Parcelar(id, dto.Parcelas, Autenticado(quem));
            return Results.Ok(new
            {
                parcelas = r.Parcelas.Select(LancamentoDto.De).ToList(),
                idOriginalExcluido = r.IdOriginalExcluido,
                valorOriginal = r.ValorOriginal.Valor,
                somaDasParcelas = r.SomaDasParcelas.Valor,
                fechou = r.Fechou
            });
        })
        .RequireAuthorization(Politicas.PodeOperar)
        .WithSummary("Divide um lançamento em parcelas")
        .WithDescription(
            "Gera N lançamentos com o sufixo `i/N` na descrição, a primeira parcela vencendo " +
            "no mês do vencimento original, e **exclui o lançamento de origem** — como no legado.\n\n" +
            "⚠️ **Duas divergências intencionais:**\n\n" +
            "1. **A soma das parcelas é exatamente o valor original.** O legado divide direto e " +
            "perde: R$ 20.000,00 em 12 vira doze parcelas de R$ 1.666,666626, somando " +
            "R$ 19.999,9995. Há 200 parcelas nessa condição na base. Aqui o resto é distribuído " +
            "nas primeiras parcelas, e o campo `fechou` confirma.\n" +
            "2. **É uma transação só.** No legado cada gravação confirma sozinha, então uma " +
            "falha no meio deixa parcelas gravadas e o original ainda presente.\n\n" +
            "A autoria do lançamento original é preservada nas parcelas.");

        grupo.MapPost("/pagar-em-lote", (RepositorioLancamentos repo, ClaimsPrincipal quem,
                                         PagarEmLoteDto dto) =>
        {
            var r = repo.PagarEmLote(dto.Ids, Autenticado(quem));
            return Results.Ok(new
            {
                pagos = r.Pagos,
                jaEstavamPagos = r.JaEstavamPagos,
                semPermissao = r.SemPermissao,
                naoEncontrados = r.NaoEncontrados,
                quantidade = r.Quantidade,
                totalPago = r.TotalPago.Valor
            });
        })
        .RequireAuthorization(Politicas.PodeOperar)
        .WithSummary("Quita vários lançamentos de uma vez")
        .WithDescription(
            "Para cada lançamento ainda não pago: data de pagamento hoje e valor pago igual ao " +
            "previsto, como faz o legado.\n\n" +
            "⚠️ **Divergência intencional:** um lançamento já pago é apenas ignorado. No legado, " +
            "o avanço para o próximo registro está dentro da condição \"se não pago\", então um " +
            "único item já pago na lista **trava a aplicação em laço infinito**.\n\n" +
            "A resposta discrimina o destino de cada identificador — pago, já estava pago, sem " +
            "permissão ou inexistente — em vez de silenciar.");

        grupo.MapPost("/importar/previa", async (IFormFile planilha) =>
        {
            if (planilha.Length == 0)
                throw new RegraDeNegocioException("Envie uma planilha.");

            await using var conteudo = planilha.OpenReadStream();
            using var memoria = new MemoryStream();
            await conteudo.CopyToAsync(memoria);
            memoria.Position = 0;

            var leitura = LeitorDePlanilha.Ler(memoria);
            var linhas = leitura.Linhas;

            return Results.Ok(new
            {
                quantidade = linhas.Count,
                // Soma em decimal, nunca em ponto flutuante — é dinheiro.
                total = linhas.Sum(l => l.Valor.Valor),
                creditosIgnorados = leitura.CreditosIgnorados,
                datasHerdadas = leitura.DatasHerdadas,
                primeiraLinhaComDados = leitura.PrimeiraLinhaComDados,
                linhas = linhas.Select(l => new
                {
                    numeroDaLinha = l.NumeroDaLinha,
                    data = l.Data.ToString("yyyy-MM-dd"),
                    descricao = l.Descricao,
                    valor = l.Valor.Valor
                }).ToList()
            });
        })
        .RequireAuthorization(Politicas.PodeAdministrar)
        .DisableAntiforgery()
        .WithSummary("Mostra o que a planilha vai gravar, sem gravar nada (nível 3)")
        .WithDescription(
            "Lê a planilha exatamente como a importação lê — mesma aba, mesmas colunas, mesma " +
            "consolidação de linhas sem data — e devolve o que sairia disso, sem tocar no banco.\n\n" +
            "Existe porque a importação grava um lote inteiro de lançamentos **já quitados** e " +
            "não tem desfazer: conferir antes é a única defesa. Também é aqui que erros de " +
            "formato aparecem, antes de qualquer escrita.");

        grupo.MapPost("/importar", async (RepositorioLancamentos repo, ClaimsPrincipal quem,
                                          IFormFile planilha,
                                          int subdespesaId, int contaId, int formaPagamentoId,
                                          [FromForm] string? descricoes) =>
        {
            if (planilha.Length == 0)
                throw new RegraDeNegocioException("Envie uma planilha.");

            await using var conteudo = planilha.OpenReadStream();
            using var memoria = new MemoryStream();
            await conteudo.CopyToAsync(memoria);
            memoria.Position = 0;

            var leitura = LeitorDePlanilha.Ler(memoria);
            var linhas = LeitorDePlanilha.AplicarDescricoesManuais(
                leitura.Linhas, LerDescricoesManuais(descricoes));

            var r = repo.ImportarLote(
                linhas, subdespesaId, contaId, formaPagamentoId, Autenticado(quem));

            return Results.Ok(new
            {
                quantidade = r.Quantidade,
                total = r.Total.Valor,
                creditosIgnorados = leitura.CreditosIgnorados,
                lancamentos = r.Lancamentos.Select(LancamentoDto.De).ToList()
            });
        })
        .RequireAuthorization(Politicas.PodeAdministrar)
        .DisableAntiforgery()
        .WithSummary("Importa um lote de pagamentos de uma planilha (nível 3)")
        .WithDescription(
            "Lê o `.xlsx` na aba `Planilha1` — não achando, usa a primeira. Coluna 1 data, " +
            "2 descrição, 3 valor. Título e cabeçalho no alto são pulados: os dados começam " +
            "na primeira linha com data legível.\n\n" +
            "**Serve extrato bancário direto.** Valor terminado em `C` é crédito e fica de " +
            "fora — este sistema é contas a pagar. Linha com valor mas sem data herda a data " +
            "da anterior, que é como o extrato marca dois lançamentos no mesmo dia.\n\n" +
            "**Linha só com descrição — sem data e sem valor — não vira registro novo:** sua " +
            "descrição é anexada à do registro anterior, separada por \" - \". É assim que uma " +
            "despesa com várias linhas de detalhe é consolidada.\n\n" +
            "Todo o lote recebe a mesma subdespesa, conta e forma de pagamento, e entra **já " +
            "quitado**, com a data histórica da planilha. É isso que explica os 10.481 " +
            "lançamentos com pagamento anterior ao cadastro — comportamento esperado, não defeito.\n\n" +
            "⚠️ **Divergências intencionais:** o lote é uma transação só, então uma linha " +
            "inválida impede o lote inteiro em vez de gravar pela metade. E a leitura não " +
            "depende de ter o Excel instalado, ao contrário do legado, que usa automação OLE.\n\n" +
            "O campo `descricoes` é opcional: um JSON `{\"216\": \"TEXTO\"}` com o que a pessoa " +
            "digitou para as linhas que a planilha trouxe sem histórico. Só preenche o que " +
            "está em branco.");
    }

    /// <summary>
    /// Lê o JSON `{"216": "TEXTO"}` das descrições digitadas na prévia.
    ///
    /// Recusa formato torto em vez de ignorar: a pessoa digitou algo que precisa chegar, e
    /// engolir isso gravaria o lote com a linha em branco — que é o erro que ela corrigiu.
    /// </summary>
    private static IReadOnlyDictionary<int, string>? LerDescricoesManuais(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return null;

        try
        {
            var bruto = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
            if (bruto is null) return null;

            return bruto
                .Where(p => int.TryParse(p.Key, out _))
                .ToDictionary(p => int.Parse(p.Key), p => p.Value);
        }
        catch (JsonException)
        {
            throw new RegraDeNegocioException(
                "As descrições digitadas não chegaram em formato válido. Confira a planilha de novo.");
        }
    }
}
