# Fluxos funcionais ponta a ponta

Cada fluxo descreve o caminho completo: o que o operador faz, o que o sistema executa, quais
tabelas são tocadas e onde estão os pontos frágeis.

Serve como roteiro para os **testes de paridade**: o comportamento novo precisa reproduzir
exatamente estes passos.

---

## 1. Entrar no sistema

```
Abrir o executável
  -> lê config.ini ao lado do exe (Server, User, Password, Database)
  -> conecta ao Firebird
     falha -> mensagem com o erro técnico + encerra o programa
  -> abre SELECT * FROM LOGIN  (a tabela inteira vai para a estação)
  -> tela de login
       digita o nome -> ao sair do campo, procura na lista carregada
                        não achou -> avisa e limpa o campo
       digita a senha -> compara texto contra texto
                        errou -> avisa e ENCERRA o programa
  -> aplica o nível: esconde menus conforme 1, 2 ou 3
  -> se LOGIN_ID <> 1: esconde backup e desliga o backup automático
  -> conta vencimentos: DATA_VENCIMENTO <= hoje AND PAGO = 0
       havendo algum -> mostra "Há N despesa(s) a pagar"
```

**Tabelas:** `LOGIN` (leitura completa), `REGISTRO_DE_GASTOS` (contagem).

**Frágil:** senha em texto plano comparada no cliente; a tabela de usuários inteira, com todas
as senhas, trafega a cada abertura. Falha de senha derruba o programa em vez de permitir nova
tentativa.

> `UfrmPrincipal.pas:156-186`, `Ulogin.pas:79-123`, `UfrmPrincipal.pas:114-126`

---

## 2. Lançar uma despesa

```
Menu Movimentação > Lançamentos
  -> se há vencimentos pendentes, abre na aba de consulta; senão, na de cadastro
  -> botão Novo
       habilita os campos, posiciona o foco na descrição
       preenche as datas com hoje
       coloca o dataset em modo inserção
  -> operador preenche descrição, valor previsto, datas
  -> duplo clique (ou Enter) na busca de subdespesa
       -> abre o seletor com SUBCATEGORIA + CATEGORIA
       -> escolhe uma -> preenche subdespesa E despesa juntas
  -> escolhe a conta e a forma de pagamento nas listas
  -> opcionalmente marca "confirmar pagamento" -> revela data e valor pago
  -> botão Salvar
       valida: descrição, valor previsto, subdespesa e conta preenchidos
               algum vazio -> avisa e não grava
       grava CONTA_FK e FORMA_DE_PAGAMENTO_FK da posição atual das listas
       grava USERID = usuário logado
       grava DATA_CADASTRO = agora
       cheque compensado vazio -> 'N'
       confirmou pagamento -> DATA_PAGAMENTO informada, PAGO = 1
       não confirmou       -> PAGO = 0, VALOR_PAGO = 0
       Post  (commit imediato, por AutoCommitUpdates)
       recarrega os datasets e refaz a pesquisa
       atualiza o aviso de vencimentos na tela principal
```

**Tabelas:** `REGISTRO_DE_GASTOS` (inserção), `CATEGORIA`, `SUBCATEGORIA`, `CONTAS`,
`FORMA_DE_PAGAMENTO`, `LOGIN` (leitura).

**Triggers:** `REGISTRO_DE_GASTOS_BI` não age — o FireDAC já forneceu o ID.

**Frágil:** conta e forma de pagamento vêm da *posição do cursor* na lista, não de uma
seleção explícita; se o dataset for reposicionado por outro caminho, grava o registro errado.

> `UfrmLancamentos.pas:732-790`

---

## 3. Parcelar um lançamento

```
Seleciona o lançamento na grade
  -> botão Gerar Parcelas -> confirma
  -> informa a quantidade N
  -> calcula valor da parcela = VALOR_PREVISTO / N
  -> tela "Serão geradas N parcelas de R$ X" -> confirma ou aborta
  -> guarda todos os campos do original em variáveis
  -> repete N vezes:
       insere cópia do original
       descrição = "DESCRIÇÃO i/N"
       observação = "Gerada automaticamente pelo parcelamento"
       vencimento = vencimento original deslocado de (i-1) meses
       valor previsto = VALOR_PREVISTO / N
       Post                      <- commit individual
  -> marca Parcelando = SIM
  -> exclui o lançamento original
       -> a NF vinculada volta a NF_LANCADA = 'SIM'
  -> recarrega
```

