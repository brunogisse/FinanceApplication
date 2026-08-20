# 0004 — Não migrar o módulo de estoque

- **Situação:** Aceita
- **Data:** 2026-08-18

## Contexto

O sistema tem dois módulos: financeiro (contas a pagar) e estoque com notas fiscais. O segundo
ocupa nove das vinte e seis telas do projeto — Entrada de NF, Itens de Entrada, Saída de
Produtos, Produtos e Tipos, Pesquisa de Produto, Itens de Estoque, Movimentação de Produto,
Relatório de Saídas, além dos cadastros de Fornecedor, Destino e Propriedade.

A engenharia reversa mostrou que ele está desativado:

- Todas as chamadas que alteram `PRODUTO.ESTOQUE` estão comentadas no código
  (`AtualizarEstoqueDeProdutos`, `MovimentarEstoque`, `AtualizarEstoqueDoProduto`).
- Todas as chamadas que gravam histórico (`RegistrarMovimentacaoProduto`) estão comentadas.
- As validações de estoque negativo (`VerificarEstoqueZerado`) estão comentadas.
- A tabela `MOVIMENTACAO_PRODUTO` está **vazia** — embora seu generator marque 1.923, ou seja,
  houve 1.923 movimentações que foram apagadas.

As tabelas ainda guardam dados históricos: 592 notas fiscais, 1.412 itens, 1.294 saídas, 735
produtos e 181 fornecedores. O que não existe mais é o controle de saldo.

Consultado sobre isso, o cliente confirmou: o módulo está abandonado e o foco é o financeiro.

O único ponto de contato entre os dois módulos é `REGISTRO_DE_GASTOS.ENTRADA_ID`, um inteiro
que aponta para `CADASTRO_NF` **sem chave estrangeira** — há 5 valores órfãos. A tela de
lançamentos ainda manipula `CADASTRO_NF.NF_LANCADA` ao alterar, excluir ou parcelar.

## Decisão

O módulo de estoque e notas fiscais **não é migrado**. A nova stack contempla apenas o
financeiro.

Os dados históricos das tabelas de estoque são **preservados** — não são apagados nem
excluídos de backups. Continuam consultáveis pelo legado enquanto ele existir.

O vínculo `ENTRADA_ID` é migrado como **um número inteiro sem significado ativo**, apenas para
não perder o dado histórico. A nova stack não implementa a manipulação de `NF_LANCADA`: sem o
módulo de notas, marcar e desmarcar uma nota como lançada não tem efeito nenhum.

As regras do módulo ficam registradas em [dominio.md](../dominio.md) e [fluxos.md](../fluxos.md)
para o caso de o assunto voltar.

## Consequências

**Mais fácil:** o escopo da migração cai de vinte e seis para cerca de dez telas. Os testes de
paridade concentram-se onde o dinheiro está.

**Mais difícil:** se o cliente decidir retomar o controle de estoque, será um projeto novo, não
uma continuação. A vantagem é que as regras estão documentadas e as tabelas do estoque usam os
tipos monetários corretos — melhor ponto de partida do que o financeiro tinha.

**Passa a ser obrigatório:** ao migrar `REGISTRO_DE_GASTOS`, tratar `ENTRADA_ID` como dado
opaco. Não criar chave estrangeira para `CADASTRO_NF` na nova base sem antes resolver os 5
órfãos — e resolver significa decidir com o cliente o que fazer com eles, não apagá-los.

**Fica pendente:** confirmar com o cliente se as telas do módulo devem continuar acessíveis no
legado durante a convivência, ou se convém escondê-las do menu para evitar uso acidental de um
módulo que não controla mais nada.
