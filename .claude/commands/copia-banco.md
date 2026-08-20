---
description: Gera uma cópia de trabalho isolada do banco Firebird legado usando gbak
argument-hint: [caminho do .FDB de origem] (opcional, padrão DADOS_12_23.FDB)
allowed-tools: PowerShell, Bash, Read
---

Gere uma cópia de trabalho do banco legado.

Origem: `$1` — se vazio, use
`C:\PROGRAMAS\V OFICIAL\AGENDA FINANCEIRA ITAPUA\Win32\Debug\Dados\DADOS_12_23.FDB`.

## Passos

1. **Confirme a origem antes de tocar nela.** Mostre caminho, tamanho e data de modificação.
   Verifique se algum processo mantém o arquivo aberto tentando obter bloqueio exclusivo — se
   estiver aberto, avise e pergunte antes de continuar.

2. **Backup lógico** com `gbak -b` para a pasta de scratchpad. Nunca copie o arquivo `.FDB`
   diretamente: cópia bruta de banco aberto pode sair inconsistente.

3. **Restaure** com `gbak -c` para `COPIA_TRABALHO.FDB` na mesma pasta. Se já existir uma
   cópia, avise que será substituída e peça confirmação antes.

4. **Verifique** o resultado: confira o código de saída de cada passo e, além disso, o efeito
   — o arquivo apareceu, e uma contagem em `REGISTRO_DE_GASTOS` bate com o esperado
   (13.972 na base de referência). Código de saída zero sozinho não prova nada.

5. **Relate** o caminho da cópia, o tamanho e a contagem conferida.

## Lembretes

- O `gbak` conecta pelo servidor (`localhost:caminho`), o que **avança os contadores de
  transação no cabeçalho da origem** e muda a data do arquivo. Nenhum dado é alterado, mas
  mencione isso no relato. Se a exigência for zero escrita na origem, copie o arquivo primeiro
  com `Copy-Item` e rode o `gbak` contra a cópia.
- Binários em `C:\Program Files\Firebird\Firebird_2_5\bin`.
- Nunca execute DDL ou DML na origem. Ver `docs/decisoes/0002-banco-legado-e-sagrado.md`.