**Tabelas:** `REGISTRO_DE_GASTOS` (N inserções + 1 exclusão), `CADASTRO_NF` (atualização).

**Frágil — três problemas sérios:**

1. **Não é atômico.** Cada `Post` confirma sozinho. Falha na metade deixa parcelas gravadas e
   o original ainda presente.
2. **Divisão sem tratar dízima.** R$ 20.000,00 ÷ 12 grava R$ 1.666,666626 em cada parcela;
   somadas dão R$ 19.999,9995. Já há 200 parcelas assim na base.
3. **Variáveis não inicializadas.** Cheque, nota fiscal e entrada só são lidas se não forem
   nulas, mas são copiadas incondicionalmente — quando o original tem esses campos nulos,
   grava lixo de memória.

Na nova stack este fluxo precisa ser **uma transação única**, com a **última parcela
absorvendo a diferença** do arredondamento.

> `UfrmLancamentos.pas:1257-1359`

---

## 4. Pagar em lote

```
Marca "pagar todas" -> revela o botão
  -> botão Pagar em Lote
  -> confirma ("Todos os dados exibidos serão pagos. Esta operação é irreversível.")
  -> vai para o primeiro registro
  -> para cada registro da grade:
       se PAGO = 0:
         DATA_PAGAMENTO = hoje
         PAGO = 1
         VALOR_PAGO = VALOR_PREVISTO
         Post
         avança                   <- o avanço está DENTRO do "se"
  -> commit
  -> recarrega e atualiza o aviso de vencimentos
```

**Tabelas:** `REGISTRO_DE_GASTOS` (atualização em massa).

**Frágil — defeito crítico:** o avanço para o próximo registro está dentro da condição. Um
único registro já pago na grade faz o laço rodar para sempre e **a aplicação congela**. Como o
filtro "todos" é comum, o cenário é plausível no uso diário.

> `UfrmLancamentos.pas:416-447`

---

## 5. Importar pagamentos de planilha

```
Tela de Lançamentos > botão de planilha (só nível 3)
  -> escolhe o arquivo .xls/.xlsx
  -> botão Carregar
       abre o Excel por automação OLE
       lê a aba de nome fixo "Planilha1", a partir da linha 2
       para cada linha:
         tem data?  sim -> novo registro: data, descrição (MAIÚSCULA, sem acento), valor
                    não -> anexa a descrição ao registro anterior com " - "
       fecha o Excel
       mostra a quantidade importada
  -> escolhe despesa/subdespesa (uma para todo o lote)
  -> escolhe conta e forma de pagamento (uma para todo o lote)
  -> botão Salvar -> confirma
       para cada linha do lote:
         resolve CONTA_ID e FORMA_DE_PAGAMENTO_ID pela descrição escolhida
         VALOR_PREVISTO = VALOR_PAGO = valor da planilha
         DATA_VENCIMENTO = DATA_PAGAMENTO = data da planilha
         DATA_CADASTRO = agora
         PAGO = 1                    <- entra sempre como pago
         CHEQUE = 0, NOTA_FISCAL = 0, ENTRADA_ID = 0, CHEQUE_COMPENSADO = 'N'
         USERID = usuário logado
         Post
       commit -> "Lote cadastrado com sucesso!"
  -> fecha a tela (e fecha também a de lançamentos)
```

**Tabelas:** `REGISTRO_DE_GASTOS` (inserção em massa), `CONTAS`, `FORMA_DE_PAGAMENTO`,
`SUBCATEGORIA`, `CATEGORIA` (leitura).

**Frágil:** nome de aba fixo; se a planilha usar outro nome, falha. Uma consulta ao banco é
executada por linha para resolver conta e forma de pagamento, sempre com o mesmo resultado.
E o lote inteiro é gravado com commits individuais.

> Este fluxo é a explicação dos 10.481 lançamentos com pagamento anterior ao cadastro — é o
> comportamento esperado, não um defeito.

> `UfrmLancamentosEmLote.pas:114-190`, `UfrmLancamentosEmLote.pas:374-465`

### O que o sistema novo faz diferente aqui

A regra do legado — *"linha sem data anexa a descrição à anterior"* — **descarta dinheiro em
silêncio** quando a planilha é um extrato bancário. Extrato não repete a data dentro do mesmo
dia, então a segunda compra do dia chega sem data, com valor. Pela regra do legado essa linha
vira apenas um pedaço de texto colado na descrição de cima, e **o valor dela some sem aviso**.

Medido no extrato real de junho/2025 (`conta raul junho.xlsx`, 179 débitos, R$ 348.271,89):
duas linhas cairiam nesse buraco, R$ 1.542,73 e R$ 90,00.

