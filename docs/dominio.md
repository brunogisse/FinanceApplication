# Domínio e regras de negócio

Regras extraídas do código Delphi, escritas em linguagem de negócio. **Nenhuma delas está no
banco** — todas vivem em eventos de interface, e é por isso que precisam ser documentadas
antes da migração.

Cada regra traz a origem no código para conferência.

---

## Conceitos

**Despesa** (`CATEGORIA`) — o nível mais alto de classificação. Na prática funciona como
centro de custo: AGRICOLA, CASA RAUL, PETROTORQUE, ESCRITORIO, VEICULOS, CHACARA, DESTILARIA,
IMPOSTOS, DUBAI, BASE JC, COMPRAS E FINANCIAMENTOS, DOCE E CANA, DESPESAS.

**Subdespesa** (`SUBCATEGORIA`) — detalha uma Despesa. São 148, e sempre pertencem a
exatamente uma Despesa.

**Conta** (`CONTAS`) — de onde o dinheiro sai. Mistura bancos e pessoas: ALAMO SA, CEDRO,
DINHEIRO, ELISA, GABRIEL, JC REPRESENTAÇÃO -BRADESCO, LESSIA, PETROTORQUE, RAQUEL,
RAUL/GABRIEL, RAUL/LESSIA e outras.

**Forma de Pagamento** (`FORMA_DE_PAGAMENTO`) — como o dinheiro sai: TED/ PIX, CHEQUE,
DINHEIRO, CARTAO DE CREDITO, CARTAO DE DEBITO, DEPOSITO, SAQUE, DEBITO BANCO,
CHEQUE/DEPOSITO, APLICATIVO.

**Lançamento** (`REGISTRO_DE_GASTOS`) — uma despesa a pagar ou já paga. É o coração do
sistema.

---

## Módulo: Acesso e permissões

### Autenticação

O usuário digita o nome, o sistema procura na lista de usuários e, ao sair do campo, avisa se
não encontrou. A senha é comparada em seguida.

- A comparação de nome **ignora maiúsculas e minúsculas**.
- A comparação de senha é **exata**, texto contra texto.
- **Senha errada fecha o programa.** Não há segunda tentativa.
- Fechar a tela de login sem autenticar também fecha o programa.

> `Ulogin.pas:79-108`, `Ulogin.pas:110-123`

### Níveis de acesso

| Nível | O que pode |
|---|---|
| 1 | Apenas consultar. Perde os menus Cadastros, Lançamentos e Usuários |
| 2 | Operação normal: lançar, alterar, excluir |
| 3 | Tudo do nível 2, mais o cadastro de usuários e a importação por planilha |

Além do nível, existe uma regra ligada ao **usuário 1** especificamente: só ele enxerga o menu
de backup e tem o backup automático ligado.

> `Ulogin.pas:56-72`, `Ulogin.pas:91-98`, `UfrmLancamentos.pas:1498-1501`

O nível restrito também esconde, dentro da tela de lançamentos, os botões de CRUD, o painel de
status e o pagamento em lote.

> `UfrmPrincipal.pas:128-144`

> **Atenção:** toda a autorização é feita escondendo controles da interface. Não há nenhuma
> verificação no banco. Quem alcançar o banco diretamente faz o que quiser.

### Autoria do lançamento

Todo lançamento grava quem o criou (`USERID`). A regra é: **só quem lançou pode alterar ou
excluir**, com o usuário 1 como exceção que pode tudo. Ao recusar, o sistema informa o nome de
quem lançou, para que o operador procure a pessoa certa.

> `UfrmLancamentos.pas:588-604`

> **Defeito:** essa verificação está **comentada no botão Alterar** e ativa apenas no Excluir.
> Na prática, hoje qualquer usuário altera o lançamento de qualquer outro.
> `UfrmLancamentos.pas:1205`

---

## Módulo: Lançamentos

### Campos obrigatórios

