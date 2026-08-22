---
description: Executa uma consulta SQL na cópia de trabalho do Firebird com as proteções do projeto
argument-hint: <pergunta ou SQL a executar>
allowed-tools: PowerShell, Bash, Read, Write, Glob
---

Responda com dados do banco: **$ARGUMENTS**

## Como proceder

1. **Use a cópia de trabalho**, nunca o banco de produção. Procure `COPIA_TRABALHO.FDB` na
   pasta de scratchpad. Se não existir, gere uma com `/copia-banco` antes de continuar.

2. **Escreva a consulta num arquivo `.sql`** e execute com `isql -i`. Nunca passe SQL pela
   opção `-c`: o PowerShell come as aspas duplas dentro de argumentos de executável e o SQL
   chega deformado ao servidor.

   ```powershell
   & "C:\Program Files\Firebird\Firebird_2_5\bin\isql.exe" `
     -user SYSDBA -password masterkey -i consulta.sql -o saida.txt "localhost:$copia"
   ```

3. **Se a consulta alterar dados** — o que só é aceitável na cópia —, inclua **`-b`** (*bail*).
   Sem isso o `isql` segue executando as instruções seguintes depois de um erro, deixando um
   trabalho pela metade. `-v ON_ERROR_STOP=1` é do `psql`; o `isql` não conhece.

4. **Confira o código de saída e a saída.** Erros do Firebird aparecem no texto mesmo quando o
   código de saída é zero.

5. **Responda a pergunta**, não apenas cole o resultado. Números com contexto: quantos, de
   quantos, em que período.

## Particularidades deste banco

- Firebird 2.5, Dialect 3, charset WIN1252. `SET HEADING OFF;` deixa a saída mais limpa para
  leitura.
- `ORDER BY <posição>` **não aceita** expressão agregada — repita a expressão no `ORDER BY`.
- `FIRST n` em vez de `LIMIT`.
- **Valores monetários de `REGISTRO_DE_GASTOS` e `SUBCATEGORIA` são `FLOAT`.** Comparação
  exata com decimal falha por natureza. Use tolerância explícita e exiba o valor cru com casas
  suficientes para o problema aparecer:

  ```sql
  CAST(VALOR_PREVISTO AS NUMERIC(18,6))
  ```

- Grave o arquivo `.sql` com a ferramenta Write, em texto sem acento quando possível.
  `Set-Content` sem `-Encoding utf8` grava em ANSI e corrompe acentuação.

O dicionário de dados completo está em `docs/schema.md`.
