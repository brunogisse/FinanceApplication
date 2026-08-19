# 0009 — Acesso a dados com Dapper, e como ler o charset WIN1252

- **Situação:** Aceita
- **Data:** 2026-08-19

## Contexto

O [ADR 0007](0007-backend-dotnet.md) deixou a escolha entre Dapper e EF Core condicionada a um
spike, por depender de um fato não verificado: quão bem o ferramental .NET lida com um Firebird
2.5.

O spike foi executado contra a cópia de trabalho e está preservado em
`src/AgendaFinanceira.SpikeFirebird`. Pode ser rodado de novo a qualquer momento com
`dotnet run`.

### O que o spike provou

Provider `FirebirdSql.Data.FirebirdClient` 10.3.4 sobre .NET 8:

| Verificação | Resultado |
|---|---|
| Conexão com Firebird 2.5.9 | funciona |
| Tipo de `VALOR_PREVISTO` | chega como `Single`, confirmando o `FLOAT` |
| Conversão do valor impreciso | `147059.765625` vira `R$ 147.059,77` corretamente |
| `DATA_VENCIMENTO` | chega sem hora, `Kind=Unspecified` — `DateOnly` serve |
| Total pago acumulado | `R$ 34.501.459,68`, idêntico ao levantado na Fase 2 |
| `INSERT` sem informar o ID | aceito; a trigger atribuiu, como previsto |
| Reversão da transação | funciona; nada ficou gravado |

Ou seja: o caminho .NET → Firebird 2.5 está livre, e a estratégia de tratar a imprecisão
monetária na borda ([0006](0006-dinheiro-em-decimal.md)) se confirma na prática.

### O que o spike revelou de inesperado

**O provider não aceita `WIN1252`.** Nem `WIN1252`, nem `Windows1252`, nem `windows1252` —
todas rejeitadas com `Invalid character set specified`. O enum interno tem `Windows1252`, mas a
string da conexão não o aceita. É uma limitação real do provider, não erro de digitação.

Os charsets que funcionam contra este banco:

- **`NONE`** — corrompe a acentuação. `JC REPRESENTAÇÃO` vira `JC REPRESENTA??O`.
- **`ISO8859_1`** — devolve a acentuação corretamente.

Só que ISO-8859-1 e WIN1252 são idênticos apenas de `0xA0` a `0xFF`, faixa onde vivem os
acentos do português. **Eles divergem de `0x80` a `0x9F`**, onde o WIN1252 põe travessões,
aspas curvas e reticências — exatamente os caracteres que Word e Excel inserem sozinhos.

Varrendo os 19.065 valores de texto do banco, **um registro usa essa faixa**:

```
REGISTRO_DE_GASTOS.OBS, byte 0x96 (travessão)
  correto   : Lote 12 – Quadra K – Escritura R$ 1.486,10
  ISO8859_1 : Lote 12   Quadra K   Escritura R$ 1.486,10
```

Um em dezenove mil. Mas é dado financeiro, a perda é silenciosa, e o fluxo de importação por
planilha lê do Excel — que produz esses caracteres naturalmente. O legado não os normaliza: sua
função `RemoverAcentos` trata acentos, não pontuação tipográfica. Ou seja, **novos casos podem
aparecer a qualquer momento**, inclusive gravados pelo Delphi durante a convivência.

## Decisão

### Acesso a dados: Dapper

O provider ADO.NET se mostrou sólido, e Dapper é uma camada fina sobre ele — o risco herdado é
mínimo.

O argumento decisivo contra o EF Core nesta etapa não é técnico, é de contexto: durante a
convivência **não controlamos o schema**. Ele pertence ao Delphi. O maior benefício do EF Core,
que são as migrações versionadas, não se aplica enquanto o legado for dono da estrutura. E as
consultas do legado já estão catalogadas em [fluxos.md](../fluxos.md), prontas para reaproveitar
— num banco sem índice de data, controlar o SQL emitido importa.

O EF Core volta a ser avaliado na Etapa 3 de [0005](0005-estrategia-de-banco.md), quando o
schema passar a ser nosso.

### Charset: `ISO8859_1` na conexão, com três salvaguardas

1. **Conexão em `ISO8859_1`.** Resolve corretamente a acentuação de todo o resto.
2. **Colunas de texto livre lidas como bytes.** `REGISTRO_DE_GASTOS.DESCRICAO` e
   `REGISTRO_DE_GASTOS.OBS` são lidas com
   `CAST(coluna AS VARCHAR(n) CHARACTER SET OCTETS)` e decodificadas em C# com
   `Encoding.GetEncoding(1252)`. São os campos onde texto humano entra sem filtro, e onde o
   único caso conhecido apareceu.
3. **Normalização na escrita.** Antes de gravar, a API converte a faixa `0x80`–`0x9F` para
   equivalentes ASCII: travessão vira hífen, aspas curvas viram retas, reticências viram três
   pontos. Impede que a API introduza novos casos.

O teste `[9]` do spike fica como **sentinela**: roda contra a base e informa quantos textos
usam a faixa divergente. Se o número crescer, o Delphi introduziu casos novos e vale reavaliar.

Quando o banco migrar para UTF-8 — Firebird 5 ou PostgreSQL —, o problema desaparece e as
salvaguardas 2 e 3 podem ser removidas.

## Consequências

**Mais fácil:** começar a escrever a API com uma incerteza técnica a menos. O caminho está
provado ponta a ponta, com evidência reproduzível em vez de suposição.

**Mais difícil:** sem EF Core, coisas como filtro global de baixa lógica e mapeamento
automático passam a ser responsabilidade do código. As consultas ficam explícitas — o que é
bom para controle e ruim para volume de digitação.

**Passa a ser obrigatório:** toda leitura de `DESCRICAO` e `OBS` de `REGISTRO_DE_GASTOS` usa o
caminho de bytes; toda escrita de texto passa pela normalização. E o valor `147059.765625`
serve como caso de teste permanente da conversão monetária — está no spike e deve migrar para a
suíte de paridade.

**Fica registrado:** o spike não testou o EF Core. A decisão por Dapper foi tomada pelo
argumento de contexto acima, não por o EF Core ter falhado. Se o argumento mudar, a decisão
merece ser revisitada com um spike próprio.