O leitor novo:

| Situação na planilha | Legado | Sistema novo |
|---|---|---|
| Título e cabeçalho no alto | erro (espera dados na linha 2) | pulados até a primeira data legível |
| Sem data, **com** valor | valor descartado calado | herda a data da linha anterior |
| Sem data, sem valor, só texto | anexa à descrição anterior | igual |
| Valor terminado em `C` (crédito) | vira despesa | fica de fora, e a prévia diz quantas |
| Sem descrição | grava em branco | a prévia pede o texto, e ele vai na gravação |
| Data ilegível no meio dos dados | pula | recusa o lote apontando a linha |

A prévia informa cada uma dessas decisões por extenso. Quem descarta em silêncio some com
dado sem ninguém ver — e foi exatamente isso que aconteceu no legado.

---

## 6. Consultar lançamentos

```
Aba de consulta
  -> escolhe o período (padrão: últimos 6 meses até hoje)
  -> opcionalmente filtra por subdespesa (abre o seletor)
  -> opcionalmente filtra por conta (abre o cadastro em modo pesquisa)
  -> escolhe a situação: Pago / Não Pago / (TODOS)
  -> escolhe o tipo de busca e digita o termo:
       Descrição         -> LIKE sobre DESCRICAO,        período por DATA_VENCIMENTO
       Nota fiscal       -> igualdade sobre NOTA_FISCAL, período por DATA_CADASTRO,
                            e força o início em 01/01/2018
       Cheque/documento  -> LIKE sobre CHEQUE,           período por DATA_VENCIMENTO
       Status            -> LIKE sobre SITUACAO_STATUS,  período por DATA_CADASTRO
       Cheque compensado -> LIKE sobre CHEQUE_COMPENSADO, IGNORA o período
       Faixa de valor    -> BETWEEN sobre VALOR_PREVISTO (período por vencimento)
                                     ou VALOR_PAGO       (período por PAGAMENTO)
  -> monta o SQL concatenando os filtros escolhidos
  -> executa e recalcula os totais do rodapé
```

**Tabelas:** `REGISTRO_DE_GASTOS` + as quatro de apoio, sempre na mesma junção.

**Frágil:** o SQL é montado por concatenação; os textos passam por `QuotedStr`, mas número de
NF e faixas de valor são convertidos sem validação — entrada não numérica gera exceção. A
busca por cheque compensado é sensível a maiúsculas, e há 9 registros com `'s'` minúsculo que
nunca aparecem. Sem índice em data, cada consulta varre a tabela inteira.

> `UfrmLancamentos.pas:903-1120`

---

## 7. Alterar um lançamento

```
Seleciona na grade -> botão Alterar
  -> [a checagem de permissão está COMENTADA aqui]
  -> marca a NF vinculada como NF_LANCADA = 'NÃO'
  -> coloca o dataset em edição
  -> repovoa os campos não ligados ao datasource:
       data prevista, valor previsto, texto da subdespesa,
       data de pagamento, conta e forma de pagamento
  -> marca "confirmar pagamento" conforme PAGO
  -> desabilita a grade
  -> operador altera e salva (mesmo caminho do fluxo 2)
```

Existe um segundo caminho de entrada: na consulta por despesa, o duplo clique no detalhe leva
direto para cá, recarregando o lançamento pelo `GASTOS_ID`.

**Frágil:** a regra "só quem lançou pode alterar" existe e funciona no Excluir, mas está
comentada no Alterar. Hoje qualquer usuário edita o lançamento de qualquer outro.

> `UfrmLancamentos.pas:606-631`, `UfrmLancamentos.pas:1203-1212`,
> `UfrmLancamentos.pas:1728-1763`

---

## 8. Excluir um lançamento

```
Seleciona na grade -> botão Excluir
  -> verifica permissão:
       não é o usuário 1 e não é o autor
         -> busca o nome do autor e recusa: "Fale com o(a) User X para continuar"
  -> confirma
  -> marca a NF vinculada como NF_LANCADA = 'NÃO'
  -> Delete
       falhou -> mostra "Impossível excluir este lançamento em razão do motivo: ..."
  -> commit
```

**Frágil:** o commit acontece fora do bloco de confirmação e mesmo quando a exclusão falha.

> `UfrmLancamentos.pas:555-580`

---

## 9. Consultar gastos por despesa

