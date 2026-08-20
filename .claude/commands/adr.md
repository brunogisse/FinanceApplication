---
description: Cria um novo registro de decisão arquitetural (ADR) numerado
argument-hint: <título da decisão>
allowed-tools: Read, Glob, Write, Edit
---

Crie um ADR para: **$ARGUMENTS**

## Como proceder

1. **Leia `docs/decisoes/README.md`** e liste os ADRs existentes para descobrir o próximo
   número da sequência e não repetir uma decisão já registrada.

2. **Verifique se a decisão substitui alguma anterior.** Se sim, o novo ADR referencia o
   antigo, e o antigo é marcado como `Substituída por [NNNN]`. ADR aceito não se edita.

3. **Crie** `docs/decisoes/NNNN-titulo-em-kebab-case.md` com a estrutura:

   ```markdown
   # NNNN — Título

   - **Situação:** Proposta | Aceita | Substituída por [NNNN] | Revogada
   - **Data:** AAAA-MM-DD

   ## Contexto
   ## Decisão
   ## Consequências
   ```

4. **Atualize o índice** em `docs/decisoes/README.md`. Se a decisão estava listada como
   pendente da Fase 4, remova-a de lá.

## Como escrever

**Contexto:** fatos, não opiniões. Números quando existirem. O que motivou a decisão, o que
foi observado, quais restrições valiam. Quem ler daqui a um ano precisa entender a situação
sem ter estado presente.

**Decisão:** voz ativa, direto. "Valores monetários usam decimal em todas as camadas", não
"seria bom considerar decimal".

**Consequências:** o que fica mais fácil, o que fica mais difícil, e o que passa a ser
obrigatório. A parte "mais difícil" é a que dá valor ao documento — um ADR que só lista
vantagens não foi pensado até o fim.

Se a decisão envolve o banco legado ou valores monetários, releia as restrições em `CLAUDE.md`
antes de escrever. Para decisões de arquitetura com trade-off relevante, considere acionar o
agente `arquiteto-migracao`.
