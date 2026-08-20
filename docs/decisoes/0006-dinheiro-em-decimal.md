# 0006 — Valores monetários em decimal, em todas as camadas

- **Situação:** Aceita
- **Data:** 2026-08-19

## Contexto

O defeito central do legado é de tipo. `REGISTRO_DE_GASTOS.VALOR_PAGO`, `VALOR_PREVISTO` e
`SUBCATEGORIA.VALOR_MAXIMO` são `FLOAT` no Firebird — ponto flutuante de precisão simples, 32
bits, cerca de 7 dígitos significativos.

Isso não é teoria. Medido na base de produção:

- **471** lançamentos com valor previsto que não fecha em dois decimais; **400** no valor pago
- **30** lançamentos acima de R$ 99.999,99, onde a perda é garantida
- maior valor da base: R$ 2.070.000,00

```
ID=19035  gravado=147059.765625   pretendido=147059.77
ID=17014  gravado=  1666.666626   pretendido=  1666.67
```

O segundo caso é uma parcela de R$ 20.000,00 dividida em 12. As doze parcelas somam
R$ 19.999,9995 e não fecham o total — há **200 parcelas** nessa condição.

O detalhe que mais incomoda: o módulo de estoque, que foi abandonado, usa `NUMERIC(15,2)` e
`DECIMAL(15,2)` corretamente em todas as suas colunas de valor. Só o módulo em produção errou.

## Decisão

Nenhum valor monetário passa por ponto flutuante em nenhuma camada da nova stack — nem
`float`, nem `double`, nem `single`, nem `real`, nem `number` do JavaScript.

**No banco:** `NUMERIC(15,2)` ou `DECIMAL(15,2)`.

**No backend:** o tipo `decimal` do C#, que é de base 10, 128 bits, e existe exatamente para
isto.

**No transporte:** número decimal ou texto no JSON, nunca convertido para `double` no caminho.

**No frontend:** representação decimal explícita. O `number` do JavaScript é ponto flutuante
binário de dupla precisão e não serve para dinheiro. Valores chegam e saem como texto ou
inteiro de centavos, e a formatação para tela acontece na borda.

**Arredondamento** é sempre explícito, para duas casas, com regra declarada — nunca implícito
por conversão de tipo.

**Divisão que gera dízima** distribui o resto de forma determinística: a soma das partes é
sempre igual ao todo. No parcelamento, as N parcelas somam exatamente o valor original, com a
diferença absorvida numa parcela definida por regra fixa e documentada.

### Como lidar com o legado durante a convivência

Enquanto o banco continuar sendo o Firebird atual ([0005](0005-estrategia-de-banco.md)), as
três colunas continuam `FLOAT`. Alterar o tipo agora quebraria os campos persistentes
`TSingleField` declarados nos `.dfm` do Delphi, exigindo recompilar e reinstalar o legado.

Então a API trata a imprecisão **na borda**:

- **Ao ler:** converte o `FLOAT` para `decimal` e arredonda para duas casas. É a interpretação
  correta — R$ 147.059,765625 nunca foi um valor real, foi R$ 147.059,77 mal guardado.
- **Ao escrever:** grava o valor já arredondado para duas casas. Não piora nada, e tudo o que
  o novo sistema escrever fica correto até o limite que o tipo permite.
- **Acima de R$ 99.999,99** o `FLOAT` não consegue representar dois decimais com fidelidade.
  Enquanto a coluna for `FLOAT`, valores nessa faixa continuam sujeitos a erro na gravação —
  é uma limitação herdada, não uma escolha, e precisa estar visível no plano de migração.

A correção definitiva do tipo acontece na Etapa 2 ou 3 de [0005](0005-estrategia-de-banco.md),
quando o legado já puder ser recompilado ou já estiver desligado.

## Consequências

**Mais fácil:** confiar nos totais. Somar 13.972 lançamentos e obter o mesmo número duas vezes,
em qualquer camada.

**Mais difícil:** o frontend perde a conveniência de fazer aritmética com `number`. Toda
operação monetária no cliente precisa de cuidado explícito, e isso será uma fonte recorrente de
revisão em code review.

**Passa a ser obrigatório:** todo teste de paridade que compara valores contra o legado usa
tolerância declarada, comparando com o valor do legado **arredondado para dois decimais**, não
com o valor cru. O novo sistema não vai reproduzir os erros do antigo, e essa divergência é
correção intencional — precisa aparecer no relatório de paridade, nunca ser silenciada.
Ver `.claude/agents/qa-paridade.md`.
