# Referência de paridade

Números extraídos da **base congelada** em 19/08/2026. São o oráculo mais forte dos testes:
resultado acumulado de três anos de operação do legado.

Qualquer implementação nova rodada sobre a mesma base precisa reproduzi-los exatamente.

## Onde ficam as bases

```
C:\PROGRAMAS\AgendaFinanceira-paridade\
    base-paridade-2026-08-19.fbk    backup lógico, a fonte de tudo
    BASE_PARIDADE.FDB               referência IMUTÁVEL dos testes de leitura
    MOLDE_ESCRITA.FDB               igual, mais a coluna SENHA_HASH; molde dos testes de escrita
    DESENVOLVIMENTO.FDB             onde a API roda no dia a dia; pode ser sujada à vontade
```

**`BASE_PARIDADE.FDB` nunca é escrita.** Os testes que gravam copiam o `MOLDE_ESCRITA.FDB`
para um arquivo temporário próprio, que é apagado ao final — ver `BaseDescartavel` nos testes.
Assim um teste nunca enxerga o que outro gravou, e a referência não se move.

Para recriar o molde depois de restaurar a base:

```sql
ALTER TABLE LOGIN ADD SENHA_HASH VARCHAR(200);
```

**Fora do repositório de propósito.** Contém dados financeiros reais, 157 CNPJs e senhas em
texto plano. Nunca versionar, nunca copiar para fora da máquina sem anonimizar.

Para recriar a base do zero a partir do backup:

```powershell
$fb = "C:\Program Files\Firebird\Firebird_2_5\bin"
$P  = "C:\PROGRAMAS\AgendaFinanceira-paridade"
& "$fb\gbak.exe" -c -user SYSDBA -password masterkey `
    "$P\base-paridade-2026-08-19.fbk" "localhost:$P\BASE_PARIDADE.FDB"
```

## Totais gerais

| Medida | Valor esperado |
|---|---|
| Lançamentos | 13.972 |
| Pagos | 12.462 |
| A pagar | 1.510 |
| **Total pago** | **R$ 34.501.459,68** |
| **Total previsto** | **R$ 35.586.456,69** |
| Categorias (despesas) | 14 |
| Subcategorias | 148 |
| Contas | 14 |
| Formas de pagamento | 10 |
| Usuários | 6 |

Os totais monetários são a soma dos valores **convertidos para `NUMERIC(15,2)`**, ou seja, cada
lançamento arredondado para duas casas antes de somar. É essa a regra de comparação: o novo
sistema bate com o legado arredondado, não com o valor cru do `FLOAT`.

## Período coberto

| Medida | Valor |
|---|---|
| Menor vencimento | 1899-12-30 (o zero do `TDateTime`, dado sujo) |
| Maior vencimento | 2027-07-08 |
| Maior cadastro | 2025-03-26 |

## Total pago por despesa

A soma desta tabela fecha exatamente em **R$ 34.501.459,68**, e a contagem em **13.972** —
o que dá uma verificação cruzada de consistência.

| Despesa | Lançamentos | Total pago |
|---|---:|---:|
| AGRICOLA | 2.777 | R$ 6.424.525,50 |
| BASE JC | 450 | R$ 358.851,85 |
| CASA RAUL | 2.479 | R$ 1.486.431,43 |
| CHACARA | 257 | R$ 1.415.053,76 |
| COMPRAS E FINANCIAMENTOS | 121 | R$ 1.928.309,05 |
| DESPESAS | 4.448 | R$ 17.202.250,60 |
| DESTILARIA | 73 | R$ 10.160,72 |
| DUBAI | 5 | R$ 322.806,23 |
| ESCRITORIO | 1.205 | R$ 1.217.832,33 |
| IMPOSTOS | 3 | R$ 18.594,17 |
| PETROTORQUE | 1.555 | R$ 3.421.328,94 |
| VEICULOS | 599 | R$ 695.315,10 |

Só 12 das 14 categorias aparecem: uma tem descrição vazia e `DOCE E CANA` nunca recebeu
lançamento. Ambas precisam continuar existindo no cadastro mesmo sem movimento.

## Casos especiais que os testes precisam cobrir

| Caso | Quantidade | Por quê importa |
|---|---:|---|
| Valor previsto impreciso | 471 | comparação monetária precisa de tolerância declarada |
| Valor pago impreciso | 400 | idem |
| Valor acima de R$ 99.999,99 | 30 | acima do limite de precisão do `FLOAT` |
| Parcelas geradas por parcelamento | 4.441 | 32% da base; a soma das parcelas não fecha o total |
| Data 30/12/1899 | 11 | zero do `TDateTime`; decidir a representação |
| `CHEQUE_COMPENSADO` minúsculo | 9 | invisíveis à busca do legado, que é sensível a caixa |
| Situação LIBERADA | 501 | |
| Situação AGUARDANDO | 13 | |
| `ENTRADA_ID` órfão | 5 | aponta para nota fiscal inexistente |

## Casos individuais de referência

Valores conhecidos, úteis como teste unitário da conversão monetária:

| Lançamento | Gravado no banco | Valor correto |
|---|---|---|
| 19035 | 147059.765625 | R$ 147.059,77 |
| 17014 | 1666.666626 | R$ 1.666,67 |

O 17014 é uma parcela de "CARTAO DE CREDITO 12/12" — R$ 20.000,00 divididos por 12. As doze
parcelas somam R$ 19.999,9995 no legado. **No sistema novo devem somar R$ 20.000,00**, e essa
divergência é correção intencional.

## Texto com caractere fora do ISO-8859-1

Um registro em `REGISTRO_DE_GASTOS.OBS` usa o byte `0x96` (travessão do WIN1252):

```
Lote 12 – Quadra K – Escritura R$ 1.486,10
Lote 27 – Quadra F – Escritura R$ 1.273,66
```

Serve de teste para a estratégia de leitura descrita no
[ADR 0009](decisoes/0009-acesso-a-dados-dapper-e-charset.md). Se lido como ISO-8859-1 puro, os
travessões desaparecem.

## Como regerar estes números

O programa em `src/AgendaFinanceira.SpikeFirebird` confere parte deles automaticamente. Para a
lista completa, as consultas estão no histórico deste documento — e a regra é: **se algum
número mudar sem que ninguém tenha mexido na base, alguma coisa está errada**, e o motivo
precisa ser encontrado antes de atualizar o documento.
