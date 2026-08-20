# 0001 — Adotar ADRs para registrar decisões

- **Situação:** Aceita
- **Data:** 2026-08-18

## Contexto

O sistema legado tem quatro anos de decisões que ninguém consegue explicar hoje. Alguns
exemplos encontrados na engenharia reversa:

- Por que os valores monetários do módulo financeiro são `FLOAT` enquanto os do módulo de
  estoque são `NUMERIC(15,2)`?
- Por que a verificação de permissão está comentada no botão Alterar e ativa no Excluir?
- Por que a atualização de saldo do estoque foi desligada em vez de o módulo ser removido?
- Por que o backup automático aponta para caminhos fixos na área de trabalho de um usuário?

Nenhuma dessas perguntas tem resposta no código, no histórico do Git ou em documento algum.
Cada uma delas custou tempo de investigação e algumas continuam sem resposta — só é possível
descrever o comportamento, não a intenção.

A migração vai gerar muito mais decisões do que o legado gerou, e várias serão difíceis de
reverter.

## Decisão

Toda decisão arquitetural relevante do projeto é registrada como um ADR em `docs/decisoes/`,
seguindo o formato descrito no [README](README.md).

Uma decisão é "relevante" quando pelo menos uma destas for verdadeira:

- é cara ou arriscada de reverter depois
- alguém razoável escolheria diferente
- afeta a integridade dos dados financeiros
- estabelece uma regra que vale para todo o projeto

ADRs não são editados após aceitos. Uma mudança de rumo gera um novo ADR que substitui o
anterior.

## Consequências

**Mais fácil:** entender o porquê de escolhas antigas; retomar o trabalho depois de uma pausa;
discordar de uma decisão de forma produtiva, com o contexto original à vista.

**Mais difícil:** decidir no impulso. Escrever o ADR obriga a articular o motivo, o que às
vezes revela que a decisão não estava madura — o que é justamente o objetivo.

**Passa a ser obrigatório:** abrir um ADR antes de mudar o schema do banco legado, trocar a
stack de qualquer camada, ou alterar a forma como valores monetários são representados.
