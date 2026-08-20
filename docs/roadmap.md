# Roadmap da migração

Plano por etapas, com critérios de pronto, validação e riscos. A arquitetura que sustenta este
plano está em [arquitetura-alvo.md](arquitetura-alvo.md).

> **Situação em 20/08/2026.** As etapas 1 a 6 estão concluídas **no código**, incluindo os
> três relatórios impressos. Falta a metade do critério de pronto da etapa 6 que diz "os
> números batem com os relatórios do legado": os números batem com a grade, e a paridade da
> grade está provada por teste, mas ninguém comparou ainda com a folha que o Delphi imprime.
> O legado
> continua sendo a única versão em produção — o sistema novo roda só em desenvolvimento, sobre
> uma cópia. Nenhum módulo foi cortado, e portanto o critério de pronto nº 2 (uso real por
> duas semanas com o legado ao lado) **ainda não foi cumprido por nenhuma etapa**.
>
> Traduzindo: o código está pronto e provado por teste, mas ninguém usou de verdade ainda.
> Esse é o próximo passo que importa, e ele depende da operadora, não de mais código.

Duas ideias governam a ordem:

**Risco crescente.** Começa por leitura, que não pode corromper nada, e termina em parcelamento
e pagamento em lote, que são os fluxos com mais regra escondida e mais defeito conhecido.

**Reversão barata.** Como legado e novo compartilham a mesma base, reverter uma etapa é voltar
a usar a tela do Delphi. Nenhum dado precisa ser migrado de volta em nenhum momento.

---

## Critérios de pronto

Valem para toda etapa. Uma etapa não está pronta enquanto os cinco não forem verdadeiros:

1. **Paridade provada.** Testes comparando com o legado passam, e as divergências intencionais
   estão declaradas no relatório — nunca silenciadas.
2. **Usado de verdade.** A operadora principal usou o módulo em trabalho real por pelo menos
   duas semanas, com o legado disponível ao lado.
3. **Reversão testada.** Voltar para o Delphi foi exercitado, não apenas planejado.
4. **Documentação em dia.** Se uma regra mudou ou foi esclarecida, `dominio.md` e `fluxos.md`
   refletem isso.
5. **Decisões registradas.** Toda escolha relevante da etapa virou ADR.

O critério 2 é o que costuma ser pulado, e é o mais importante: quem faz 96% dos lançamentos é
uma pessoa só, e o que ela não consegue usar não está pronto, por mais que os testes passem.

---

## Etapa 0 — Melhorias no legado (não depende de nada)

Correções de valor imediato, independentes da migração. Se a migração parar amanhã por qualquer
motivo, estas continuam valendo a pena.

### 0.1 — Só no banco, sem recompilar o Delphi

| Melhoria | Motivo | Risco |
|---|---|---|
| Índice em `REGISTRO_DE_GASTOS (DATA_VENCIMENTO)` e `(DATA_PAGAMENTO)` | toda consulta filtra por data e hoje varre 13.972 linhas | baixo — índice é transparente para a aplicação |
| Corrigir os 3 generators do estoque e ressincronizar | inserção sem ID viola a PK; comprovado | baixo — módulo inativo |
| Normalizar `CHEQUE_COMPENSADO` de `'s'` para `'S'` (9 linhas) | a busca é sensível a caixa e esses registros são invisíveis | baixo |
| Backup por `gbak` no lugar do `CopyFile` | cópia de arquivo com banco aberto pode sair inconsistente | baixo — é script externo |

**Validação:** medir o tempo de uma consulta típica antes e depois do índice, com a mesma
consulta e a mesma base. Não aceitar "ficou mais rápido" sem número. Para o `gbak`, provar o
backup **restaurando-o** — backup não verificado por restauração não é backup.

### 0.2 — Exige recompilar o legado

| Melhoria | Motivo |
|---|---|
| **Laço infinito no pagamento em lote** | um item já pago na grade congela a aplicação |
| Reativar a permissão no botão Alterar | hoje qualquer usuário edita lançamento de outro |
| Tirar os caminhos fixos do backup automático | aponta para a área de trabalho de um usuário |

A correção do laço infinito é de uma linha: em `UfrmLancamentos.pas:436`, o `FDqryLcto.Next`
está dentro do `if PAGO = 0`. Precisa sair para fora do `if`, permanecendo dentro do `while`.

Vale reforçar o cuidado: mexer no legado exige recompilar no RAD Studio 11 e redistribuir o
executável. Precisa ser exercitado em cópia antes, com o cenário exato que hoje trava — uma
grade contendo item pago e item não pago.

### 0.3 — Higiene do repositório

- **`_readme.txt` na raiz é uma nota de resgate de ransomware**, commitada em `b477b5d`. Nenhum
  arquivo cifrado na árvore, é resíduo — mas vale descobrir de onde veio antes de apagar.
