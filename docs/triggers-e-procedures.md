# Triggers, procedures e generators

## Resumo

O banco tem **15 triggers, 15 generators, nenhuma stored procedure e nenhuma view**.

Todas as triggers fazem exatamente a mesma coisa: atribuir a chave primária a partir de um
generator quando ela chega nula. **Nenhuma trigger dispara regra de negócio** — nenhuma
valida, calcula, replica ou audita.

Isso é a informação mais importante deste documento: na migração, **não há lógica escondida no
banco para descobrir**. Tudo o que o sistema faz está no código Delphi, documentado em
[dominio.md](dominio.md).

---

## O padrão

Toda trigger segue esta forma:

```sql
CREATE TRIGGER <TABELA>_BI FOR <TABELA>
ACTIVE BEFORE INSERT POSITION 0
as
begin
  if (new.<coluna_id> is null) then
    new.<coluna_id> = gen_id(<GENERATOR>, 1);
end
```

A condição `is null` importa: quando a aplicação fornece o ID — e o FireDAC sempre fornece,
via `UpdateOptions.GeneratorName` — **a trigger não faz nada**. Ela só age em inserções que
deixam a chave em branco.

Esse detalhe é o que mantém o defeito abaixo adormecido.

---

## Defeito: três triggers usam o generator errado

| Trigger | Generator que usa | Generator correto |
|---|---|---|
| `ITEM_NF_BI` | ❌ `GEN_CADASTRO_NF_ID` | `GEN_ITEM_NF_ID` |
| `SAIDA_PRODUTO_BI` | ❌ `GEN_CADASTRO_NF_ID` | `GEN_SAIDA_PRODUTO_ID` |
| `TIPO_PRODUTO_BI` | ❌ `GEN_CADASTRO_NF_ID` | `GEN_TIPO_PRODUTO_ID` |

Quatro tabelas compartilham `GEN_CADASTRO_NF_ID`. Provável erro de copiar e colar ao criar as
triggers.

### Por que ainda não quebrou

O FireDAC busca o próximo ID no generator **correto** antes de inserir, então a chave nunca
chega nula e a trigger nunca age. O sistema funciona por acidente feliz.

### Por que vai quebrar

O generator compartilhado ficou muito atrás dos máximos reais:

```
GEN_CADASTRO_NF_ID   = 1.174    ->  próximo valor: 1.175
MAX(ITEM_NF_ID)      = 2.594
MAX(SAIDA_PRODUTO_ID)= 2.356
```

Ou seja, o ID que a trigger geraria **já existe** há mais de mil registros.

### Comprovação

Teste executado na cópia de trabalho, inserindo em `ITEM_NF` sem informar a chave:

```sql
INSERT INTO ITEM_NF (NF_ID, PRODUTO_ID, VALOR_ITEM, QTDE_ITEM, VALOR_TOTAL_ITEM)
  VALUES (1, 1, 1.00, 1, 1.00);
```

```
Statement failed, SQLSTATE = 23000
violation of PRIMARY or UNIQUE KEY constraint "PK_ITEM_NF" on table "ITEM_NF"
-Problematic key value is ("ITEM_NF_ID" = 1175)
```

### Consequência para a migração

Qualquer escrita que não venha do Delphi falha na primeira tentativa: um script de correção,
uma carga de dados, uma ferramenta de administração — e, principalmente, **a API que será
construída**.

Corrigir é pré-requisito, e envolve dois passos que precisam andar juntos:

1. Apontar cada trigger para o seu próprio generator.
2. Ressincronizar os generators com `SELECT MAX(...)` de cada tabela antes de liberar escrita.

Fazer só o passo 1 troca uma colisão por outra. Fazer só o passo 2 não resolve nada.

> Como esta é uma alteração de DDL no banco legado, ela precisa de ADR próprio e só pode ser
> aplicada sobre cópia até validação. Ver [decisoes/](decisoes/).

---

## Inventário completo das triggers

Todas são `ACTIVE BEFORE INSERT POSITION 0`.

