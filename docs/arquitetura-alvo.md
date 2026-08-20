# Arquitetura alvo

Proposta da Fase 4. As decisões que a sustentam estão registradas como ADRs:
[0005](decisoes/0005-estrategia-de-banco.md) banco,
[0006](decisoes/0006-dinheiro-em-decimal.md) dinheiro,
[0007](decisoes/0007-backend-dotnet.md) backend,
[0008](decisoes/0008-frontend-angular-electron.md) frontend.

---

## Visão geral

```
   DURANTE A CONVIVÊNCIA (Etapa 1)

   +---------------------+         +------------------------------+
   |  Legado Delphi VCL  |         |  Novo cliente (Electron)     |
   |  módulos ainda não  |         |  Angular - módulos migrados  |
   |  migrados           |         +--------------+---------------+
   +----------+----------+                        | HTTP + JSON
              | FireDAC                           v
              |                        +----------------------+
              |                        |  API - ASP.NET Core  |
              |                        |  regras de negócio   |
              |                        +----------+-----------+
              |                                   |
              +---------------+-------------------+
                              v
                  +-----------------------+
                  |  Firebird 2.5         |
                  |  MESMA BASE, ÚNICA    |
                  +-----------------------+
```

O ponto que define tudo: **uma única fonte de dados**. Não há sincronização, não há dois
bancos, não há conflito de replicação. Cada módulo migrado deixa de ser servido pelo Delphi e
passa a ser servido pela API, sobre a mesma tabela. Reverter um módulo é repontar a tela, não
migrar dados de volta.

Depois de desligado o legado, a caixa da esquerda desaparece e a decisão sobre PostgreSQL pode
ser tomada como corte único — ver [0005](decisoes/0005-estrategia-de-banco.md), Etapa 3.

---

## Camadas do backend

Quatro camadas, com dependências apontando sempre para dentro:

```
  Api            controllers, DTOs, autenticação, tratamento de erro
   |
   v
  Aplicacao      casos de uso: LancarDespesa, Parcelar, PagarEmLote, ImportarPlanilha
   |
   v
  Dominio        entidades, invariantes, tipos de valor (Dinheiro, Periodo)
   ^
   |
  Infraestrutura repositórios Firebird, leitura de planilha, geração de relatório
```

A camada de domínio não conhece banco, HTTP nem Firebird. É onde as regras hoje espalhadas em
eventos de formulário passam a viver — a mesma regra, num lugar só, testável sem interface.

**Por que isso importa aqui:** no legado, a regra de parcelamento existe dentro de um
`OnClick`. Não dá para testá-la sem abrir a tela, e não dá para reusá-la na importação em
lote. Separar não é cerimônia: é o que torna o teste de paridade possível.

### Estrutura proposta

```
  src/
    AgendaFinanceira.Dominio/          entidades e regras, sem dependência externa
    AgendaFinanceira.Aplicacao/        casos de uso, orquestração, transações
    AgendaFinanceira.Infraestrutura/   Firebird, planilhas, relatórios
    AgendaFinanceira.Api/              ASP.NET Core
  testes/
    AgendaFinanceira.Testes.Unidade/
    AgendaFinanceira.Testes.Paridade/  compara com o legado
  cliente/
    agenda-web/                        Angular
    agenda-desktop/                    empacotamento Electron
```

### Tipos de valor que o domínio precisa ter

**`Dinheiro`** — envolve um `decimal`, garante duas casas, proíbe construção a partir de
`double` e implementa `Dividir(n)` distribuindo o resto para que a soma das partes seja igual
ao todo. É o antídoto direto ao defeito central: o parcelamento do legado gera 12 parcelas de
R$ 1.666,666626 que somam R$ 19.999,9995.

**`Periodo`** — par de `DateOnly` com início e fim, validado. Toda consulta do sistema filtra
por período, e hoje cada tela monta o seu.

---

## Como a convivência funciona na prática

### Identificadores

A API insere em `REGISTRO_DE_GASTOS` **sem informar o identificador**, deixando a trigger
`REGISTRO_DE_GASTOS_BI` atribuí-lo a partir de `GEN_REGISTRO_DE_GASTOS_ID` — que está correto e
sincronizado. Como generator do Firebird é atômico, Delphi e API podem inserir ao mesmo tempo
sem risco de colisão.

Isso vale para todas as tabelas do módulo financeiro. O defeito dos generators compartilhados
atinge apenas as três tabelas do estoque, que não serão migradas.