- **`config.ini` versionado com `SYSDBA` / `masterkey`** em texto plano.
- **Quatro `.FDB` versionados**, com dados financeiros reais e senhas em texto plano, presentes
  em todo o histórico do Git.

Os dois últimos não se resolvem apagando o arquivo: o conteúdo continua no histórico. Tratar
exige decidir se vale reescrever o histórico do repositório — decisão que precisa de ADR.

---

## Etapa 1 — Fundação

Nada de funcionalidade. Só o terreno.

**Entra:** os três spikes de [arquitetura-alvo.md](arquitetura-alvo.md#antes-de-escrever-o-primeiro-código)
— acesso a dados, convivência com `SENHA_HASH`, base de paridade congelada. Esqueleto da
solução nas quatro camadas, projeto Angular, empacotamento Electron mínimo que abre uma janela,
e a infraestrutura de testes rodando em automação.

**Pronto quando:** um endpoint de saúde responde, o cliente Electron abre e o conjunto de
testes roda do zero em uma máquina limpa. O ADR de acesso a dados (Dapper ou EF Core) está
escrito e decidido por evidência.

**Risco:** o provider Firebird para .NET ter limitação séria com a versão 2.5. É por isso que o
spike vem antes de qualquer compromisso. Se o resultado for ruim, o plano de acesso a dados
muda aqui, quando ainda é barato.

---

## Etapa 2 — Leitura

O novo sistema passa a **consultar**, sem escrever nada. O Delphi continua fazendo tudo.

**Entra:** consulta de lançamentos com todos os filtros de [fluxos.md](fluxos.md#6-consultar-lançamentos),
aviso de vencimentos, consolidado por despesa nos dois modos, e totais de tela.

**Por que primeiro:** é a maior parte do sistema em superfície, e não pode corromper nada. É
onde a equipe aprende o domínio e a infraestrutura de paridade amadurece sem risco.

**Pronto quando:** para o mesmo período e filtros, os resultados batem com os do legado linha a
linha; o total pago acumulado reproduz **R$ 34.501.459,68** sobre a base congelada; os totais
por despesa batem com os registrados em [schema.md](schema.md).

**Como validar:** oráculos 1 e 2 de [arquitetura-alvo.md](arquitetura-alvo.md#testes-de-paridade)
— dados de produção e SQL do legado.

**Riscos:** a troca da coluna de data entre os modos pago e não pago da consulta por despesa é
fácil de perder na reimplementação e passa despercebida se ninguém testar os dois modos.
Os 11 registros com data `30/12/1899` e o `'s'` minúsculo aparecem aqui pela primeira vez.

**Reversão:** parar de usar a tela nova. Não há efeito colateral — nada foi escrito.

---

## Etapa 3 — Cadastros simples

Primeira escrita, no lugar mais barato.

**Entra:** contas, formas de pagamento, despesas e subdespesas. Autenticação com `SENHA_HASH`
conforme a estratégia de convivência.

**Por que aqui:** são poucos registros, mudam raramente, e o estrago de um erro é visível e
reversível à mão. É onde se prova que Delphi e API podem escrever na mesma base sem se
atrapalhar.

**Pronto quando:** criar um cadastro pelo novo sistema e vê-lo aparecer no Delphi, e vice-versa,
sem reiniciar nada. A exclusão de um registro referenciado é recusada com mensagem
compreensível, como no legado.

**Riscos:** o legado esconde menus por nível de acesso; a API precisa impor a mesma regra **no
servidor**, não só na tela. Este é o momento de fechar essa lacuna, e não depois.

**Reversão:** voltar a cadastrar pelo Delphi. Os dados já gravados continuam válidos — estão na
mesma tabela.

---

## Etapa 4 — Lançamento individual

O coração do sistema.

**Entra:** lançar, alterar e excluir uma despesa, com as validações de
[dominio.md](dominio.md#módulo-lançamentos): campos obrigatórios, subdespesa determinando a
despesa, autoria carimbada, confirmação de pagamento.

**Pronto quando:** os testes de paridade cobrem cada regra do módulo; a permissão de alteração
funciona **de verdade** (no legado ela está comentada — divergência intencional a declarar); e
um lançamento criado no novo sistema é indistinguível de um criado no Delphi, campo a campo.

**Riscos:** aqui entra a conversão de dinheiro na borda. Todo valor lido de `FLOAT` vira
`decimal` arredondado; todo valor gravado vai arredondado. Acima de R$ 99.999,99 a coluna ainda
não consegue guardar dois decimais com fidelidade — limitação herdada que precisa estar visível
para quem opera, não escondida.

O outro risco é de fluxo: a operadora tem os atalhos memorizados. `Enter` na busca de subdespesa
abre o seletor, `Enter` na descrição não salva. Quebrar isso custa produtividade real.

**Reversão:** voltar à tela do Delphi. Lançamentos criados pelo novo continuam lá.

---

## Etapa 5 — Operações em lote

Os fluxos mais arriscados, quando a infraestrutura de paridade já está madura.

**Entra:** parcelamento, pagamento em lote e importação por planilha.

**Por que por último:** concentram os defeitos conhecidos e a regra mais escondida. O
parcelamento sozinho gerou 32% da base — 4.441 lançamentos.

**Pronto quando:**

- Parcelar R$ 20.000,00 em 12 gera parcelas que **somam exatamente R$ 20.000,00**, com o resto
  distribuído por regra fixa e documentada. O legado gera R$ 19.999,9995.
- O parcelamento inteiro é **uma transação**: falha no meio não deixa parcela órfã nem o
  original perdido. No legado não é atômico.
- Pagar em lote com um item já pago na lista **conclui** em vez de congelar.
- A importação reproduz a concatenação de linha sem data, a normalização para maiúsculas sem
  acento, e grava tudo como pago com a data histórica da planilha.

**Riscos:** o parcelamento exclui o lançamento original. Qualquer erro aqui apaga dado real.
Precisa ser exercitado exaustivamente em cópia antes de tocar produção, incluindo o caso do
original com cheque, nota fiscal e entrada nulos, onde o legado copia lixo de memória.

**Reversão:** é a etapa com reversão mais delicada, porque as operações são destrutivas por
natureza. Mitigação: backup verificado imediatamente antes de liberar o módulo, e período
inicial com volume pequeno.

---

## Etapa 6 — Relatórios e exportação

**Entra:** os relatórios hoje em FastReport e a exportação para Excel.

**Pronto quando:** os números batem com os relatórios do legado para os mesmos parâmetros, e a
exportação traz as mesmas colunas com formatação brasileira.

**Riscos:** o legado arredonda só na exportação, então a planilha do legado e o banco divergem.
O novo sistema não terá essa divergência — outra correção intencional a declarar.

---

## Etapa 7 — Corte final

**Entra:** desligar o Delphi.

**Pronto quando:** todos os módulos em uso estão migrados e nenhum usuário abre o legado há pelo
menos um mês.

Depois disso, e só depois, abrem-se as decisões que a convivência bloqueava:

- **Corrigir o tipo das colunas monetárias** para `NUMERIC(15,2)`. Impossível antes, porque
  quebra os campos persistentes do Delphi.
- **Atualizar o Firebird** para a série 5, ou avaliar **PostgreSQL** como corte único, com o
  plano de portabilidade já registrado em
  [0005](decisoes/0005-estrategia-de-banco.md#plano-de-portabilidade-para-postgresql-para-a-etapa-3).
- **Apagar a coluna `SENHA`** em texto plano.

O legado não é apagado ao ser desligado. Fica arquivado, com uma cópia do banco daquele
momento, por tempo a combinar.

---

## Riscos que atravessam todas as etapas

**Dependência de uma pessoa.** Quem faz 96% dos lançamentos é a mesma pessoa que valida cada
etapa. Se ela ficar indisponível, a validação para. Mitigação: envolver um segundo usuário
desde a Etapa 2, ainda que só para consulta.

**Migração longa demais.** Conviver dois sistemas custa atenção. Quanto mais tempo, maior a
chance de o projeto perder prioridade e o sistema ficar meio migrado — o pior dos mundos.
Mitigação: etapas curtas, cada uma entregando algo utilizável.

**Escopo crescendo.** O legado tem funcionalidade morta: o teto por subdespesa nunca foi
preenchido em nenhuma das 148 subdespesas. Paridade é com o que se usa, não com o que existe.
Cada recurso morto encontrado é confirmado com o cliente antes de entrar no escopo.

**Alterar o banco durante a convivência.** Só adicionar, nunca alterar tipo nem remover.
Sempre ensaiar em cópia e verificar com o Delphi rodando antes de aplicar.

**Firebird sem correção de segurança.** Aceito enquanto o banco estiver em rede local. Se for
exposto para fora, a atualização deixa de ser opcional e passa à frente do roadmap.

---

## Ordem resumida

```
  Etapa 0   melhorias no legado         independente, pode começar já
  Etapa 1   fundação e spikes           sem funcionalidade
  Etapa 2   leitura                     risco zero de corrupção
  Etapa 3   cadastros simples           primeira escrita
  Etapa 4   lançamento individual       o coração
  Etapa 5   operações em lote           os fluxos mais arriscados
  Etapa 6   relatórios e exportação
  Etapa 7   corte final                 desliga o Delphi
            -------------------------------------------------
            depois: tipos monetários, Firebird 5 ou PostgreSQL
```

Não há estimativa de prazo neste documento de propósito. As etapas 0, 1 e 2 podem ser
dimensionadas com o que já se sabe; da 3 em diante, a estimativa depende do resultado dos
spikes e do ritmo real de validação com quem usa. Estimar agora seria inventar número.
