# Agenda Financeira — sistema legado e migração

Sistema de **contas a pagar** em Delphi + Firebird, em produção desde março de 2022,
usado pelo grupo Juliatti de Carvalho. Este repositório contém o legado e, a partir da
migração, também a nova stack.

> **Leia antes de mexer em qualquer coisa:** o banco tem três anos de dados financeiros
> reais (13.972 lançamentos, R$ 34,5 milhões pagos). Ver [Restrições](#restrições).

---

## O que o sistema faz

Registra despesas a pagar, classificadas em dois níveis — **Despesa** (`CATEGORIA`) e
**Subdespesa** (`SUBCATEGORIA`) —, vinculadas a uma **Conta** (banco ou pessoa) e a uma
**Forma de Pagamento**. Cada lançamento tem valor previsto e valor pago, data de vencimento
e data de pagamento, e pode carregar número de cheque, nota fiscal e um status de liberação.

As operações que definem o sistema:

- **Lançar** uma despesa, opcionalmente já quitada
- **Parcelar** um lançamento em N vezes (gera N cópias e apaga o original)
- **Pagar em lote** tudo que está em tela
- **Importar** um lote de pagamentos de uma planilha Excel
- **Consultar** por descrição, NF, cheque, status, faixa de valor ou período
- **Relatórios** consolidados por despesa e subdespesa (FastReport) e exportação para Excel

Documentação completa do domínio em [docs/dominio.md](docs/dominio.md) e dos fluxos ponta a
ponta em [docs/fluxos.md](docs/fluxos.md).

---

## Arquitetura atual (legado)

Aplicação VCL monolítica, cliente-servidor de duas camadas. Não há camada de serviço: os
formulários falam direto com o banco por `TFDQuery`, e as regras de negócio vivem nos
eventos de interface.

| Item | Valor |
|---|---|
| Linguagem / IDE | Delphi 11 Alexandria (ProjectVersion 19.5), VCL, Win32 |
| Acesso a dados | FireDAC, `DriverID=FB` |
| Banco | Firebird 2.5 (ODS 11.2), **Dialect 3**, charset **WIN1252** |
| Relatórios | FastReport (`.fr3` ao lado do executável) |
| Integrações | **Nenhuma.** Só Excel via automação OLE |
| Configuração | `config.ini` ao lado do executável |
| Projeto | `AGENDA FINANCEIRA ITAPUA/PfrmPrincipal.dpr` |

Não existe DataModule: a única `TFDConnection` mora em `UfrmPrincipal` e é reconfigurada em
tempo de execução lendo o `config.ini` **por índice** de `Params.Strings[0..3]`.

Os DCUs de ACBr/NFe em `Win32/Debug` são resíduo de outra compilação — nenhum fonte os usa.

### Mapa das telas

| Unit | Tela | Papel |
|---|---|---|
| `UfrmPrincipal` | Menu principal | Conexão, login, aviso de vencimentos, backup |
| `UfrmLancamentos` | Lançamentos | **Núcleo do sistema** — CRUD, parcelamento, lote, consultas |
| `UfrmLancamentosEmLote` | Importar planilha | Carga de pagamentos via Excel |
| `UcategoriaGeral` | Despesas/Subdespesas | Cadastro dos dois níveis |
| `UpesquisaCategoria` | Consulta por despesa | Consolidação por subdespesa e período |
| `UfrmPesqDespesas` | Busca de subdespesa | Seletor usado por outras telas |
| `UConta`, `UformaPgto` | Cadastros | Contas e formas de pagamento |
| `Ulogin`, `UcadastroUser` | Acesso | Login e usuários |
| `UbackUp` | Backup | Cópia de arquivo |
| Módulo de estoque | Entrada NF, Saída, Produtos | **Abandonado** — ver abaixo |

### Módulo de estoque: abandonado

As telas de Entrada de NF, Saída de Produtos, Produtos e Movimentação continuam no projeto,
mas **toda a gravação de saldo está comentada no código** e `MOVIMENTACAO_PRODUTO` está vazia.
Decisão do cliente: não migrar. Tratar como legado inativo.

---

## Restrições

**O banco legado é sagrado.** Regras não negociáveis:

1. **Nunca** executar DDL ou DML em `Win32/*/Dados/*.FDB`. Trabalhe sempre sobre uma cópia.
2. Gerar a cópia com `gbak` (backup + restore), não copiando o arquivo — ver
   [comandos úteis](#comandos-úteis).
3. Conectar ao banco de origem pelo servidor (`localhost:caminho`) **avança os contadores de
   transação no cabeçalho** e altera a data do arquivo. Para leitura sem escrita nenhuma,
   copie o arquivo antes e conecte só à cópia.
4. Qualquer script destrutivo mostra o que vai destruir **antes** de perguntar, e confere o
   código de saída de cada passo.
5. `isql -i` sem `-v ON_ERROR_STOP=1` **segue após erros e termina com código 0**. Sempre usar.

**Dados sensíveis:** `LOGIN.SENHA` está em texto plano e `FORNECEDOR.CNPJ` tem 157 registros
reais. Toda base de desenvolvimento precisa ser anonimizada antes de sair da máquina.

### Pendências de segurança do repositório

Encontradas na engenharia reversa e ainda **não resolvidas**:

1. **`_readme.txt` na raiz é uma nota de resgate de ransomware** (família STOP/Djvu), commitada
   em `b477b5d "Projeto enviado"`. Nenhum arquivo cifrado foi encontrado na árvore — é
   resíduo. Mas indica que alguma máquina do ambiente foi comprometida, e vale descobrir de
   onde veio antes de simplesmente apagar o arquivo.
2. **`config.ini` versionado com `SYSDBA` / `masterkey`** em texto plano, junto do caminho
   absoluto do banco. Segredo em arquivo versionado acompanha qualquer cópia do repositório.
3. **Senha do banco é a padrão de instalação** do Firebird.
4. **Os arquivos `.FDB` estão versionados no Git.** São quatro bancos de 5 a 7 MB com dados
   financeiros reais e senhas em texto plano, presentes em todo o histórico. Além de inchar o
   repositório, isso significa que qualquer cópia do repositório carrega a base de produção.
   Note que operações de leitura que passam pelo servidor Firebird alteram o cabeçalho do
   arquivo, então esses bancos aparecem como modificados no `git status` com frequência.

---

## Convenções

- **Português do Brasil** em tudo: documentação, comentários, mensagens de commit e nomes de
  domínio. Sem acentos no corpo das mensagens de commit.
- Mensagem de commit longa vai em arquivo, com `git commit -F` (aspas na `-m` quebram no
  PowerShell).
- **Só commitar quando solicitado.** Push é do Bruno.
- **Dinheiro nunca em ponto flutuante.** Ver [o defeito central](#o-defeito-central).
- Data de calendário em tipo de data pura, nunca `DateTime` convertido para UTC — no Brasil
  `01/07` vira `30/06`.
- Nomes de tabela e coluna do legado são preservados na documentação em MAIÚSCULAS, como
  aparecem no banco.

### Antes de entregar

Exercitar o caminho real antes de pedir que alguém rode qualquer coisa. Quando não for
possível executar, ler o fluxo rastreando estado compartilhado. Testar a costura entre as
peças, não só cada peça isolada. Nunca afirmar estado do sistema a partir de um único
comando — confirmar por segunda via.

---

## O defeito central

`REGISTRO_DE_GASTOS.VALOR_PAGO`, `VALOR_PREVISTO` e `SUBCATEGORIA.VALOR_MAXIMO` são
**`FLOAT`** — precisão simples, 32 bits, ~7 dígitos significativos. Não é teoria: 471
lançamentos têm valor previsto que não fecha em dois decimais, e 30 estão acima de
R$ 99.999,99, onde a perda é garantida.

```
ID=19035  gravado=147059.765625   pretendido=147059.77
ID=17014  gravado=  1666.666626   pretendido=  1666.67   (parcela de 20.000 / 12)
```

O módulo de estoque — o abandonado — usa `NUMERIC(15,2)` corretamente. Só o módulo em
produção errou.

**Toda a nova stack usa decimal.** Nenhum valor monetário passa por `float`, `double`,
`single` ou `real` em nenhuma camada, do banco ao JSON à tela.

---

## Comandos úteis

Caminhos do Firebird nesta máquina:

```
C:\Program Files\Firebird\Firebird_2_5\bin\{isql,gbak,gstat,gfix}.exe
```

Criar uma cópia de trabalho a partir do banco de produção:

```powershell
$fb = "C:\Program Files\Firebird\Firebird_2_5\bin"
$origem = "C:\PROGRAMAS\V OFICIAL\AGENDA FINANCEIRA ITAPUA\Win32\Debug\Dados\DADOS_12_23.FDB"
& "$fb\gbak.exe" -b -user SYSDBA -password masterkey "localhost:$origem" ".\copia.fbk"
& "$fb\gbak.exe" -c -user SYSDBA -password masterkey ".\copia.fbk" "localhost:$PWD\COPIA_TRABALHO.FDB"
```

Rodar consulta na cópia (sempre por arquivo, nunca `-c`):

```powershell
& "$fb\isql.exe" -user SYSDBA -password masterkey -i consulta.sql -o saida.txt "localhost:$PWD\COPIA_TRABALHO.FDB"
```

Extrair o DDL completo:

```powershell
& "$fb\isql.exe" -x -user SYSDBA -password masterkey -o schema.sql "localhost:$PWD\COPIA_TRABALHO.FDB"
```

Ver cabeçalho do banco (dialect, ODS, page size) — lê o arquivo direto, sem servidor:

```powershell
& "$fb\gstat.exe" -h -user SYSDBA -password masterkey "caminho\do\banco.FDB"
```

Compilar o legado: abrir `AGENDA FINANCEIRA ITAPUA/PfrmPrincipal.dproj` no RAD Studio 11.
Saída em `Win32\Debug` ou `Win32\Release`, junto do `config.ini` e dos `.fr3`.

### Rodar o sistema novo

Um comando sobe tudo — API, cliente e a janela do aplicativo:

```powershell
cd "C:\PROGRAMAS\V OFICIAL"
.\iniciar-desenvolvimento.ps1
```

Ele confere antes o que costuma faltar (banco de desenvolvimento, serviço do Firebird, chave
de assinatura), avisa com a solução quando algo está ausente, e só então sobe. Para encerrar:

```powershell
.\parar-desenvolvimento.ps1
```

Usuários no banco de desenvolvimento, para exercitar os três níveis:

| Usuário | Senha | Nível | O que pode |
|---|---|---|---|
| `DEMO` | `demo123` | 3 | tudo, inclusive importar planilha |
| `OUTROOP` | `op123` | 2 | opera, mas não administra |
| `SOCONSULTA` | `ver123` | 1 | só consulta |

São usuários de teste criados numa **cópia** do banco. As senhas reais de produção não
aparecem em lugar nenhum do repositório.

### Configuração da API

A API **não sobe sem a chave de assinatura dos tokens**, e ela nunca fica no repositório.
Configure uma vez por máquina:

```powershell
cd "C:\PROGRAMAS\V OFICIAL\src\AgendaFinanceira.Api"
dotnet user-secrets set "Jwt:Chave" "<48 bytes aleatórios em base64>"
```

Se a chave faltar, a mensagem de erro já sugere uma pronta para uso. Alternativa por variável
de ambiente: `setx Jwt__Chave "<chave>"`.

Rodar a API e abrir a documentação:

```powershell
cd "C:\PROGRAMAS\V OFICIAL\src\AgendaFinanceira.Api"
dotnet run --urls http://localhost:5199
```

Depois é só abrir `http://localhost:5199`, que redireciona para o Swagger. Para chamar os
endpoints protegidos: `POST /sessao`, copiar o `token` e informar em **Authorize**.

Rodar os testes:

```powershell
cd "C:\PROGRAMAS\V OFICIAL"
dotnet test
```

### Bases de trabalho

Nenhuma delas fica no repositório, e nenhuma é a produção:

```
C:\PROGRAMAS\AgendaFinanceira-paridade\
    base-paridade-2026-08-19.fbk    backup lógico, a fonte de tudo
    BASE_PARIDADE.FDB               referência IMUTÁVEL dos testes de leitura
    MOLDE_ESCRITA.FDB               igual, mais a coluna SENHA_HASH
    DESENVOLVIMENTO.FDB             onde a API roda; pode ser sujada à vontade
```

Detalhes e números de referência em [docs/paridade-referencia.md](docs/paridade-referencia.md).

---

## Estado da migração

**O legado continua sendo a única versão em produção.** O sistema novo roda apenas em
desenvolvimento, sobre uma cópia do banco. Nada foi cortado ainda.

| Etapa do [roadmap](docs/roadmap.md) | Situação |
|---|---|
| 0 — Melhorias no legado | **Pendente** — não depende de nada, pode começar quando quiser |
| 1 — Fundação e spikes | **Concluída** |
| 2 — Leitura | **Concluída** — paridade provada contra a base real |
| 3 — Cadastros e autenticação | **Concluída** — convivência com o Delphi verificada |
| 4 — Lançamento individual | **Concluída** |
| 5 — Operações em lote | **Concluída** — parcelamento, pagamento em lote, importação |
| 6 — Relatórios e exportação | **Concluída** — consolidado por despesa e exportação para planilha |
| 7 — Corte final | Não iniciada |

### O que existe hoje

```
src/AgendaFinanceira.Dominio/          Dinheiro, Lancamento, regras, validações
src/AgendaFinanceira.Infraestrutura/   repositórios Dapper, leitor de planilha, BCrypt
src/AgendaFinanceira.Api/              ASP.NET Core + Swagger + JWT
src/AgendaFinanceira.SpikeFirebird/    spike de acesso a dados, ainda roda
testes/AgendaFinanceira.Testes/        181 testes, 26 de paridade contra a base real
cliente/agenda-web/                    Angular 21 zoneless
cliente/agenda-desktop/                Electron
```

**Telas prontas:** login, grade de lançamentos (com aviso de vencimentos, seleção, pagamento
em lote, parcelamento, exportação para planilha), formulário de lançamento, consolidado por
despesa, cadastros (contas, formas de pagamento, despesas e subdespesas) e importação de
planilha.

**Falta no cliente:** o empacotamento em instalador.

**O servidor está completo** para o módulo financeiro.

**`prompt()` não existe no Electron.** Ele lança `prompt() is not supported.` e a ação morre
sem aviso — funciona no navegador e falha no aplicativo, que é o pior tipo de defeito.
`alert()` e `confirm()` funcionam normalmente. Onde for preciso pedir um valor, use um
`<dialog>`, como faz o parcelamento em `lancamentos.html`. Verificado na janela real.

### Pendências que valem lembrar

- **Etapa 0 do roadmap** continua sem dono e não depende da migração. A correção de uma linha
  que resolve o laço infinito do pagamento em lote está em `UfrmLancamentos.pas:436`.
- **Repositório é público no GitHub** e carrega no histórico os `.FDB` com dados reais e o
  `config.ini` com `SYSDBA`/`masterkey`. Ver [Pendências de segurança](#pendências-de-segurança-do-repositório).
- **Endpoints de escrita exigem token**, mas não há revogação: trocar a senha de alguém não
  invalida os tokens já emitidos até expirarem (12 h).

### Arquitetura decidida

| Camada | Escolha | ADR |
|---|---|---|
| Banco | **Manter Firebird** durante a convivência; PostgreSQL só após desligar o legado | [0005](docs/decisoes/0005-estrategia-de-banco.md) |
| Dinheiro | `decimal` em todas as camadas, nunca ponto flutuante | [0006](docs/decisoes/0006-dinheiro-em-decimal.md) |
| Backend | **C# / .NET** com ASP.NET Core | [0007](docs/decisoes/0007-backend-dotnet.md) |
| Frontend | **Angular** empacotado com **Electron** | [0008](docs/decisoes/0008-frontend-angular-electron.md) |

A estratégia é **strangler pattern**: o novo convive com o legado, módulo a módulo, com testes
de paridade provando comportamento idêntico antes de cada corte. Nada de big bang.

O que torna a convivência simples é a decisão do banco: legado e novo compartilham **a mesma
base Firebird**, sem sincronização. Reverter um módulo é repontar a tela, não migrar dados de
volta.

**Antes do primeiro código**, três verificações: spike de acesso a dados (Dapper × EF Core),
spike de convivência (coluna `SENHA_HASH` sem quebrar o Delphi) e congelamento da base de
paridade. Detalhes em [docs/arquitetura-alvo.md](docs/arquitetura-alvo.md).

### Defeitos conhecidos do legado

Levantamento completo em [docs/dominio.md](docs/dominio.md) e
[docs/triggers-e-procedures.md](docs/triggers-e-procedures.md). Os que mudam decisões:

1. **Laço infinito** no pagamento em lote — `Next` está dentro do `if PAGO = 0`, então um
   registro já pago na grade trava a aplicação
   (`UfrmLancamentos.pas:426`).
2. **Dinheiro em `FLOAT`** — ver acima.
3. **Generators compartilhados** — `ITEM_NF_BI`, `SAIDA_PRODUTO_BI` e `TIPO_PRODUTO_BI` usam
   `GEN_CADASTRO_NF_ID`. Qualquer inserção que não venha do FireDAC viola a PK. Comprovado.
4. **Transações decorativas** — `UpdateOptions.AutoCommitUpdates = True` faz cada `Post`
   confirmar sozinho; o parcelamento (N inserções + 1 exclusão) não é atômico.
5. **Backup por cópia de arquivo** com o banco aberto, inclusive no timer automático, com
   caminhos fixos no código.
6. **Senhas em texto plano**, comparadas no cliente após trazer a tabela `LOGIN` inteira.
7. **Sem índice em coluna de data**, embora toda consulta filtre por data.