### Autenticação durante a convivência

Problema: o Delphi lê `LOGIN` inteira e compara a senha em texto plano. Trocar as senhas por
hash quebraria o legado.

Solução de convivência: adicionar a coluna `SENHA_HASH` em `LOGIN`, que o Delphi ignora por não
a conhecer. A API autentica assim:

1. Se `SENHA_HASH` está preenchida, valida contra ela.
2. Se está vazia, valida contra `SENHA` em texto plano e **grava o hash** naquele momento.
3. Quando a senha é trocada pelo novo sistema, grava nas duas colunas — o hash para a API, o
   texto plano para o Delphi continuar funcionando.

Assim a base migra para hash sozinha, conforme as pessoas entram, sem quebrar o legado. Quando
o Delphi for desligado, a coluna `SENHA` é apagada.

Adicionar coluna é a única alteração de schema segura durante a convivência: os campos
persistentes do legado estão declarados nos `.dfm`, então uma coluna nova não o afeta. Ainda
assim, precisa ser verificada com o legado rodando antes de valer em produção.

### Autoria

A API grava `USERID` com o `LOGIN_ID` do usuário autenticado, igual ao legado — o carimbo
acontece na camada de persistência, não em cada endpoint, para que nenhum caminho de gravação
possa esquecer.

### Valores monetários

A API lê `FLOAT`, converte para `decimal` e arredonda para duas casas na borda; grava já
arredondado. Ver [0006](decisoes/0006-dinheiro-em-decimal.md).

### Concorrência

Firebird usa MVCC, e o padrão de uso real é favorável: uma operadora responde por 96% dos
lançamentos. Ainda assim, a API usa transação explícita por caso de uso — ao contrário do
legado, onde `AutoCommitUpdates = True` faz cada gravação confirmar isoladamente e o
parcelamento não é atômico.

---

## Contratos da API

Recorte inicial, cobrindo o módulo financeiro:

```
  POST   /sessao                        autenticar, devolve token
  GET    /lancamentos                   consulta com filtros e período
  POST   /lancamentos                   lançar despesa
  PUT    /lancamentos/{id}              alterar
  DELETE /lancamentos/{id}              excluir
  POST   /lancamentos/{id}/parcelar     gerar N parcelas
  POST   /lancamentos/pagar-em-lote     quitar um conjunto
  POST   /lancamentos/importar          carga por planilha
  GET    /lancamentos/vencimentos       o que vence hoje ou está vencido
  GET    /despesas                      categorias e subdespesas
  GET    /contas
  GET    /formas-pagamento
  GET    /relatorios/por-despesa        consolidado por subdespesa e período
```

Convenções: DTOs sempre, nunca entidade crua. Enums como texto. Datas de calendário no formato
`aaaa-mm-dd`, nunca instante com fuso. Erro devolvido com a razão real da recusa, para que o
cliente possa exibi-la sem reescrever.

---

## Testes de paridade

O objetivo é provar que o novo faz o mesmo que o legado. Há uma limitação honesta: **o legado é
uma interface Delphi e não é automatizável** — não há como dirigi-lo por script para comparar
respostas.

A saída é usar três oráculos, em ordem de força:

**1. Os dados de produção.** Três anos de operação são o resultado acumulado do legado. Os
relatórios do novo sistema, rodados sobre a mesma base, precisam reproduzir números conhecidos:
total pago de R$ 34.501.459,68, 13.972 lançamentos, os totais por despesa registrados em
[schema.md](schema.md). É o oráculo mais forte porque não depende de interpretação.

**2. O SQL do legado.** As consultas estão catalogadas em [fluxos.md](fluxos.md). Cada consulta
do novo sistema é comparada com a do legado executada sobre a mesma base, conferindo os
conjuntos de resultado linha a linha. Cobre bem toda a parte de leitura, que é a maioria do
sistema.

**3. A regra documentada.** Para escrita, o oráculo é a especificação em [dominio.md](dominio.md),
com os casos derivados dos defeitos conhecidos. Aqui a comparação é contra o comportamento
**esperado**, e as divergências intencionais precisam estar declaradas.

### Divergências que são correção, não defeito

Precisam constar do relatório de paridade, nunca ser silenciadas:

