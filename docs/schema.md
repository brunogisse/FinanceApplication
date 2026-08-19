# Dicionário de dados

Banco `DADOS_12_23.FDB` — Firebird 2.5 (ODS 11.2), **Dialect 3**, charset padrão **WIN1252**,
page size 16.384, atributo `force write`.

Extraído em 18/08/2026 de uma cópia de trabalho gerada por `gbak`. Volumetria da mesma data.

> A aplicação **não declara `CharacterSet`** na conexão FireDAC. Funciona porque cliente e
> banco são WIN1252; qualquer mudança para UTF-8 exige transliteração explícita.

---

## Visão geral

15 tabelas, divididas em dois módulos que se tocam num único ponto
(`REGISTRO_DE_GASTOS.ENTRADA_ID`).

```
FINANCEIRO (ativo)                    ESTOQUE / NF (inativo)

LOGIN                                 FORNECEDOR
  |                                     |
  | USERID                              | FORNECEDOR_ID
  v                                     v
CATEGORIA --< SUBCATEGORIA           CADASTRO_NF --< ITEM_NF >-- PRODUTO
  |              |                        ^                        |
  |              |                        |                        v
  +------+-------+                        |                   TIPO_PRODUTO
         |                                |
         v                     ENTRADA_ID |                   MOVIMENTACAO_PRODUTO
  REGISTRO_DE_GASTOS >----------------- --+                        ^
         ^  ^                                                      |
         |  |                                             SAIDA_PRODUTO
    CONTAS  FORMA_DE_PAGAMENTO                              |     |
                                                       DESTINO  PROPRIEDADE
```

**O vínculo `ENTRADA_ID` não tem chave estrangeira** — é um inteiro solto apontando para
`CADASTRO_NF`. Há 5 valores órfãos na base.

---

## Objetos existentes

| Objeto | Quantidade |
|---|---|
| Tabelas | 15 |
| Generators | 15 |
| Triggers | 15 (todas `BEFORE INSERT` de auto-incremento) |
| Views | **0** |
| Stored procedures | **0** |
| Domains de usuário | **0** |
| Constraints CHECK | **0** |
| Defaults de coluna | **0** |
| Índices além de PK/FK | **0** |

O banco garante integridade referencial e nada mais. **Toda regra de negócio está na
aplicação** — ver [dominio.md](dominio.md).

---

## Módulo financeiro

### REGISTRO_DE_GASTOS — 13.972 linhas

O coração do sistema. Cada linha é uma despesa a pagar ou já paga.

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `GASTOS_ID` | INTEGER | não | PK. Gerador `GEN_REGISTRO_DE_GASTOS_ID` |
| `CATEGORIA_ID` | INTEGER | não | FK para `CATEGORIA`. Despesa (centro de custo) |
| `SUBCATEGORIA_ID` | INTEGER | não | FK para `SUBCATEGORIA`. Subdespesa |
| `CONTA_ID` | INTEGER | não | FK para `CONTAS`. De onde o dinheiro sai |
| `FORMA_DE_PAGAMENTO_ID` | INTEGER | não | FK para `FORMA_DE_PAGAMENTO` |
| `USERID` | INTEGER | não | FK para `LOGIN`. Quem lançou |
| `DESCRICAO` | VARCHAR(200) | sim | Texto livre. Parcelas recebem o sufixo `i/N` |
| `VALOR_PREVISTO` | **FLOAT** | sim | Valor esperado. **Tipo errado** — ver abaixo |
| `VALOR_PAGO` | **FLOAT** | sim | Valor efetivamente pago. **Tipo errado** |
| `PAGO` | INTEGER | sim | `0` = a pagar, `1` = pago. Sem constraint |
| `DATA_VENCIMENTO` | DATE | sim | Quando vence |
| `DATA_PAGAMENTO` | DATE | sim | Quando foi pago |
| `DATA_CADASTRO` | DATE | sim | Quando foi digitado. Sempre o momento da gravação |
| `NOTA_FISCAL` | INTEGER | sim | Número da NF. Zero quando importado por planilha |
| `CHEQUE` | INTEGER | sim | Número do cheque ou documento |
| `CHEQUE_COMPENSADO` | CHAR(1) | sim | `'N'` ou `'S'`. Há 9 registros com `'s'` minúsculo |
| `ENTRADA_ID` | INTEGER | sim | Aponta para `CADASTRO_NF`. **Sem FK.** 5 órfãos |
| `SITUACAO_STATUS` | VARCHAR(10) | sim | `NULL`, `'AGUARDANDO'` ou `'LIBERADA'` |
| `OBS` | VARCHAR(200) | sim | Observação. Parcelas trazem texto automático |