| Trigger | Tabela | Coluna | Generator | Correto? |
|---|---|---|---|---|
| `CADASTRO_NF_BI` | CADASTRO_NF | `CADASTRO_NF_ID` | `GEN_CADASTRO_NF_ID` | ✅ |
| `CATEGORIA_BI` | CATEGORIA | `CATEGORIA_ID` | `GEN_CATEGORIA_ID` | ✅ |
| `CONTAS_BI` | CONTAS | `CONTA_ID` | `GEN_CONTAS_ID` | ✅ |
| `DESTINO_BI` | DESTINO | `DESTINO_ID` | `GEN_DESTINO_ID` | ✅ |
| `FORMA_DE_PAGAMENTO_BI` | FORMA_DE_PAGAMENTO | `FORMA_DE_PAGAMENTO_ID` | `GEN_FORMA_DE_PAGAMENTO_ID` | ✅ |
| `FORNECEDOR_BI` | FORNECEDOR | `FORNECEDOR_ID` | `GEN_FORNECEDOR_ID` | ✅ |
| `ITEM_NF_BI` | ITEM_NF | `ITEM_NF_ID` | `GEN_CADASTRO_NF_ID` | ❌ |
| `LOGIN_BI` | LOGIN | `LOGIN_ID` | `GEN_LOGIN_ID` | ✅ |
| `MOVIMENTACAO_PRODUTO_BI` | MOVIMENTACAO_PRODUTO | `MOVIMENTACAO_ID` | `GEN_MOVIMENTACAO_PRODUTO_ID` | ✅ |
| `PRODUTO_BI` | PRODUTO | `PRODUTO_ID` | `GEN_PRODUTO_ID` | ✅ |
| `PROPRIEDADE_BI` | PROPRIEDADE | `PROPRIEDADE_ID` | `GEN_PROPRIEDADE_ID` | ✅ |
| `REGISTRO_DE_GASTOS_BI` | REGISTRO_DE_GASTOS | `GASTOS_ID` | `GEN_REGISTRO_DE_GASTOS_ID` | ✅ |
| `SAIDA_PRODUTO_BI` | SAIDA_PRODUTO | `SAIDA_PRODUTO_ID` | `GEN_CADASTRO_NF_ID` | ❌ |
| `SUBCATEGORIA_BI` | SUBCATEGORIA | `SUBCATEGORIA_ID` | `GEN_SUBCATEGORIA_ID` | ✅ |
| `TIPO_PRODUTO_BI` | TIPO_PRODUTO | `TIPO_PRODUTO_ID` | `GEN_CADASTRO_NF_ID` | ❌ |

---

## Stored procedures

**Nenhuma.** O único SQL do sistema são os `SELECT`, `INSERT`, `UPDATE` e `DELETE` gerados pelo
FireDAC ou montados por concatenação de string no Delphi.

Consequência prática: não existe uma "API do banco". Qualquer cliente novo precisa reimplementar
as consultas — e as consultas do legado estão catalogadas em [fluxos.md](fluxos.md).

---

## Views

**Nenhuma.** Todas as junções são montadas na aplicação, no estilo antigo (tabelas separadas
por vírgula no `FROM`, condições de junção no `WHERE`).

A junção mais repetida do sistema aparece **oito vezes** no código, sempre igual:

```sql
from REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP
where (REG.CATEGORIA_ID = C.CATEGORIA_ID)
  and (REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID)
  and (REG.CONTA_ID = CT.CONTA_ID)
  and (REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID)
```

Essa é a definição natural de uma view de lançamento completo, e é o primeiro candidato a
virar uma projeção única na nova stack.

---

## Domains, constraints e defaults

**Nenhum.** Não há domain de usuário, constraint `CHECK` ou valor padrão de coluna em todo o
banco.

Isso significa que colunas com domínio conceitual bem definido não têm nenhuma garantia:

| Coluna | Domínio pretendido | O que o banco aceita |
|---|---|---|
| `REGISTRO_DE_GASTOS.PAGO` | 0 ou 1 | qualquer inteiro, inclusive nulo |
| `REGISTRO_DE_GASTOS.CHEQUE_COMPENSADO` | `'N'` ou `'S'` | qualquer caractere. Há 9 com `'s'` |
| `REGISTRO_DE_GASTOS.SITUACAO_STATUS` | `AGUARDANDO` ou `LIBERADA` | qualquer texto de 10 |
| `CADASTRO_NF.STATUS` | `NF ABERTA` ou `PROCESSADA` | qualquer texto de 10 |
| `CADASTRO_NF.NF_LANCADA` | `SIM`, `NÃO`, `AJU` | qualquer texto de 3 |
| `LOGIN.NIVEL` | 1, 2 ou 3 | qualquer inteiro |
| valores monetários | ≥ 0 | negativos livremente |

Nenhuma dessas regras é imposta em lugar nenhum além da interface. Na nova stack, elas devem
existir **no banco e no servidor**, não apenas no formulário.

---

## Índices

Apenas os criados automaticamente por PK e FK. **Não existe um único índice em coluna de
data**, embora praticamente toda consulta do sistema filtre por `DATA_VENCIMENTO`,
`DATA_PAGAMENTO` ou `DATA_CADASTRO` sobre 13.972 registros.

Índices por tabela: REGISTRO_DE_GASTOS 6, SAIDA_PRODUTO 4, ITEM_NF 3, CADASTRO_NF 2,
MOVIMENTACAO_PRODUTO 2, PRODUTO 2, SUBCATEGORIA 2, demais 1.

Melhoria de baixo risco e efeito imediato, aplicável **antes mesmo da migração**: índices em
`REGISTRO_DE_GASTOS (DATA_VENCIMENTO)` e `(DATA_PAGAMENTO)`. Precisa de medição antes e depois
para comprovar o ganho.
