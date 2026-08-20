# 0005 — Estratégia de banco: manter Firebird durante a convivência

- **Situação:** Aceita
- **Data:** 2026-08-19

## Contexto

A pergunta colocada era binária: manter o Firebird e construir a API sobre ele, ou migrar para
PostgreSQL com um plano de portabilidade seguro.

Os fatos que pesam:

- O banco tem **13.972 lançamentos**, R$ 34,5 milhões registrados, três anos de operação. É a
  única fonte desses dados.
- **Firebird 2.5 está fora de suporte.** Não recebe correção de segurança. A série atual é a 5.
- O banco roda em **rede local**, sem exposição à internet.
- O schema é simples: 15 tabelas, sem view, sem procedure, sem constraint `CHECK`, sem
  default. As 15 triggers só atribuem chave primária.
- Três colunas monetárias são `FLOAT` — ver [0006](0006-dinheiro-em-decimal.md).
- Três triggers usam o generator errado, e uma inserção sem ID explícito **falha hoje** com
  violação de chave primária. Comprovado em cópia.

E a restrição que decide tudo: a migração é **incremental, com o legado convivendo com o
novo** ([strangler pattern](../../CLAUDE.md#estado-da-migração)), até paridade total.

### Por que a convivência decide a escolha

O strangler pattern só funciona se os dois sistemas enxergarem **a mesma fonte de dados**.
Enquanto o Delphi e a nova aplicação estiverem os dois em produção, os dois vão ler e escrever
os mesmos lançamentos.

Se o novo sistema usar PostgreSQL desde o início, é preciso manter dois bancos sincronizados
**nos dois sentidos**, em tempo real, com dois sistemas escrevendo ao mesmo tempo. Isso traz
conflito de escrita concorrente, ordem de aplicação, geração de identificadores em duas
bases e transações que atravessam bancos diferentes. É a parte mais difícil de acertar em
qualquer migração, e o preço do erro aqui é dado financeiro corrompido em silêncio.

Trocar o banco no dia um não é migração incremental: é um big bang de dados escondido atrás de
uma migração incremental de telas. Perde-se justamente a propriedade que motivou o strangler.

## Decisão

A migração acontece em três tempos, e apenas o primeiro está autorizado agora.

### Etapa 1 — Construir sobre o Firebird atual (agora)

A nova API é construída sobre o Firebird 2.5 existente. Legado e novo compartilham a mesma
base, sem sincronização de espécie alguma. Cada módulo migrado passa a ler e escrever pela
API, enquanto os módulos ainda não migrados continuam no Delphi, na mesma tabela.

Nesta etapa, o banco recebe apenas correções **que não quebram o legado**:

- Correção dos três generators compartilhados, com ressincronização. Não altera schema nem
  tipo, então o Delphi não sente. **Não é bloqueante para a API do financeiro**: as três
  triggers defeituosas são de `ITEM_NF`, `SAIDA_PRODUTO` e `TIPO_PRODUTO`, todas do módulo de
  estoque, que não será migrado ([0004](0004-nao-migrar-estoque.md)). Os generators de
  `REGISTRO_DE_GASTOS`, `CATEGORIA`, `SUBCATEGORIA`, `CONTAS`, `FORMA_DE_PAGAMENTO` e `LOGIN`
  estão corretos e sincronizados com o máximo de suas tabelas. É higiene necessária antes de
  qualquer script tocar o estoque, não véspera do primeiro endpoint.
- Índices em `REGISTRO_DE_GASTOS (DATA_VENCIMENTO)` e `(DATA_PAGAMENTO)`. Índice é transparente
  para a aplicação e as consultas do legado passam a ser mais rápidas também.

O que **não** muda nesta etapa: os tipos das colunas. Alterar `VALOR_PREVISTO` de `FLOAT` para
`NUMERIC(15,2)` quebraria os campos persistentes `TSingleField` declarados nos `.dfm` do
legado, exigindo recompilar e reinstalar o Delphi — risco desnecessário enquanto ele ainda é o
sistema principal. A API trata a imprecisão na borda, conforme [0006](0006-dinheiro-em-decimal.md).

### Etapa 2 — Atualizar o Firebird (quando conveniente)

Atualizar de Firebird 2.5 para a série 5, o que resolve o problema de suporte **sem trocar de
SGBD**. É um upgrade dentro da mesma família, feito por backup e restore com `gbak`, e o
legado continua funcionando pelo FireDAC.

Esta etapa é independente da migração da aplicação e pode acontecer a qualquer momento entre a
1 e a 3. Precisa de ensaio em cópia e de verificação do comportamento do legado antes de valer
em produção.

### Etapa 3 — Avaliar PostgreSQL (depois de desligar o legado)

Com o Delphi desligado, existe um único sistema escrevendo, e a migração para PostgreSQL vira
um **corte único com janela de manutenção** — não uma convivência bidirecional. Aí sim ela é
segura, e a decisão de fazê-la ou não pode ser tomada com informação que hoje não temos.

Essa avaliação terá ADR próprio. O plano de portabilidade abaixo fica registrado desde já,
porque foi levantado agora e envelhece bem.

## Plano de portabilidade para PostgreSQL (para a Etapa 3)

**Mapeamento de tipos**

| Firebird | PostgreSQL | Observação |
|---|---|---|
| `INTEGER` | `integer` | direto |
| `VARCHAR(n)` WIN1252 | `varchar(n)` UTF-8 | exige transliteração explícita |
| `CHAR(1)` | `char(1)` | normalizar `'s'` para `'S'` antes |
| `DATE` | `date` | data de calendário, nunca `timestamptz` |
| `NUMERIC/DECIMAL(15,2)` | `numeric(15,2)` | direto |
| **`FLOAT`** | **`numeric(15,2)`** | **com arredondamento explícito e validado** |

**Charset.** O banco é WIN1252 e a conexão FireDAC não declara charset. `PROPRIEDADE.DESCRICAO`
é `CHARACTER SET NONE` e contém acentuação real. A conversão precisa ler essa coluna
explicitamente como WIN1252; sem isso, vira lixo em silêncio.

**Generators → sequences.** Cada generator vira uma sequence, posicionada com
`setval(MAX(id))` da tabela correspondente — não com o valor atual do generator, que em três
casos está errado. As triggers `BEFORE INSERT` deixam de existir: identidade passa a ser
responsabilidade da coluna.

**Regras.** O que hoje não existe no banco passa a existir: `CHECK` para `PAGO`,
`SITUACAO_STATUS`, `CHEQUE_COMPENSADO`, `NIVEL`, e não-negatividade dos valores. Só depois de
os dados serem saneados, senão a carga falha.

**Validação registro a registro.** Comparar **valores, não contagens** — contar linhas não
detecta valor trocado. No mínimo: todos os campos de todos os lançamentos comparados um a um;
somas por despesa, por conta e por mês conferidas dos dois lados; e conferência explícita dos
471 lançamentos com valor impreciso e dos 30 acima do limite de precisão do `FLOAT`.

**Reversão.** O Firebird permanece intacto e em modo somente leitura durante toda a janela.
Reverter é repontar a aplicação de volta para ele. A janela só é declarada encerrada depois da
validação completa, não depois da carga.

## Consequências

**Mais fácil:** a convivência do strangler passa a ser trivial — não há sincronização, não há
dois bancos, não há conflito. Cada módulo pode ser migrado e revertido isoladamente. O risco
para os dados na Etapa 1 é próximo de zero, porque o dado não se move.

**Mais difícil:** trabalhar sobre um banco fora de suporte por mais tempo, e conviver com as
colunas `FLOAT` durante a convivência, tratando a imprecisão na borda da API em vez de
resolvê-la na raiz. O ferramental .NET para Firebird é menos maduro que o de PostgreSQL — ver
[0007](0007-backend-dotnet.md).

**Passa a ser obrigatório:** toda alteração no banco legado durante a Etapa 1 precisa ser
verificada contra o Delphi antes de valer em produção, porque os dois compartilham a base.

**Fica registrado como risco aceito:** Firebird 2.5 sem correções de segurança, mitigado por
estar em rede local e pela Etapa 2. Se o banco vier a ser exposto para fora da rede local, a
Etapa 2 deixa de ser opcional e passa a ser urgente.