Chaves estrangeiras: `FK_REGISTRO_DE_GASTOS_1..5` para `CATEGORIA`, `SUBCATEGORIA`, `CONTAS`,
`FORMA_DE_PAGAMENTO` e `LOGIN`.

Índices: apenas a PK e os cinco índices automáticos das FKs.
**Nenhum índice em `DATA_VENCIMENTO`, `DATA_PAGAMENTO` ou `DATA_CADASTRO`**, apesar de todas
as consultas do sistema filtrarem por essas colunas.

Distribuição dos dados:

- `PAGO`: 12.462 pagos, 1.510 a pagar
- `SITUACAO_STATUS`: 13.458 nulos, 501 `LIBERADA`, 13 `AGUARDANDO`
- Cadastros de 15/03/2022 a 26/03/2025; vencimentos até 08/07/2027
- Total pago acumulado: **R$ 34.501.459,68**
- 4.441 linhas (32%) geradas por parcelamento

Inconsistências conhecidas: 11 linhas com data 30/12/1899 (o zero do `TDateTime` do Delphi),
30 pagas sem data de pagamento, 24 pagas com valor zero, 4 não pagas com data de pagamento,
1 com valor pago nulo.

> #### O problema do tipo FLOAT
>
> `FLOAT` em Firebird é precisão simples (32 bits, ~7 dígitos significativos). Valores acima
> de R$ 99.999,99 não são representáveis exatamente, e mesmo abaixo disso muitos não são.
>
> ```
> ID=19035  gravado=147059.765625   pretendido=147059.77
> ID=17014  gravado=  1666.666626   pretendido=  1666.67
> ```
>
> Medido na base: 471 valores previstos e 400 pagos não fecham em dois decimais; 30 e 32
> respectivamente estão acima do limite de precisão. Maior erro individual: R$ 0,004375.
> Soma dos erros absolutos: R$ 0,296701.
>
> Na migração, esses valores devem ser convertidos para `NUMERIC(15,2)` com arredondamento
> explícito e documentado — e a conversão precisa ser validada valor a valor.

### CATEGORIA — 14 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `CATEGORIA_ID` | INTEGER | não | PK. Gerador `GEN_CATEGORIA_ID` |
| `DESCRICAO` | VARCHAR(100) | sim | Nome da despesa |

Existe uma linha com descrição vazia — provável cadastro acidental.

### SUBCATEGORIA — 148 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `SUBCATEGORIA_ID` | INTEGER | não | PK. Gerador `GEN_SUBCATEGORIA_ID` |
| `CATEGORIA_ID` | INTEGER | não | FK para `CATEGORIA` |
| `DESCRICAO` | VARCHAR(100) | sim | Nome da subdespesa |
| `VALOR_MAXIMO` | **FLOAT** | sim | Teto de gasto. **Zero ou nulo nas 148 linhas** |

`VALOR_MAXIMO` alimenta o painel de saldo da tela de lançamentos, que nunca foi usado.

### CONTAS — 14 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `CONTA_ID` | INTEGER | não | PK. Gerador `GEN_CONTAS_ID` |
| `DESCRICAO` | VARCHAR(50) | sim | Nome da conta |

Mistura contas bancárias e pessoas. `JC REPRESENTACAO 1162152` e
`JC REPRESENTAÇÃO -BRADESCO` parecem duplicidade — confirmar com o cliente.

### FORMA_DE_PAGAMENTO — 10 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `FORMA_DE_PAGAMENTO_ID` | INTEGER | não | PK. Gerador `GEN_FORMA_DE_PAGAMENTO_ID` |
| `DESCRICAO` | VARCHAR(50) | sim | Nome da forma de pagamento |

### LOGIN — 6 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `LOGIN_ID` | INTEGER | não | PK. Gerador `GEN_LOGIN_ID`. O ID 1 é o administrador de fato |
| `NOME` | VARCHAR(20) | **não** | Nome de acesso |
| `SENHA` | VARCHAR(20) | **não** | **Senha em texto plano**, 3 a 6 caracteres |
| `NIVEL` | INTEGER | **não** | 1 = consulta, 2 = operação, 3 = administração |

> **Dado sensível.** Anonimizar em qualquer base de desenvolvimento.

