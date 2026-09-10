# Unificação das duas bases

Como a base do **financeiro** e a do **faturamento** viraram uma só, com cada
lançamento e cada cadastro carregando o setor a que pertence.

> **Estado em 09/09/2026:** feito e conferido em laboratório, sobre cópias.
> A produção é repetida no fim de semana, com o mesmo script.
> **A API ainda não filtra por setor** — ver [O que falta](#o-que-falta).

---

## 1. O que se descobriu antes de mexer

O pedido original supunha dois bancos de setores diferentes. **Não é isso.**

As duas são **ramos do mesmo banco original**: mesma data de criação
(09/07/2020), mesmos 6 usuários com os mesmos IDs, cadastros idênticos até certo
ponto. Em algum momento a base foi copiada, os setores se separaram, e cada
cópia seguiu sendo usada.

| | `DADOS_12_23` (financeiro) | `DADOS_14032022_ZERADO` (faturamento) |
|---|---|---|
| Lançamentos | 18.249 | 15.664 |
| Soma paga | 42.578.394,62 | 42.631.955,73 |
| Soma prevista | 43.674.012,91 | 57.902.880,21 |
| Vencimentos | 30/12/1899 a 08/07/2027 | 17/12/2021 a 30/03/2028 |
| Despesas / Subdespesas | 16 / 160 | 26 / 141 |
| Contas / Formas | 14 / 10 | 23 / 11 |

**As somas pagas diferem em 0,1%.** Setores realmente separados teriam somas sem
relação nenhuma. Foi esse número que fez desconfiar e medir o resto.

### A sobreposição

Dos **15.437 IDs que existem nas duas bases**:

| | | |
|---|---|---|
| **9.251** | 60% | o **mesmo registro**, idêntico em data, valor, despesa e descrição |
| **6.127** | 40% | mesmo ID, **registros sem parentesco nenhum** |
| ~59 | 0,4% | ambíguos: mesmo registro editado, ou dois eventos? |

O ID 13337 é `CONTA CELULAR EVA 10/12` numa base e `CENTER TECH` na outra. Depois
da separação, **as duas continuaram inserindo na mesma sequência do generator**,
e os números colidiram.

Não há corte no tempo que separe: os idênticos vão de 2021 a 2027, e os
divergentes também.

### Quem lançou o quê

Cruzando a classificação com o autor de cada lançamento:

| Grupo | Quantidade | Autor predominante |
|---|---|---|
| Compartilhado (idêntico nas duas) | 9.251 | **JULIANA 94,6%** |
| Só do financeiro | 2.812 | JULIANA 99,9% |
| Mesmo ID, lado financeiro | 6.186 | **JULIANA 100%** |
| Mesmo ID, lado faturamento | 6.186 | **aline 98%**, HAYOLLA 1,7% |
| Só do faturamento | 227 | aline 80% |

Separação limpa: **JULIANA lançou tudo do financeiro; aline e HAYOLLA, tudo do
faturamento.** Foi assim que se soube a que setor cada pessoa pertence, sem
precisar perguntar.

### Os ambíguos, e por que a vizinhança resolve

Dos 59, **46 têm data e valor idênticos até os centavos** — mesmo lançamento,
apenas reclassificado ou com a descrição completada num dos ramos:

```
ID 17470   financeiro   16/11/2023   3.670,03   NF 42858 - COOPERCITRUS
           faturamento  16/11/2023   3.670,03   NF 42858 -
```

Vários apareciam como "valor diferente" na primeira medição por causa do `FLOAT`:
`2.021,53` gravado com bits diferentes nos dois ramos. É [o defeito
central](../CLAUDE.md#o-defeito-central) do sistema aparecendo na comparação.

Os 13 restantes foram analisados pela **vizinhança**, e isso inverteu a leitura
inicial:

```
WHITE MARTINS MENSALIDADE - série de 12 parcelas

  12930  12/04/2023   156,96   1/12     idêntico nas duas
  ...                                   idênticos nas duas
  12940  12/02/2024   156,96  11/12     idêntico nas duas

  12941  financeiro:  12/03/2024   156,96   12/12    ← fecha a série
         faturamento: 10/04/2024   191,16   (sem sufixo)
```

**As onze primeiras parcelas são idênticas; só a décima segunda diverge.** Um
lançamento novo teria pegado um ID novo do generator — não cairia no meio de uma
série numerada. Foi a última parcela, editada quando veio com valor e data
diferentes.

O mesmo em `FINANCIAMENTO PLANTADEIRA SOJA`, onde os valores caem ano a ano
(10.843 → 10.393 → **9.964** → 9.525) e o lado do faturamento quebra a
progressão com 15.057.

---

## 2. A regra que decidiu tudo

> *"coloque o que era de cada base na base unificada mas separados por setor.
> não podemos assumir perda de dados visualizados por cada operária."*
> — Bruno, 08/09/2026

Com isso, **nada é fundido por semelhança**. Nem lançamento, nem cadastro. Os
9.251 compartilhados passam a existir **duas vezes**, uma por setor, e cada
operária continua vendo exatamente a mesma lista de hoje.

Isso encerrou a análise dos 59 ambíguos: não é preciso decidir nenhum deles.

### O que isso custa

Um relatório que somasse os dois setores **contaria os 9.251 compartilhados em
dobro**. Hoje essa tela não existe, e toda consulta vai filtrar por setor — mas
um futuro "total da empresa" não pode ser uma soma simples.

---

## 3. O desenho

```
SETOR              tabela nova:  1 FINANCEIRO,  2 FATURAMENTO

REGISTRO_DE_GASTOS + SETOR_ID    de quem é o lançamento
CATEGORIA          + SETOR_ID
SUBCATEGORIA       + SETOR_ID
CONTAS             + SETOR_ID
FORMA_DE_PAGAMENTO + SETOR_ID
LOGIN              + SETOR_ID    a que setor a pessoa pertence
LOGIN              + SENHA_HASH  coluna de convivência (ADR 0010)
```

**O nível continua onde sempre esteve, no `LOGIN`.** Gravar nível também no
registro criaria a chance de os dois se contradizerem — e aí qual vale? São dois
eixos independentes:

| | Responde | Onde vive |
|---|---|---|
| **Setor** | de quem é o dado | no registro **e** no usuário |
| **Nível** | o que a pessoa pode fazer | só no usuário |

Isso sobrevive ao próximo pedido sem migração nova: uma ajudante nível 2 no
financeiro, um administrador no faturamento, alguém que veja os dois.

### Por que o cadastro também leva setor

A primeira versão do plano casava cadastros **por nome**: `AGRICOLA` de uma base
com `AGRICOLA` da outra, uma linha só.

Isso quebra na regra. Casar `CHACARA 2` (ID 43 no financeiro) com `CHACARA 2`
(ID 54 no faturamento) é **assumir que são a mesma propriedade** — exatamente a
fusão por semelhança que a regra proíbe. E o faturamento tem `CHACARA 3` duas
vezes (IDs 53 e 55), que o casamento por nome fundiria numa só.

Com setor no cadastro, cada operária vê a lista dela, sem nome repetido no
seletor e sem ninguém perder nada.

### O deslocamento de IDs

Os lançamentos e cadastros do faturamento entram com **ID + 100.000**.

Não é enfeite: 15.437 dos 15.664 lançamentos colidem, então preservar o número
original é impossível. De quebra, **qualquer linha com ID acima de 100.000 se
identifica como vinda do faturamento só pelo número** — o que vale muito quando
alguém perguntar de onde saiu um lançamento.

`USERID` **não** é deslocado: `LOGIN` é compartilhado, são as mesmas pessoas.

### Os usuários

Não são duplicados — são os mesmos 6, uma linha cada, com setor:

| | Nível | Setor | Lançou |
|---|---|---|---|
| JULIANA | 3 | financeiro | 26.356 |
| EGLECIR | 2 | financeiro | 0 |
| KA | 1 | financeiro | 0 |
| aline | 2 | faturamento | 7.320 |
| HAYOLLA | 2 | faturamento | 121 |
| ALINEAP | 2 | faturamento | 116 |

EGLECIR e KA nunca lançaram em nenhuma das duas; ficaram no financeiro por
não haver sinal em contrário. ALINEAP tem volume nos dois lados e ficou no
faturamento, onde é maior.

---

## 4. Como a cópia é feita, e as duas tentativas que falharam

### Tentativa 1 — cliente .NET com `Charset=ISO8859_1`

Morreu em **"Cannot transliterate character between character sets"**.

A base é **WIN1252**, e os travessões e aspas tipográficas do legado vivem na
faixa `0x80–0x9F`, que o ISO8859_1 não tem. O provider também **não aceita
`WIN1252`** pelo nome, em nenhuma variante — verificado no spike do projeto.

### Tentativa 2 — cliente .NET com `Charset=NONE`

Passou do charset e morreu na **linha 6.655** com **"string right truncation"**.

O campo `OBS` do `GASTOS_ID` 14494 tem exatamente **200 caracteres com acentos**,
e o cliente codificava o parâmetro com mais de um byte por acentuado: 200
caracteres viravam mais de 200 bytes, e a coluna `VARCHAR(200)` recusava.

> Sem diagnóstico por linha, o Firebird diz só `string right truncation` — um
> erro sem endereço no meio de 15 mil registros. O programa passou a reportar a
> linha e o comprimento de cada campo de texto, e aí a causa apareceu na hora.

### O que funcionou — `EXECUTE STATEMENT ON EXTERNAL`

O Firebird 2.5 sabe ler outro banco **por dentro do servidor**:

```sql
FOR EXECUTE STATEMENT 'SELECT ... FROM REGISTRO_DE_GASTOS'
    ON EXTERNAL 'localhost:C:\...\FATURAMENTO.FDB'
    AS USER 'SYSDBA' PASSWORD 'masterkey'
    INTO :V_ID, :V_CAT, ...
DO INSERT INTO REGISTRO_DE_GASTOS (...) VALUES (:V_ID + 100000, ..., 2);
```

Três problemas resolvidos de uma vez:

- **Os bytes nunca passam por codificação.** Vão de um banco para o outro como
  estão.
- **O `FLOAT` não vira texto no caminho.** `VALOR_PAGO`, `VALOR_PREVISTO` e
  `VALOR_MAXIMO` são `FLOAT` no legado; exportar para SQL e reinserir pode mudar
  o último bit, e a perda seria invisível — R$ 2.021,53 continua imprimindo
  R$ 2.021,53.
- **Levou 1 segundo**, contra minutos de 15 mil viagens de ida e volta.

### O que foi conferido antes de escrever a primeira linha

- **As seis triggers são condicionais** (`if (new.X is null) then gen_id(...)`),
  então IDs explícitos passam. Se fossem incondicionais, elas sobrescreveriam
  tudo em silêncio.
- **Não há `CHECK` nem `UNIQUE`** — só PK e FK, como o [ADR
  0005](decisoes/0005-estrategia-de-banco.md) registra.
- **`ENTRADA_ID`** aponta para o módulo de estoque, abandonado, e **não tem FK**.
  Vai como está: apagar seria perder dado, e o valor é inerte.
- **As categorias sem descrição do faturamento** (42, 43, 45, 48) **não são
  usadas por lançamento nenhum** — mas vão junto assim mesmo, pela regra.

---

## 5. O resultado

**33.913 lançamentos**, e as somas são **idênticas às das origens até o último
dígito** — não é arredondamento coincidente, é o mesmo `FLOAT`, bit por bit:

| | Financeiro | Faturamento |
|---|---|---|
| Lançamentos | 18.249 | 15.664 |
| Soma paga | 42578394,61954442 | 42631955,72959402 |
| Soma prevista | 43674012,91234407 | 57902880,20504710 |
| Bytes de `DESCRICAO` | 398.947 | 330.592 |
| Bytes de `OBS` | — | 301.531 |

**A contagem de bytes é a prova do texto**: nenhum acento virou dois bytes nem
sumiu. `JC REPRESENTAÇÃO -BRADESCO` e `Casa Icém / Manutençã` estão inteiros.

Mais: zero linha sem setor, zero FK órfã, zero lançamento usando cadastro do
outro setor, generators acima do maior ID.

### Provado pela API

A API foi subida contra a base unificada e as **seis contas entram**, com as
senhas de produção e sem ninguém trocar nada — `SENHA_HASH` está nula e a
autenticação cai para o texto plano do legado, que é a convivência do ADR 0010
funcionando sobre a base nova.

`GET /lancamentos` devolveu os 33.913, R$ 101.576.893,14 previsto.

> Um tropeço que engana: mandando o campo como `nome` em vez de `usuario`, a API
> responde **401 "Informe o usuário"** — parece senha errada, e é nome de campo
> errado. O DTO é `CredenciaisDto { Usuario, Senha }`.

---

## 6. Como repetir

```
instalacao\unificacao\UNIFICAR.cmd
```

Pergunta as duas bases e o destino. **As origens não são tocadas** — só lidas.
Faz backup do financeiro por `gbak`, gera o destino, cria a estrutura, copia o
faturamento, ajusta os generators pelo `MAX` real e **confere 26 medidas** contra
as duas origens. Divergiu, recusa o resultado.

| Arquivo | |
|---|---|
| `unificar-bases.ps1` | o processo inteiro, com as recusas |
| `1-estrutura.sql` | `SETOR`, as colunas e a marcação do financeiro |
| `2-copia.sql.modelo` | a cópia por `ON EXTERNAL`; `@@ORIGEM@@` e `@@DESLOCAMENTO@@` são preenchidos |
| `3-conferir-detalhado.sql` | conferência avulsa, para rodar à mão depois |

Os generators são ajustados **do `MAX` real**, e não de um número calculado a
partir do deslocamento. Valor fixo funcionaria hoje e mentiria amanhã: um
generator abaixo do maior ID faz a próxima inclusão violar a chave primária — em
silêncio, até alguém tentar lançar.

---

## 7. O filtro por setor

Feito em 09/09/2026, e é o que faz a coluna valer alguma coisa. Antes disso a
`SETOR_ID` estava preenchida e correta, e ninguém a consultava: qualquer pessoa
que entrasse via os 33.913 lançamentos dos dois setores.

### Onde o setor entra

**No token, uma vez, no login.** `LOGIN.SETOR_ID` vira a claim `setor`, assinada.
Não é parâmetro de tela — uma tela que pedisse "me mostre o setor 1" seria só
mais um campo para alguém mexer. O filtro fica **no servidor**, que é o [ADR
0011](decisoes/0011-autorizacao-verificada-no-servidor.md).

**Sem setor, não entra.** A recusa é no login, com o motivo escrito. Sem setor
não há o que mostrar: nem tudo, que vazaria o outro lado, nem nada, que pareceria
uma base vazia.

### Como o servidor recusa

Um montador único, `FiltroDeSetor`, é o único lugar que escreve a condição.
Nenhuma consulta digita `SETOR_ID` por conta própria. Ele **falha fechada e falha
alto**: setor não informado vira o valor padrão da estrutura, que é zero, e em vez
de virar consulta vazia — que passaria por "não há lançamentos no período" — vira
recusa com mensagem.

Os **30 métodos públicos dos 5 repositórios** passaram a exigir o setor de fora.
Onde já existia `Usuario quem`, ele sai de lá. É o compilador que garante que
ninguém esqueceu: a mudança quebrou **160 chamadas**, e cada uma teve de ser
corrigida para compilar.

`Setor` é um tipo próprio, e não um `int`, por um motivo prático: numa assinatura
como `Alterar(int id, ..., Setor setor)` o compilador impede a troca de posição.
Com dois inteiros, trocá-los compila — e a consulta buscaria o registro errado no
setor errado, calada.

Na escrita não basta filtrar o `SELECT`: `UPDATE`, `DELETE` e o `PorId` levam
`AND SETOR_ID = @setor`. Sem isso, **saber o número bastaria** para alterar o
lançamento da outra pessoa. E a cadeia toda é conferida dentro do setor — despesa,
subdespesa, conta, forma de pagamento —, senão um lançamento nasceria classificado
sob um nome que quem lançou nunca viu.

> **A checagem de nome repetido passou a valer dentro do setor.** As duas listas
> podem ter uma conta com o mesmo nome, e recusar por causa da outra seria recusar
> por um registro que quem cadastra não enxerga — nada explicaria a mensagem.

### As duas redes de segurança

O compilador garante que o setor é passado. Não garante que o `WHERE` foi escrito
lá dentro. Por isso:

**A trigger `REGISTRO_DE_GASTOS_BI_SETOR`**, posição 1, depois da que atribui o
identificador. Preenche o setor a partir de `LOGIN.SETOR_ID` do autor quando vier
nulo — que é como os setores foram descobertos aqui. É ela que impede o Delphi de
criar registro invisível para a API durante a convivência: ele não conhece a
coluna e gravaria nulo. Quando nem assim dá para deduzir, o registro fica sem
setor **de propósito**, em vez de ser atribuído a um lado por chute, e o
`GET /saude` conta esses registros à vista.

**O teste de vazamento**, `VazamentoEntreSetoresTeste`, sobre uma cópia da base
unificada com os dois setores dentro. Com sessão do faturamento, varre os
endpoints de leitura e exige que nada do financeiro apareça; nos de escrita, tenta
alterar, excluir, parcelar e pagar em lote lançamento do outro setor e exige
recusa **mais o registro intacto no banco depois**. São 23 conferências.

### O que ele mostrou

Três premissas minhas estavam erradas, e o teste é que disse:

- **Os identificadores não colidem mais.** Os 6.127 repetidos eram das bases de
  origem; o deslocamento os separou. O teste passou a conferir isso ao contrário —
  se voltarem a colidir, um lançamento fica alcançável pelo número nos dois lados.
- **Faltavam 30 lançamentos do financeiro** na consulta com período de 2000 a
  2099. Não é vazamento nem filtro: são vencimentos digitados fora dessa faixa no
  legado.
- **Junho de 2023 dá exatamente o mesmo total nos dois setores** — 433 lançamentos,
  R$ 657.945,64. É o esperado, não defeito: são os compartilhados, que existem dos
  dois lados. Um teste de "tem de dar diferente" reprovaria o comportamento certo.
  A conferência virou de **partição**: os dois somados dão o mês inteiro, e nenhum
  deles sozinho dá.

### Na tela

O login devolve o setor. A tela de usuários ganhou a coluna **Setor**, que vem da
tabela `SETOR` pelo `GET /setores` — não de uma lista escrita dentro do cliente.
Quem está sem setor aparece em vermelho, com um aviso no alto dizendo que essas
pessoas não conseguem entrar.

Conferido na janela de verdade, pelo depurador: JULIANA entra com setor 1 e vê
R$ 2.000,00 pagos no mês; aline entra com setor 2 e vê "Nada foi pago neste mês".
Mesma base, mesma tela, números diferentes.

> **A lista de usuários é a única que não é recortada**, e de propósito: `LOGIN` é
> compartilhada — foi ela que permitiu unificar sem duplicar ninguém — e o nível 3
> já administra a senha de todo mundo. **Nível e setor são coisas diferentes:** o
> nível diz o que a pessoa pode fazer, o setor diz sobre quais registros.

### A API não sobe sem a coluna

Apontar para uma base que não passou pela unificação deixaria a aplicação subir e
quebrar depois, uma consulta por vez, com erro técnico na tela de quem trabalha.
Agora é uma recusa única, ao subir, dizendo o que rodar. As duas metades foram
exercitadas: a API **sobe** sobre uma base preparada só pelo script de instalação,
e **recusa** sobre uma sem a coluna.

Por isso `preparar-base.ps1` e o passo 2 da instalação no servidor passaram a
cuidar das duas colunas. O passo 2 saía assim que encontrava `SENHA_HASH` — o que
agora deixaria a base sem `SETOR_ID` e a API se recusando a subir no passo 3, sem
ninguém entender por quê.

---

## 8. O que ainda falta

- **O Delphi não filtra nada.** Continua na mesma base e mostra tudo. Ou o legado
  sai de cena para esses setores, ou o isolamento é decorativo. A trigger cuida
  para que o que ele gravar não suma, mas o que ele **mostra** continua sendo tudo.
- **Um "total da empresa"**, se um dia existir, não pode ser soma simples: contaria
  em dobro os 9.251 compartilhados.
- **A produção ainda não foi unificada.** O que existe é laboratório.
