# 0003 — Português do Brasil em todo o projeto

- **Situação:** Aceita
- **Data:** 2026-08-18

## Contexto

O legado já é escrito em português: tabelas (`REGISTRO_DE_GASTOS`, `SUBCATEGORIA`), colunas
(`VALOR_PREVISTO`, `DATA_VENCIMENTO`), telas e mensagens. O vocabulário do negócio também é
português — "despesa", "subdespesa", "lançamento", "baixa", "conta".

Há, porém, uma mistura: alguns identificadores estão em inglês (`DuploClickNaGrid = 'SUPPLIER'`,
`EntradaOuSaidaOuRelatorio`, `allowPrint`, `paymentCondition`), e várias mensagens de commit
alternam entre os dois idiomas. Essa inconsistência obriga quem lê o código a traduzir
mentalmente de um lado para o outro.

Quem mantém o sistema fala português. Os usuários falam português. Os nomes do domínio são
português.

## Decisão

Todo o projeto é escrito em **português do Brasil**: documentação, comentários, nomes de
domínio, mensagens de interface, mensagens de erro e mensagens de commit.

Ficam em inglês apenas os termos que são da linguagem ou da ferramenta, e que traduzir tornaria
mais confuso: palavras-chave, nomes de bibliotecas, verbos HTTP, padrões consagrados
(`repository`, `middleware`), e convenções obrigatórias de framework.

Os nomes de tabela e coluna do legado são **preservados exatamente** como estão no banco,
inclusive na documentação, para que a busca por um nome encontre tanto o código quanto o
documento.

Mensagens de commit não usam acento no corpo, por causa do comportamento do terminal no
ambiente de desenvolvimento. Mensagens longas vão em arquivo, com `git commit -F` — aspas na
opção `-m` quebram o argumento no PowerShell.

## Consequências

**Mais fácil:** ler o código na mesma língua em que se conversa com o usuário sobre o
problema. A distância entre "o que a Juliana chamou de subdespesa" e `SUBCATEGORIA` no código
fica menor.

**Mais difícil:** copiar exemplos de tutoriais sem adaptar. Alguns termos ficam esquisitos
traduzidos e exigem julgamento caso a caso.

**Passa a ser obrigatório:** ao criar código novo que conversa com o legado, manter o
vocabulário do legado mesmo quando um nome melhor existir. Renomear conceitos durante a
migração é fonte garantida de confusão — a hora de renomear é depois da paridade, se ainda
fizer sentido.
