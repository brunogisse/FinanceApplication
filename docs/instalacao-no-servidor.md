# Implantação do sistema

Como colocar a Agenda Financeira em produção: o que instalar no servidor, o que instalar em
cada estação, e em que ordem.

> **Nada aqui desliga o Delphi.** Ao terminar, os dois sistemas estarão no ar sobre a mesma
> base — que é o que o [ADR 0005](decisoes/0005-estrategia-de-banco.md) prevê. Desligar o
> legado é a [etapa 7](roadmap.md#etapa-7--corte-final), outro assunto.

---

## 1. O desenho: o que roda onde

```
        SERVIDOR                                    ESTAÇÃO (cada uma)
  ┌──────────────────────────┐                ┌──────────────────────────┐
  │                          │                │                          │
  │   Firebird 2.5           │                │   Agenda Financeira      │
  │        │                 │                │   (o aplicativo)         │
  │        │ disco local     │                │                          │
  │   FINANCES.FDB           │                │   sabe UMA coisa:        │
  │        ▲                 │                │   http://servidor:5199   │
  │        │                 │                │                          │
  │   API (serviço Windows)  │◄───── rede ────┤                          │
  │   porta 5199             │   porta 5199   │                          │
  │                          │                │                          │
  └──────────────────────────┘                └──────────────────────────┘
             ▲
             │ o Delphi continua entrando direto no Firebird, como sempre
             │
        ESTAÇÃO com o sistema antigo
```

| Onde | O que se instala | Quantas vezes |
|---|---|---|
| **Servidor** | Firebird 2.5, o `.FDB`, e a **API** como serviço | uma vez |
| **Estação** | só o **aplicativo** (`AgendaFinanceira-Instalador-1.0.0.exe`) | uma por máquina |

**Três coisas que decorrem disso, e evitam a maior parte dos enganos:**

1. **A API fica no servidor, não na estação.** Ela é quem fala com o banco. Se cada estação
   tivesse a sua, seriam vários pontos de escrita no mesmo arquivo e várias configurações
   para manter em sincronia — cada uma um lugar a mais para errar o caminho do banco.

2. **A estação não sabe o que é Firebird.** Ela não precisa do cliente do Firebird, nem do
   caminho do banco, nem da senha dele. Sabe um endereço `http://...` e mais nada. Mudar o
   banco de lugar depois mexe só no servidor; nenhuma estação é tocada.

3. **O aplicativo se instala em cada máquina, não se compartilha por atalho.** Um atalho para
   o `.exe` numa pasta de rede não faz o programa rodar no servidor — o Windows traz os
   180 MB pela rede e executa na estação, toda vez que alguém abre.

---

## 2. Antes de começar

- [ ] Saber **qual máquina** é o servidor: a que hospeda o `.FDB` que o Delphi usa hoje.
      Não sabe? Abra o `config.ini` ao lado do executável do Delphi numa estação — a linha
      `Database=` diz o caminho e `Server=` diz a máquina.
- [ ] **Administrador** nessa máquina.
- [ ] O servidor precisa de **nome fixo ou IP fixo**. Se o IP mudar, todas as estações param
      juntas. Reserve no roteador, ou use o nome da máquina.
- [ ] **250 MB** de disco livre no servidor, mais o tamanho do banco.
- [ ] O pacote de instalação, montado por `instalacao\1-publicar-api.ps1`.

**Decisões já tomadas** (05/09/2026), porque mudam os passos:

| | |
|---|---|
| A API roda | na mesma máquina do Firebird |
| Primeiro sobe sobre | uma **cópia**; a produção só na fase D |
| Bases | só a `FINANCES` agora; a de faturamento repete tudo depois |

---

## 3. Fase A — No servidor: proteger o que já existe

Antes de instalar coisa nenhuma. O Delphi continua rodando normalmente.

**A.1 — Backup da produção.** Por `gbak`, nunca copiando o arquivo: cópia leva junto o lixo de
páginas e qualquer estrago que já estivesse lá.

```powershell
$fb = "C:\Program Files\Firebird\Firebird_2_5\bin"
$hoje = Get-Date -Format 'yyyy-MM-dd_HHmm'
& "$fb\gbak.exe" -b -user SYSDBA -password masterkey `
  "localhost:C:\caminho\da\PRODUCAO.FDB" "D:\Backups\producao-$hoje.fbk"
```

Confira o **efeito**, não o código de saída: o `.fbk` existe? tem tamanho compatível?

**A.2 — Anote os números de hoje.** São a régua para conferir tudo depois.

```sql
SELECT COUNT(*) AS LANCAMENTOS, SUM(VALOR_PAGO) AS SOMA_PAGO,
       SUM(VALOR_PREVISTO) AS SOMA_PREVISTO FROM REGISTRO_DE_GASTOS;
SELECT COUNT(*) AS USUARIOS FROM LOGIN;
```

Rode com `isql -b -i consulta.sql -o saida.txt`. **Apague o arquivo de saída antes** — o
`isql -o` acrescenta em vez de sobrescrever, e você leria o resultado da rodada anterior
achando que é o de agora.

---

## 4. Fase B — No servidor: subir a API sobre uma cópia

Ainda sem encostar na base de produção.

**B.1 — Leve o pacote** para um disco local do servidor. Sugestão: `C:\AgendaApi`.
Nunca instalar direto de pasta de rede: se a conexão cair, o serviço fica apontando para um
caminho que some e a API para de subir sem dizer por quê.

**B.2 — Gere a cópia de trabalho:**

```powershell
cd C:\AgendaApi\instalacao
.\preparar-base.ps1 -Origem "C:\caminho\da\PRODUCAO.FDB" -Nome FINANCES
```

O script copia o **arquivo** antes de conectar em qualquer coisa (conectar avança os
contadores de transação da produção), roda `gbak` backup + restore, cria a coluna
`SENHA_HASH` e confere **contagens e somas** contra a origem. Divergiu, ele para.

**B.3 — Registre a API como serviço:**

```powershell
.\2-instalar-no-notebook.ps1 -BancoDeOrigem "C:\AgendaFinanceira\FINANCES.FDB" -NomeDaBase FINANCES
```

> O nome do arquivo diz "notebook" por herança; serve para qualquer máquina. Ele gera a chave
> que assina as sessões, registra o serviço para subir junto com a máquina, e sobe.

**B.4 — Abra a API para a rede.** *Este passo não existe numa instalação de máquina única, e
é o que mais se esquece.*

Edite `C:\AgendaApi\instalacao\publicado\appsettings.Production.json`:

```json
{
  "Banco": { "Caminho": "C:/AgendaFinanceira/FINANCES.FDB" },
  "Cors":  { "Origens": [ "http://localhost:4200", "null" ] },
  "Jwt":   { "Chave": "…não mexa…" },
  "Urls":  "http://0.0.0.0:5199"
}
```

Três armadilhas, todas já pagas neste projeto:

- **`Urls` tem de sair de `localhost`.** Em `localhost` a API responde só na própria máquina.
  As estações levam "não foi possível alcançar o servidor" e ninguém desconfia do servidor,
  porque nele tudo funciona.
- **`"null"` fica na lista de CORS.** O aplicativo empacotado carrega de `file://` e o
  Chromium manda `Origin: null` — a palavra, não a ausência do cabeçalho. Sem ela a API
  responde 200 sem o cabeçalho de liberação e o cliente descarta a resposta: funciona no
  desenvolvimento e não funciona no instalado.
- **Não troque a chave `Jwt`.** Trocar derruba todas as sessões abertas.

**B.5 — Libere a porta no firewall do servidor:**

```powershell
New-NetFirewallRule -DisplayName "Agenda Financeira - API" -Direction Inbound `
  -Protocol TCP -LocalPort 5199 -Action Allow -Profile Domain,Private
```

`Public` fica de fora de propósito: o Firebird 2.5 não recebe mais correção de segurança, e o
[roadmap](roadmap.md) só aceita isso enquanto tudo estiver em rede local.

**B.6 — Reinicie e prove, no servidor:**

```powershell
.\REINICIAR-API.cmd
```

Ele pergunta ao `/saude` **qual arquivo** está em uso e compara com o que a configuração
manda. Serviço "Running" com a API morta dentro é o engano mais comum aqui.

**B.7 — Prove de OUTRA máquina.** Este é o teste que vale:

```powershell
Invoke-RestMethod "http://SERVIDOR:5199/saude"
```

Tem de responder `banco = FINANCES.FDB`. **Enquanto isso não responder de fora, nenhuma
estação vai funcionar** — e o sintoma na estação não aponta para cá.

---

## 5. Fase C — Primeira estação: homologar

**C.1 — Instale o aplicativo:** duplo clique em `AgendaFinanceira-Instalador-1.0.0.exe`.
Não pergunta nada e abre sozinho no fim.

**C.2 — Aponte para o servidor.** O endereço fica **na própria tela de login**, no painel
verde à esquerda. Informe `http://SERVIDOR:5199`.

> É a única tela onde ele pode ser configurado, e isso é intencional: para entrar é preciso
> alcançar o servidor, e o endereço do servidor se configura aí.

**C.3 — Entre com um usuário real.** As senhas são as do sistema antigo; ninguém troca senha.
Confira os totais do painel contra os números da fase A.2.

**C.4 — Deixe rodar alguns dias.** É homologação **sobre cópia**: o que for lançado aqui não
aparece no Delphi, e vice-versa. Avise quem for testar, senão alguém lança de verdade e perde.

---

## 6. Fase D — Cortar para a base de produção

A fase delicada: a partir daqui os dois sistemas escrevem no mesmo arquivo.

**D.1 — Escolha a hora.** Ninguém no Delphi, ninguém na Agenda.

**D.2 — Backup de novo.** Repita a A.1; o backup da fase A já tem dias.

**D.3 — Crie a coluna de convivência na base viva:**

```sql
ALTER TABLE LOGIN ADD SENHA_HASH VARCHAR(200);
COMMIT;
```

```powershell
& "$fb\isql.exe" -b -user SYSDBA -password masterkey -i coluna.sql -o saida.txt `
  "localhost:C:\caminho\da\PRODUCAO.FDB"
```

O `-b` (*bail*) não é opcional: sem ele o `isql` segue executando depois de um erro e termina
anunciando sucesso.

**Por que é seguro:** o Delphi ignora colunas que não conhece — é o
[ADR 0010](decisoes/0010-autenticacao-durante-a-convivencia.md), verificado com ele rodando.
A coluna nasce vazia; quem ainda não tem hash entra pela senha em texto plano de sempre, e o
hash é gravado naquele momento. A base migra sozinha conforme as pessoas entram.

**D.4 — Confirme que a coluna existe:**

```sql
SELECT COUNT(*) FROM RDB$RELATION_FIELDS
 WHERE TRIM(RDB$RELATION_NAME) = 'LOGIN' AND TRIM(RDB$FIELD_NAME) = 'SENHA_HASH';
```

Tem de devolver `1`. O `ALTER` pode passar sem erro e a coluna não estar lá.

**D.5 — Aponte a API para a produção:**

```powershell
.\APONTAR-PARA-BASE.cmd
```

Escolha o `.FDB` de produção. Ele confere o formato, guarda a configuração anterior com a
hora no nome, reinicia e prova que subiu com o banco pedido.

**D.6 — O teste que prova a convivência.** Abra o Delphi e a Agenda ao mesmo tempo. Lance uma
despesa em cada um e veja se aparece no outro. Dois minutos, e é o que realmente importa.

**D.7 — Confira os totais** contra a fase A.2, descontando o que você acabou de lançar.

---

## 7. Fase E — Demais estações

Repita **C.1 e C.2** em cada máquina: instalador e endereço. Mais nada.

---

## 8. Voltar atrás

| Do quê | Como |
|---|---|
| Fase B (a API) | `sc.exe delete AgendaFinanceiraApi`. A produção nunca foi tocada. |
| Fase C | Nada a desfazer. Era cópia. |
| D.3 (a coluna) | `ALTER TABLE LOGIN DROP SENHA_HASH;` — o Delphi nunca a viu. |
| D.5 (o corte) | `APONTAR-PARA-BASE.cmd` de novo, escolhendo a cópia. |
| Tudo | Restaure o `.fbk` da D.2 **em outro arquivo** e compare antes de trocar qualquer coisa. |

A cópia de trabalho da fase B continua no disco depois do corte. Ela é o retrato de como as
coisas estavam — não apague nos primeiros dias.

---

## 9. Quando não funciona

| Sintoma | Causa quase sempre |
|---|---|
| Estação: "não foi possível alcançar o servidor" | `Urls` ainda em `localhost` (B.4), ou firewall (B.5) |
| Funciona no servidor, não na estação | O mesmo. Refaça o teste **B.7** antes de olhar a estação |
| Entra e as telas ficam vazias | Falta `"null"` no CORS (B.4) |
| "Usuário ou senha inválidos" para todo mundo | Falta a coluna `SENHA_HASH` (D.3) |
| Parou tudo de repente, depois de dias | O IP do servidor mudou. Use nome fixo ou reserve o IP |
| A API não sobe e não diz nada | Falta a chave `Jwt` na configuração. Ela falha fechada de propósito |

Em qualquer caso, no servidor:

```powershell
.\conferir-estado.ps1
```

Não altera nada e diz em que camada parou: serviço, API, banco ou cliente.

---

## 10. Depois

- **Segunda base (`FINANCESFATURAMENTO`)** repete este roteiro. Como a API lê **uma base por
  vez**, serão **dois serviços em portas diferentes** — 5199 e 5200 —, cada um com sua pasta
  `publicado` e sua configuração. As estações ganham dois atalhos, cada um com seu endereço.

- **Banco e API em máquinas separadas** passou a ser possível: `Banco:Caminho` aceita
  `192.168.1.20:C:/bases/FINANCES.FDB`, onde o caminho é o do disco **do servidor de banco**.
  Não é o desenho escolhido aqui, mas está disponível.
  **Nunca use caminho de compartilhamento** (`\\maquina\pasta\x.fdb`): a trava do Firebird não
  atravessa rede e dois processos escrevem por cima um do outro. A API recusa subir assim.

- **Índices em `DATA_VENCIMENTO` e `DATA_PAGAMENTO`.** O ADR 0005 autoriza — índice é
  transparente para o Delphi. Vale quando a base crescer.

- **A senha do banco ainda é `masterkey`**, a padrão do Firebird. Já dá para trocar:
  `"Banco": { "Senha": "…" }` na configuração. Está na lista de pendências do
  [CLAUDE.md](../CLAUDE.md).
