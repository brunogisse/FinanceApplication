---
description: Extrai as regras de negócio de uma tela do legado Delphi e atualiza a documentação
argument-hint: <nome da unit ou da tela, ex: UfrmLancamentos ou "pagamento em lote">
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Agent
---

Extraia as regras de negócio de: **$ARGUMENTS**

## Como proceder

1. **Localize** a unit em `AGENDA FINANCEIRA ITAPUA/`. Se o argumento for o nome de um fluxo e
   não de um arquivo, procure primeiro em `docs/dominio.md` e `docs/fluxos.md` — pode já estar
   documentado, e nesse caso seu trabalho é aprofundar, não repetir.

2. **Leia o `.pas` inteiro.** Neste código a regra aparece em lugares improváveis: um
   `OnKeyPress` que salva, um `OnCellClick` que cancela edição, um `OnDrawColumnCell` que
   comunica status por cor.

3. **Leia o `.dfm` junto.** Metade da configuração está lá. Filtre, porque os `.dfm` grandes
   têm imagens embutidas:

   ```bash
   awk '/SQL\.Strings = \(/,/\)$/' arquivo.dfm
   grep -n -E "UpdateOptions\.|MasterSource|MasterFields|Transaction = " arquivo.dfm
   ```

4. **Rastreie o estado compartilhado.** As telas conversam por variáveis públicas
   (`setarEditFoco`, `DuploClickNaGrid`, `Parcelando`) e mexem nos datasets umas das outras.
   Uma regra costuma estar partida entre duas units.

5. **Relate o código comentado.** Neste projeto, código comentado é funcionalidade desligada
   de propósito — todo o controle de estoque está assim, e a verificação de permissão do botão
   Alterar também.

## O que produzir

Para cada regra: o que acontece em linguagem de negócio, onde está (`arquivo.pas:linha`), o
que dispara, quais tabelas e colunas toca, se há commit, e se está ativa ou comentada.

Para cada defeito: o **cenário concreto** que o expõe — quais dados, qual sequência, qual
resultado errado.

Depois atualize `docs/dominio.md` e, se o fluxo for novo ou tiver mudado,
`docs/fluxos.md`. Mantenha o estilo dos documentos existentes: linguagem de negócio no corpo,
referência ao código em citação.

## O que não fazer

**Não invente regra de negócio.** Se o código é ambíguo, diga que é ambíguo e apresente as
leituras possíveis. Uma regra financeira inventada custa mais caro do que uma pergunta.

Para uma varredura mais profunda, considere acionar o agente `analista-delphi`.