Uso real: `JULIANA` (nível 3, ID 1) fez 13.466 lançamentos; `aline` 446; `ALINEAP` 51;
`HAYOLLA` 9. `EGLECIR` e `KA` nunca lançaram.

---

## Módulo estoque e notas fiscais (inativo)

Mantido para consulta histórica. Ver [dominio.md](dominio.md#módulo-estoque-e-notas-fiscais--inativo).

### CADASTRO_NF — 592 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `CADASTRO_NF_ID` | INTEGER | não | PK. Gerador `GEN_CADASTRO_NF_ID` |
| `FORNECEDOR_ID` | INTEGER | sim | FK para `FORNECEDOR` |
| `DATA` | DATE | sim | Data da entrada |
| `DATA_EMISSAO_NF` | DATE | sim | Data de emissão da nota |
| `VALOR_NF` | NUMERIC(15,2) | sim | Soma dos itens |
| `NF` | INTEGER | sim | Número da nota |
| `STATUS` | VARCHAR(10) | sim | `'NF ABERTA'` ou `'PROCESSADA'` |
| `NF_LANCADA` | VARCHAR(3) | sim | `'SIM'`, `'NÃO'` ou `'AJU'` (ajuste) |
| `OBS` | VARCHAR(200) | sim | Observação |

### ITEM_NF — 1.412 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `ITEM_NF_ID` | INTEGER | não | PK. **Trigger usa o gerador errado** — ver triggers |
| `NF_ID` | INTEGER | sim | FK para `CADASTRO_NF` |
| `PRODUTO_ID` | INTEGER | sim | FK para `PRODUTO` |
| `VALOR_ITEM` | DECIMAL(15,2) | sim | Valor unitário |
| `QTDE_ITEM` | INTEGER | sim | Quantidade |
| `VALOR_TOTAL_ITEM` | DECIMAL(15,2) | sim | Valor unitário × quantidade |

### PRODUTO — 735 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `PRODUTO_ID` | INTEGER | não | PK. Gerador `GEN_PRODUTO_ID` |
| `DESCRICAO` | VARCHAR(40) | sim | Nome do produto |
| `VALOR` | DECIMAL(15,2) | sim | Preço unitário |
| `ESTOQUE` | INTEGER | sim | Saldo. **Não é mais atualizado** |
| `ESTOQUE_MINIMO` | INTEGER | sim | Ponto de reposição. Padrão 1 |
| `TIPO` | INTEGER | sim | FK para `TIPO_PRODUTO` |

### TIPO_PRODUTO — 7 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `TIPO_PRODUTO_ID` | INTEGER | não | PK. **Trigger usa o gerador errado** |
| `DESCRICAO` | VARCHAR(40) | sim | Nome do tipo |

### FORNECEDOR — 181 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `FORNECEDOR_ID` | INTEGER | não | PK. Gerador `GEN_FORNECEDOR_ID` |
| `NOME_FANTASIA` | VARCHAR(40) | sim | Nome fantasia |
| `RAZAO_SOCIAL` | VARCHAR(40) | sim | Razão social. Obrigatório pela aplicação |
| `CNPJ` | VARCHAR(18) | sim | **Dado sensível** — 157 preenchidos |
| `TELEFONE` | VARCHAR(20) | sim | **Dado sensível** — 135 preenchidos |

### SAIDA_PRODUTO — 1.294 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `SAIDA_PRODUTO_ID` | INTEGER | não | PK. **Trigger usa o gerador errado** |
| `PRODUTO_ID` | INTEGER | sim | FK para `PRODUTO` |
| `DESTINO_ID` | INTEGER | sim | FK para `DESTINO` |
| `PROPRIEDADE_ID` | INTEGER | sim | FK para `PROPRIEDADE` |
| `DATA` | DATE | sim | Data da saída |
| `QTDE` | INTEGER | sim | Quantidade |
| `VALOR_SAIDA` | DECIMAL(15,2) | sim | Quantidade × preço do produto |
| `OBS` | VARCHAR(200) | sim | Observação |

### MOVIMENTACAO_PRODUTO — 0 linhas

Histórico de entradas e saídas de estoque. **Vazia**, mas o gerador está em 1.923: houve 1.923
movimentações que foram apagadas.

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `MOVIMENTACAO_ID` | INTEGER | não | PK. Gerador `GEN_MOVIMENTACAO_PRODUTO_ID` |
| `PRODUTO_ID` | INTEGER | **não** | FK para `PRODUTO` |
| `DATA` | DATE | sim | Data do movimento |
| `TIPO` | CHAR(1) | sim | `'E'` entrada, `'S'` saída |
| `QTDE` | INTEGER | sim | Quantidade movimentada |
| `SALDO_ATUAL` | INTEGER | sim | Saldo do produto no momento |
| `VALOR_PRODUTO` | DECIMAL(15,2) | sim | Preço no momento |
| `OBS` | VARCHAR(200) | sim | Observação |
| `ADICIONAIS` | VARCHAR(200) | sim | Rastro: origem do movimento e usuário |

### DESTINO — 53 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `DESTINO_ID` | INTEGER | não | PK. Gerador `GEN_DESTINO_ID` |
| `DESCRICAO` | VARCHAR(35) | sim | Para onde o produto foi |

### PROPRIEDADE — 12 linhas

| Coluna | Tipo | Nulo | Propósito |
|---|---|---|---|
| `DESCRICAO` | VARCHAR(35) **CHARACTER SET NONE** | sim | Nome da propriedade |
| `PROPRIEDADE_ID` | INTEGER | não | PK. Gerador `GEN_PROPRIEDADE_ID` |

> **Única coluna do banco com `CHARACTER SET NONE`** — bytes crus, sem interpretação.
> Contém acentuação real (`SÃO BENTO`). Na migração precisa ser lida explicitamente como
> WIN1252, ou vira lixo.

Note que a ordem das colunas está invertida em relação às demais tabelas: a descrição vem
antes da chave. Indício de que a coluna foi recriada em algum momento.

---

## Generators

| Generator | Valor | Tabela | Máximo atual |
|---|---|---|---|
| `GEN_REGISTRO_DE_GASTOS_ID` | 22.258 | REGISTRO_DE_GASTOS | 22.258 |
| `GEN_CADASTRO_NF_ID` | 1.174 | CADASTRO_NF | 1.174 |
| `GEN_ITEM_NF_ID` | 2.594 | ITEM_NF | 2.594 |
| `GEN_SAIDA_PRODUTO_ID` | 2.357 | SAIDA_PRODUTO | 2.356 |
| `GEN_TIPO_PRODUTO_ID` | 67 | TIPO_PRODUTO | 67 |
| `GEN_PRODUTO_ID` | 1.335 | PRODUTO | 1.335 |
| `GEN_MOVIMENTACAO_PRODUTO_ID` | 1.923 | MOVIMENTACAO_PRODUTO | **0 (vazia)** |
| `GEN_FORNECEDOR_ID` | 186 | FORNECEDOR | 186 |
| `GEN_SUBCATEGORIA_ID` | 318 | SUBCATEGORIA | 318 |
| `GEN_CATEGORIA_ID` | 41 | CATEGORIA | 41 |
| `GEN_CONTAS_ID` | 18 | CONTAS | 18 |
| `GEN_FORMA_DE_PAGAMENTO_ID` | 14 | FORMA_DE_PAGAMENTO | 14 |
| `GEN_DESTINO_ID` | 86 | DESTINO | 86 |
| `GEN_PROPRIEDADE_ID` | 17 | PROPRIEDADE | 17 |
| `GEN_LOGIN_ID` | 7 | LOGIN | 7 |

Os máximos maiores que a contagem de linhas mostram exclusões ao longo do tempo — normal.

> **`GEN_CADASTRO_NF_ID` é usado por quatro tabelas** por causa de triggers erradas. Ver
> [triggers-e-procedures.md](triggers-e-procedures.md).

---

## Convenções observadas no schema

- Todas as PKs são `INTEGER` simples, alimentadas por generator via trigger `BEFORE INSERT`.
- O padrão de nome é `<TABELA>_ID`, com três exceções: `REGISTRO_DE_GASTOS` usa `GASTOS_ID`,
  `MOVIMENTACAO_PRODUTO` usa `MOVIMENTACAO_ID` e `PRODUTO.TIPO` é FK sem sufixo `_ID`.
- As colunas de FK em `REGISTRO_DE_GASTOS` **não** têm sufixo `_FK` no banco; os SELECTs da
  aplicação as renomeiam para `*_FK` na projeção, o que confunde na leitura do código.
- Valores monetários usam `NUMERIC/DECIMAL(15,2)` em todo lugar **exceto** nas três colunas
  `FLOAT` do módulo financeiro.
- Descrições são `VARCHAR` de tamanhos variados sem padrão (35, 40, 50, 100, 200).
- Nenhuma coluna tem valor padrão; nenhuma tem constraint de domínio.
