# Instalar no notebook da operadora

Roteiro do **primeiro teste em campo**: API, banco e aplicativo na mesma máquina, rodando
sobre uma **cópia** do banco de produção.

> **O que ela lançar neste teste não aparece no sistema antigo, e o sistema antigo continua
> intocado.** É de propósito: a ideia é ela usar a tela de verdade sem que um engano custe
> um lançamento real. A convivência sobre a base de produção é o passo seguinte, e depende
> de você aprovar.

---

## O que precisa existir no notebook

| Item | Como conferir |
|---|---|
| **Firebird 2.5** | Já está lá se o sistema antigo roda nessa máquina |
| **.NET** | **Não precisa.** A API vai *self-contained*, com o runtime dentro |
| **fbclient.dll** | **Não precisa.** O acesso é pelo provedor gerenciado |
| Privilégio de Administrador | Só para registrar o serviço, uma vez |

---

## Na máquina de desenvolvimento

```powershell
cd "C:\PROGRAMAS\V OFICIAL"

# 1. API self-contained -> instalacao\publicado (uns 113 MB)
.\instalacao\1-publicar-api.ps1

# 2. Instalador do cliente -> cliente\agenda-desktop\instalador\ (uns 78 MB)
cd cliente\agenda-desktop
npm run empacotar
```

Leve para o notebook, num pen drive ou pasta compartilhada:

- a pasta `instalacao` **inteira** (com `publicado` dentro)
- `cliente\agenda-desktop\instalador\AgendaFinanceira-Instalador-1.0.0.exe`

---

## No notebook

### 1. A API, como serviço

PowerShell **como Administrador**, apontando para o banco que o sistema antigo usa:

```powershell
cd C:\onde\voce\copiou\instalacao
.\2-instalar-no-notebook.ps1 -BancoDeOrigem "C:\caminho\do\DADOS_12_23.FDB"
```

O script mostra o banco de origem — tamanho e data — antes de qualquer coisa, e **não escreve
nele**. A cópia é feita pelo arquivo e só depois o `gbak` roda sobre a cópia: conectar à
origem pelo servidor avança os contadores de transação no cabeçalho.

Se já houver uma cópia de trabalho, ele **mostra quantos lançamentos e usuários ela tem** e
pergunta antes de substituir. A contagem é o que permite reconhecer se é a base certa — o
nome do arquivo parece certo mesmo quando aponta para o lugar errado.

Ao final ele confere que a API **responde de verdade**, não apenas que o serviço ficou
`Running`. Um serviço pode estar no ar com a aplicação morta dentro dele.

### 2. O cliente

Duplo clique em `AgendaFinanceira-Instalador-1.0.0.exe`. Instala para o usuário, sem pedir
elevação e sem perguntar nada. Cria atalho na área de trabalho e no menu Iniciar.

### 3. Conferir

```powershell
.\conferir-estado.ps1
```

Não altera nada. Verifica o serviço, a API, uma chamada que **passa pelo banco**, o cliente e
o Firebird — e quando um cmdlet devolve vazio, tenta uma segunda via, porque sem elevação
vários deles devolvem vazio em vez de dizer que faltou permissão.

---

## Usuários

São os mesmos do sistema antigo, com as mesmas senhas: a cópia carrega a tabela `LOGIN`
inteira. Quem entrar pela primeira vez pelo sistema novo tem o hash da senha gravado naquele
momento, e a senha em texto plano continua lá para o Delphi.

---

## Se der errado

**A API não sobe.** Rode na mão para ver a mensagem, que o serviço engole:

```powershell
cd C:\onde\voce\copiou\instalacao\publicado
$env:ASPNETCORE_ENVIRONMENT = 'Production'; .\AgendaFinanceira.Api.exe
```

**O aplicativo abre mas não entra.** A tela de login mostra o endereço do servidor no painel
verde à esquerda, com um "Alterar" ao lado. Deve estar `http://localhost:5199`.

**Tela em branco ao abrir.** Ctrl+R. Se persistir, desinstale e instale de novo — a
configuração do usuário fica em `userData` e sobrevive.

---

## Desfazer

```powershell
# Remove o servico. Nao apaga a copia do banco nem o cliente.
.\desinstalar-api.ps1

# Para apagar tambem a copia (mostra o que vai apagar antes de perguntar):
.\desinstalar-api.ps1 -ApagarTambemOBanco
```

O cliente sai pelo Painel de Controle > Aplicativos.

---

## O que foi verificado antes de este roteiro existir

Nada aqui é suposição. Na máquina de desenvolvimento, com o aplicativo **empacotado de
verdade** e a API **publicada self-contained**:

| Verificação | Resultado |
|---|---|
| App empacotado carrega de `file://` | sim, dentro do `app.asar`, em `#/login` |
| Login pelo app empacotado | passa — é o teste do CORS |
| Navegação entre telas | painel, lançamentos, usuários e cadastros, sem erro de console |
| Ponte de impressão exposta | `window.agenda.imprimir` e `salvarPdf` presentes |
| `require` no renderizador | indisponível, como deve ser |
| Executável publicado sobe sozinho | sim, lendo `appsettings.Production.json` |
| App empacotado contra a API publicada | login e painel com os números reais |

### As três armadilhas que só apareceriam instalado

**CORS.** Empacotado, a página vem de `file://` e o Chromium envia `Origin: null`. Medido: sem
`"null"` na lista de origens, a API responde 200 **sem** o `Access-Control-Allow-Origin` e o
navegador descarta a resposta. Funcionaria no desenvolvimento e falharia só na máquina dela.

**Rotas.** Sob `file://`, a estratégia normal do Angular chamaria `history.pushState` para um
caminho que não existe no disco. Resolvido com `withHashLocation()`, ligado **também em
desenvolvimento** para não haver dois comportamentos.

**NSIS.** `oneClick: true` com `allowElevation: false`. Com `oneClick: false` o instalador
pergunta onde instalar e, em modo silencioso numa conta de administrador, responde sozinho:
instala para a máquina inteira, e a partir daí toda atualização sem elevação falha calada.