Antes de salvar, quatro campos precisam estar preenchidos: **descrição**, **valor previsto**,
**subdespesa** e **conta**. Faltando qualquer um, o sistema avisa e não grava.

> `UfrmLancamentos.pas:633-646`

### Como um lançamento é gravado

- A **subdespesa determina a despesa**: ao escolher a subdespesa na busca, o sistema preenche
  os dois campos juntos. Não é possível escolher uma combinação inválida.
- **Data de cadastro** é sempre o momento da gravação, nunca digitada.
- **Autor** é sempre o usuário logado.
- **Cheque compensado** recebe `'N'` quando o campo fica vazio.
- Se **"confirmar pagamento"** estiver marcado, grava a data de pagamento informada e marca o
  lançamento como pago.
- Caso contrário, marca como **não pago e zera o valor pago**.

> `UfrmLancamentos.pas:742-790`, `UfrmPesqDespesas.pas:112-143`

### Parcelamento

Transforma um lançamento em N parcelas.

1. O operador informa a quantidade de parcelas.
2. O sistema calcula **valor da parcela = valor previsto ÷ N** e mostra uma tela de
   confirmação: "Serão geradas N parcelas de R$ X".
3. Confirmado, gera N lançamentos copiando todos os dados do original.
4. A descrição de cada parcela vira **"DESCRIÇÃO ORIGINAL i/N"**.
5. A observação de todas recebe **"Gerada automaticamente pelo parcelamento"**.
6. O vencimento da parcela *i* é o vencimento original deslocado de *i−1* meses — ou seja, a
   **primeira parcela vence no mês original**.
7. Ao final, **o lançamento original é excluído**.
8. Se havia nota fiscal vinculada, ela volta a constar como não lançada.

> `UfrmLancamentos.pas:1257-1359`

O parcelamento é fluxo central: **4.441 lançamentos (32% da base) foram gerados assim**.

> **Defeitos:**
> - A divisão não trata dízima. R$ 20.000,00 em 12 parcelas gera parcelas de R$ 1.666,666626,
>   que somam R$ 19.999,9995. Há 200 parcelas nessa condição na base.
> - A operação **não é atômica**: as N inserções e a exclusão do original são confirmadas
>   individualmente. Uma falha no meio deixa a base inconsistente.
> - Variáveis de cheque, nota fiscal e entrada não são inicializadas; quando o original tem
>   esses campos nulos, o valor copiado é lixo de memória.

### Pagamento em lote

Marca como pagos **todos os lançamentos exibidos na tela** que ainda não foram pagos.

- Exige confirmação, avisando que a operação é irreversível.
- Para cada não pago: data de pagamento recebe **hoje** e o **valor pago recebe o valor
  previsto** integralmente.
- Lançamentos já pagos são ignorados.

> `UfrmLancamentos.pas:416-447`

> **Defeito crítico:** o avanço para o próximo registro está *dentro* da condição
> "se não pago". Se qualquer registro já pago aparecer na lista, o laço nunca avança e **a
> aplicação congela**. `UfrmLancamentos.pas:426-438`

### Status de liberação

Um lançamento pode ser marcado como **AGUARDANDO** ou **LIBERADA**, para controlar aprovação
antes do pagamento. Na grade, os que estão aguardando aparecem em roxo e os já pagos em cinza.

> `UfrmLancamentos.pas:1397-1416`, `UfrmLancamentos.pas:1536-1582`

Uso real: 501 liberadas, 13 aguardando, 13.458 sem status. É um recurso pouco usado.

### Teto por subdespesa — funcionalidade morta

A tela mostra um painel com valor máximo da subdespesa e o saldo restante (previsto e pago),
calculado como *teto − total*.

> `UfrmLancamentos.pas:449-484`

> **Nenhuma das 148 subdespesas tem teto preenchido.** O painel nunca teve utilidade real.
> Não migrar sem confirmar se o cliente ainda deseja o recurso.

### Consultas

Duas abas de pesquisa, com filtros combináveis por subdespesa, conta e situação de pagamento
(pago, não pago, todos):

