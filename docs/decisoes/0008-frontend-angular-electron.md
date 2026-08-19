# 0008 — Frontend em Angular, empacotado com Electron

- **Situação:** Aceita
- **Data:** 2026-08-19

## Contexto

O requisito era frontend moderno empacotado com Electron, com React sugerido mas em aberto
("React ou o que você justificar").

O que este sistema é, na prática: **formulários e uma grade densa**. A tela central mostra
muitas colunas e muitas linhas ao mesmo tempo, com cor comunicando estado — pago em cinza,
aguardando liberação em roxo. A operadora principal responde por **96% dos 13.972 lançamentos**
e trabalha por teclado, com atalhos que já são reflexo.

Não há requisito de animação, de renderização criativa, de tempo real ou de escala. Há
requisito de **densidade de informação, entrada rápida por teclado e correção**.

O mantenedor é uma pessoa, em transição de Delphi para C#/Angular, e há outro projeto Angular
em andamento na mesma máquina.

## Alternativas consideradas

**React.** Ecossistema maior, mais material de aprendizado, mais gente no mercado. O custo, no
entanto, é que React é uma biblioteca de renderização, não um framework: roteamento, estado,
formulários, requisições HTTP e tabela são escolhas separadas, cada uma com várias opções
concorrentes. Para uma equipe, isso é flexibilidade. Para uma pessoa mantendo um sistema por
anos, cada escolha vira uma decisão que envelhece sozinha, e o conjunto delas é exatamente o
tipo de dívida que fez o legado chegar onde chegou.

**Svelte, Solid, Vue.** Bons frameworks, ergonomia agradável, mas nenhum resolve um problema
que este sistema tenha, e todos abrem uma terceira frente de aprendizado.

**Manter VCL e só trocar o banco.** Descartado: não atende ao requisito de modernização e
mantém a arquitetura de duas camadas com regra de negócio na interface, que é a origem de boa
parte dos defeitos catalogados.

## Decisão

O frontend é escrito em **Angular** e empacotado com **Electron**.

Os motivos:

**Vem com as decisões tomadas.** Roteamento, formulários reativos, cliente HTTP e injeção de
dependência fazem parte do framework. Para um mantenedor solo, não ter que escolher — nem
revisar a escolha a cada dois anos — vale mais do que a flexibilidade que se perde.

**TypeScript não é opcional.** Coerente com o que motivou toda esta migração: o defeito central
do legado foi um tipo errado que passou três anos sem ser notado.

**Formulários reativos são o ponto forte do framework, e este sistema é formulários.** Validação
declarativa, estado de formulário explícito e composição — tudo o que hoje está espalhado em
eventos `OnExit` e `OnKeyPress` no Delphi.

**Simetria com o backend.** Injeção de dependência, serviços e organização por módulos são o
mesmo modelo mental do .NET escolhido em [0007](0007-backend-dotnet.md). Um único conjunto de
conceitos dos dois lados reduz o custo de troca de contexto de quem mantém sozinho.

**Concentra o aprendizado em andamento** em vez de abrir uma frente paralela.

**Densidade e teclado.** O CDK traz rolagem virtual para a grade e um modelo de acessibilidade
e foco que ajuda a preservar os atalhos do legado — que são produtividade real, não detalhe.

React não seria uma escolha errada; seria uma escolha que exige mais decisões de arquitetura
para chegar ao mesmo lugar, e essas decisões recairiam sobre uma pessoa só.

### Sobre o Electron

Electron atende ao pedido e faz sentido aqui: o sistema é usado em rede local, por poucos
usuários, com necessidade de integração com o sistema de arquivos, impressão e planilhas —
tudo o que hoje é feito por automação OLE com o Excel.

O custo honesto é conhecido: o pacote fica na casa das centenas de megabytes, e atualização e
instalação passam a ser problema do projeto. As armadilhas já mapeadas estão registradas em
`.claude/agents/dev-frontend.md` — `ELECTRON_RUN_AS_NODE` herdado do ambiente, configuração do
usuário obrigatoriamente em `userData`, e instalador de clique único sem elevação.

Uma vantagem que compensa parte do custo: como o Angular roda igualmente no navegador, se algum
dia a distribuição desktop deixar de fazer sentido, o mesmo código serve como aplicação web sem
reescrita.

## Consequências

**Mais fácil:** manter um único vocabulário técnico entre backend e frontend; escrever
formulários complexos sem montar infraestrutura; preservar o comportamento de teclado que a
operadora já tem memorizado.

**Mais difícil:** a curva inicial do Angular é mais íngreme que a do React, e a comunidade em
português é menor. Empacotar e atualizar via Electron é trabalho recorrente que hoje não existe.

**Passa a ser obrigatório:** preservar os atalhos e o fluxo de teclado do legado, e o
vocabulário das telas — despesa e subdespesa, não categoria e subcategoria. Mudanças de fluxo
precisam de motivo melhor do que modernidade. E inspecionar a tela renderizada de verdade
antes de considerar algo pronto: compilar sem erro não prova que a tela está certa.