```
Tela de Lançamentos > Buscar Categoria
  -> escolhe a despesa numa lista auxiliar
  -> informa o período
  -> escolhe o modo:
       Pago     -> filtra por DATA_PAGAMENTO,  PAGO = 1
       Não pago -> filtra por DATA_VENCIMENTO, PAGO = 0
  -> consolida por subdespesa: SUM(valor_pago), SUM(valor_previsto)
  -> duplo clique numa subdespesa -> detalha os lançamentos daquela subdespesa
  -> duplo clique num lançamento  -> abre o lançamento em modo alteração (fluxo 7)
  -> impressão: relatorioDespesa.fr3 (consolidado)
                RelatorioSubdespesaDetalhado.fr3 (detalhado)
```

A troca da coluna de data entre os dois modos é a regra central: *quanto gastei* olha quando o
dinheiro saiu; *quanto devo* olha quando vence.

> `UpesquisaCategoria.pas:105-142`, `UpesquisaCategoria.pas:190-268`

---

## 10. Emitir relatórios

Todos seguem o mesmo padrão: carregam o `.fr3` da pasta do executável, injetam variáveis de
período e exibem em tela, de onde o operador imprime ou exporta em PDF.

| Relatório | Arquivo | Origem dos dados |
|---|---|---|
| Lançamentos do período | `Lançamento.fr3` | consulta da aba de período |
| Lançamentos da consulta | `LancamentoConsulta.fr3` | consulta da aba de busca |
| Consolidado por despesa | `relatorioDespesa.fr3` | consulta por despesa |
| Subdespesa detalhado | `RelatorioSubdespesaDetalhado.fr3` | detalhe da subdespesa |
| Nota fiscal | `RelatorioCadastroNF.fr3` | entrada de NF (módulo inativo) |
| Saídas de produto | `RelatorioSaida.fr3` | saída de produtos (módulo inativo) |

**Frágil:** o caminho é sempre relativo ao executável. Rodar o `.exe` de outro diretório faz
os relatórios não serem encontrados.

---

## 11. Exportar para Excel

```
Botão de exportação na tela de lançamentos
  -> se não há dados, avisa e sai
  -> cria uma instância do Excel por automação OLE
  -> desliga atualização de tela e alertas
  -> escreve o cabeçalho com as colunas fixas
  -> para cada registro:
       valores monetários -> arredonda para 2 casas, formata "[$R$-416] #,##0.00"
       demais             -> texto
       acumula os totais e atualiza a barra de progresso
  -> escreve a linha TOTAL
  -> ajusta a largura das colunas
  -> exibe o Excel para o operador
  -> libera as referências
```

Colunas exportadas: descrição, valor pago, valor previsto, nota fiscal, cheque, data de
vencimento, data de pagamento, conta.

**Frágil:** o arredondamento acontece só na exportação; os valores no banco continuam
imprecisos. A planilha e a tela podem divergir do banco.

> `UfrmLancamentos.pas:1591-1726`

---

## 12. Backup

```
Automático (só usuário 1):
  temporizador -> CopyFile('Y:\Dados\DADOS_12_23.FDB',
                           'C:\Users\Usuario\Desktop\Novo sistema\DADOS_12_23.FDB')
                  falhou -> "Erro ao fazer backup"

Manual:
  Menu BackUp -> escolhe origem e destino -> CopyFile -> avisa o resultado
```

**Frágil:** os dois copiam o arquivo do banco enquanto ele pode estar aberto, o que produz
cópia potencialmente inconsistente. Os caminhos do automático estão fixos no código. Os
componentes `TFDIBBackup` existem no formulário mas nunca são usados.

O backup correto é `gbak`, que produz uma cópia consistente com o banco em uso — ver os
comandos no [CLAUDE.md](../CLAUDE.md#comandos-úteis).

> `UfrmPrincipal.pas:390-406`, `UbackUp.pas:43-54`

---

## Fluxos do módulo inativo

Registrados apenas para referência histórica; o cliente decidiu não migrar o estoque.

**Entrada de nota fiscal:** cadastra o cabeçalho (fornecedor, datas, número, observação),
nasce como `NF ABERTA`; adiciona itens por uma coluna-botão na grade; o valor da nota é a soma
dos itens; ao processar, pergunta se atualiza o preço dos produtos e muda o status para
`PROCESSADA`; notas já vinculadas a um lançamento financeiro não podem ser excluídas.

**Saída de produto:** registra destino, propriedade, produto e quantidade; calcula o valor
como quantidade × preço.

Em ambos, **a atualização de saldo e o registro de movimentação estão comentados**.