| Busca por | Filtra pela data de | Comportamento |
|---|---|---|
| Descrição | Vencimento | Trecho em qualquer posição |
| Nota fiscal | Cadastro | Número exato; força o início do período em 01/01/2018 |
| Cheque / documento | Vencimento | Trecho em qualquer posição |
| Status | Cadastro | Trecho em qualquer posição |
| Cheque compensado | — | Trecho; **ignora o período** |
| Faixa de valor previsto | Vencimento | Entre inicial e final |
| Faixa de valor pago | **Pagamento** | Entre inicial e final |

O período padrão da tela principal é dos **últimos 6 meses** até hoje.

> `UfrmLancamentos.pas:903-1120`, `UfrmLancamentos.pas:1122-1201`

> **Defeitos:** a busca por cheque compensado é sensível a maiúsculas e há 9 registros
> gravados com `'s'` minúsculo — invisíveis ao filtrar por `'S'`. As buscas por nota fiscal e
> por faixa de valor convertem o texto digitado sem validar: entrada não numérica gera erro.

### Totais em tela

O rodapé soma valor previsto e valor pago de tudo que está na grade. Quando há uma subdespesa
filtrada, mostra também o saldo contra o teto.

> `UfrmLancamentos.pas:449-484`

### Exportação para Excel

Exporta a consulta atual com colunas fixas: descrição, valor pago, valor previsto, nota
fiscal, cheque, data de vencimento, data de pagamento e conta. Valores são arredondados para
duas casas e formatados como moeda brasileira. A última linha traz os totais.

> `UfrmLancamentos.pas:1591-1726`

---

## Módulo: Importação por planilha

Permite lançar um lote inteiro de pagamentos a partir de uma planilha Excel. Disponível
apenas para o nível 3.

### Leitura da planilha

- Aba de nome fixo **`Planilha1`**, dados a partir da **linha 2**.
- Coluna 1 = data, coluna 2 = descrição, coluna 3 = valor.
- A descrição é convertida para **maiúsculas e sem acentos**.
- **Linha sem data não vira registro novo:** sua descrição é anexada à do registro anterior,
  separada por " - ". É assim que uma despesa com várias linhas de detalhe é consolidada.
- O valor é limpo de qualquer caractere que não seja dígito ou vírgula.

> `UfrmLancamentosEmLote.pas:114-190`, `UfrmLancamentosEmLote.pas:467-479`

### Gravação do lote

O operador escolhe **uma** despesa/subdespesa, **uma** conta e **uma** forma de pagamento, que
valem para todo o lote. Então, para cada linha:

- Valor previsto e **valor pago recebem o mesmo valor** da planilha.
- Data de vencimento e **data de pagamento recebem a data da planilha**.
- O lançamento entra **já marcado como pago**.
- Cheque, nota fiscal e entrada recebem zero; cheque compensado recebe `'N'`.
- O autor é o usuário logado.

> `UfrmLancamentosEmLote.pas:374-465`

> Isso explica por que 10.481 lançamentos têm pagamento anterior ao cadastro: a data de
> pagamento é histórica e a de cadastro é o momento da importação. **Não é defeito.**

---

## Módulo: Despesas e subdespesas

- As duas entidades são mantidas na mesma tela, em abas.
- Ao criar uma subdespesa, ela é **atribuída à despesa selecionada na grade**, e a tela mostra
  "[Atribuir para a Despesa: X]" para deixar isso explícito.
- Teto vazio é gravado como zero.
- A exclusão captura a violação de chave estrangeira e explica ao operador que o registro está
  sendo referenciado em outro lugar, em vez de mostrar o erro técnico.

> `UcategoriaGeral.pas:463-506`, `UcategoriaGeral.pas:202-230`

O mesmo tratamento amigável de exclusão aparece em Contas, Formas de Pagamento, Produtos,
Fornecedores, Destinos e Propriedades.

---

## Módulo: Consulta por despesa