| Situação | Legado | Novo |
|---|---|---|
| Pagar em lote com item já pago na lista | congela em laço infinito | conclui normalmente |
| Parcelar R$ 20.000 em 12 | parcelas somam R$ 19.999,9995 | somam R$ 20.000,00 |
| Valor gravado acima de R$ 99.999,99 | perde precisão | correto até o limite da coluna |
| Alterar lançamento de outro usuário | permitido (verificação comentada) | recusado |
| Buscar cheque compensado maiúsculo | não acha os 9 gravados em minúscula | acha |
| Data de vencimento vazia | grava 30/12/1899 | grava ausência de data |
| Pago sem data de pagamento | possível (30 casos na base) | assume hoje |
| Pago com valor zerado | possível (24 casos na base) | assume o valor previsto |
| Descrição vazia | aceita (há uma categoria assim) | recusada |
| Travessão vindo do Excel | grava como está | normalizado para hífen |

### Comparação de valores

Sempre **valores, nunca contagens** — contar linhas não detecta valor trocado. Para dinheiro, a
comparação é contra o valor do legado **arredondado para duas casas**, com tolerância
declarada. Detalhes em `.claude/agents/qa-paridade.md`.

---

## O que muda em relação ao legado

| Aspecto | Legado | Novo |
|---|---|---|
| Camadas | formulário fala direto com o banco | domínio, aplicação, infraestrutura, API |
| Onde vive a regra | eventos de interface | camada de domínio, testável |
| Dinheiro | `FLOAT` (precisão simples) | `decimal` em todas as camadas |
| Transação | commit por gravação; parcelamento não atômico | transação por caso de uso |
| SQL | concatenação de string | sempre parametrizado |
| Autorização | menus escondidos na interface | verificada no servidor |
| Senha | texto plano, comparada no cliente | hash, verificada no servidor |
| Domínios (`PAGO`, status) | nenhuma garantia | constraint no banco e no servidor |
| Consulta por data | sem índice, varredura completa | índice em vencimento e pagamento |
| Backup | cópia de arquivo com banco aberto | `gbak`, verificado por restauração |
| Distribuição | executável copiado na rede | instalador Electron com atualização |

---

## Riscos e mitigações

**O provider Firebird para .NET pode ter limitação séria com a versão 2.5.** É a maior
incerteza técnica em aberto. Mitigação: spike antes de qualquer compromisso, e Dapper como
plano de partida por depender de menos coisa não verificada.

**Alterar o banco durante a convivência pode quebrar o legado.** Mitigação: só adicionar, nunca
alterar tipo nem remover; ensaiar em cópia; verificar com o Delphi rodando antes de aplicar.

**O sistema depende de uma pessoa que faz 96% dos lançamentos.** Qualquer mudança de fluxo ou
de atalho de teclado atinge diretamente a produtividade dela. Mitigação: preservar vocabulário,
atalhos e densidade da tela; validar cada módulo migrado com ela antes de considerar pronto.

**Firebird 2.5 sem correção de segurança.** Mitigação: rede local e Etapa 2 do
[0005](decisoes/0005-estrategia-de-banco.md). Se o banco for exposto para fora da rede local, a
atualização deixa de ser opcional.

**Escopo crescer durante a migração.** O legado tem funcionalidade morta — o teto por
subdespesa nunca foi usado em nenhuma das 148 subdespesas. Mitigação: paridade é com o que se
usa, não com o que existe; recursos mortos são confirmados com o cliente antes de migrar.

---

## Antes de escrever o primeiro código

As três verificações foram **executadas em 19/08/2026**:

1. ~~**Spike de acesso a dados.**~~ **Feito.** O caminho .NET → Firebird 2.5 está provado, e a
   decisão por Dapper está em [0009](decisoes/0009-acesso-a-dados-dapper-e-charset.md). Revelou
   também que o provider não aceita `WIN1252`. Código em `src/AgendaFinanceira.SpikeFirebird`.
2. ~~**Spike de convivência.**~~ **Feito.** `SENHA_HASH` adicionada numa cópia e o legado
   aberto contra ela chegou à tela de login sem exceção. Registrado em
   [0010](decisoes/0010-autenticacao-durante-a-convivencia.md).
3. ~~**Base de paridade.**~~ **Feita.** Congelada fora do repositório, com os números de
   referência em [paridade-referencia.md](paridade-referencia.md).

O caminho para a Etapa 2 do [roadmap](roadmap.md) está liberado.

O roadmap com ordem de módulos, critérios de pronto e validação por etapa é a Fase 5.