Consolida os gastos de uma despesa, quebrados por subdespesa, dentro de um período. Tem dois
modos que **mudam a data usada no filtro**:

| Modo | Filtra por | Condição |
|---|---|---|
| **Pago** | `DATA_PAGAMENTO` | apenas `PAGO = 1` |
| **Não pago** | `DATA_VENCIMENTO` | apenas `PAGO = 0` |

Essa troca de data é a regra mais importante do módulo: "quanto gastei" olha a data em que o
dinheiro saiu, "quanto devo" olha a data em que vence.

Ao dar duplo clique numa subdespesa, abre-se o detalhamento; o duplo clique no detalhe leva o
operador direto para o lançamento em modo de alteração.

> `UpesquisaCategoria.pas:105-142`, `UpesquisaCategoria.pas:190-268`,
> `UfrmLancamentos.pas:1728-1763`

---

## Módulo: Aviso de vencimentos

Ao abrir o sistema, e sempre que o operador atualiza, conta os lançamentos **vencidos ou
vencendo hoje que ainda não foram pagos** (`DATA_VENCIMENTO <= hoje` e `PAGO = 0`) e mostra
"Há N despesa(s) a pagar".

Se houver algum, a tela de lançamentos abre já na aba de consulta, com o período dos últimos
6 meses e todos os status. Se não houver, abre na aba de cadastro.

> `UfrmPrincipal.pas:114-126`, `UfrmLancamentos.pas:1494-1529`

---

## Módulo: Backup

Duas formas, ambas por **cópia bruta do arquivo do banco**:

1. **Manual:** o operador escolhe origem e destino e o sistema copia.
2. **Automático:** um temporizador copia `Y:\Dados\DADOS_12_23.FDB` para
   `C:\Users\Usuario\Desktop\Novo sistema\`, com os caminhos fixos no código. Ligado apenas
   para o usuário 1.

> `UbackUp.pas:43-54`, `UfrmPrincipal.pas:390-406`

> **Defeito:** copiar um arquivo Firebird enquanto o banco está aberto pode produzir uma cópia
> inconsistente. O backup correto é por `gbak`. Os componentes `TFDIBBackup` estão no
> formulário mas nunca são chamados.

---

## Módulo: Estoque e notas fiscais — inativo

Mantido no projeto, mas **sem controle de saldo**: todas as chamadas que alteram
`PRODUTO.ESTOQUE` e gravam movimentação estão comentadas, e a tabela de movimentação está
vazia. Decisão do cliente: não migrar.

Regras ainda visíveis no código, registradas para o caso de o módulo ser retomado:

- Uma nota nasce como **NF ABERTA** e vira **PROCESSADA** ao ser processada; processada não
  aceita mais alterações.
- Ao processar, o sistema pergunta se deve **atualizar o preço dos produtos** com os valores
  da nota.
- Uma entrada **já vinculada a um lançamento financeiro** não pode ser excluída; é preciso
  apagar o lançamento antes.
- O valor da nota é a **soma dos itens**, recalculada a cada alteração.
- Valor total do item = valor unitário × quantidade.
- Inserir um produto que já está na nota oferece alterar o item existente.
- A saída de produto calcula o valor como quantidade × preço do produto.

> `UfrmEntradaNF.pas`, `UfrmItensEntrada.pas`, `UfrmSaidaProdutos.pas`

---

## Comportamentos de interface que são regra

Coisas que parecem cosméticas mas o operador usa como informação:

- **Pago** aparece em cinza com texto branco na grade.
- **AGUARDANDO** aparece em roxo.
- A linha selecionada fica rosa claro com texto cinza.
- `Enter` no campo de busca de subdespesa abre o seletor; `Enter` na descrição **não** salva
  (é suprimido de propósito, para evitar gravação acidental).
- Clicar em qualquer célula da grade **cancela a edição em andamento**.

> `UfrmLancamentos.pas:1536-1582`, `UfrmLancamentos.pas:1418-1422`,
> `UfrmLancamentos.pas:1531-1534`
