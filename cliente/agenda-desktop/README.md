# Cliente desktop — Electron

Casca do Electron em volta do cliente Angular. Em desenvolvimento carrega o `ng serve`;
empacotado, carrega os arquivos gerados em `web/browser`.

```powershell
npm run dev         # abre apontando para http://localhost:4200
npm run icone       # regenera build/icone.ico a partir do desenho em gerar-icone.cjs
npm run empacotar   # gera o instalador em instalador/
```

O `package.json` não aceita comentários, e o `electron-builder` **recusa chaves
desconhecidas** dentro de `build` — inclusive as que começam com `_`. Por isso as decisões
do empacotamento estão aqui.

---

## Por que `oneClick: true` com `allowElevation: false`

Com `oneClick: false` o instalador pergunta onde instalar. Em modo silencioso, numa conta de
administrador, ele **responde sozinho**: eleva e instala para a máquina inteira. A partir daí
toda atualização sem elevação falha — e falha **calada**, sem mensagem nenhuma.

`perMachine: false` completa: a instalação é do usuário, em `%LOCALAPPDATA%`, e a atualização
não precisa de privilégio.

## Por que o `--base-href ./` no build

Empacotado, a página vem de `file://`. Com o `base href` absoluto (`/`), o navegador
procuraria os arquivos na raiz do disco.

## Por que rotas por hash

Está em `agenda-web/src/app/app.config.ts`: sob `file://`, a estratégia normal do Angular
chamaria `history.pushState` para um caminho que não existe no disco. O hash vale **também em
desenvolvimento**, de propósito — ligar só no empacotado criaria dois comportamentos, e o
defeito voltaria a aparecer apenas na máquina de quem usa.

`principal.js` tem ainda uma rede de segurança para o Ctrl+R: sob `file://` recarregar uma
rota com hash pode cair em `ERR_FILE_NOT_FOUND`, e o tratador recarrega o arquivo preservando
a rota em vez de deixar a janela em branco.

## O que não funciona no Electron

| Função | O que acontece | O que usar |
|---|---|---|
| `window.prompt()` | lança `prompt() is not supported.` | `Confirmacao.pedirTexto()` |
| `window.print()` | **retorna sem erro, sem abrir caixa e sem imprimir** | a ponte do `preload.js` |

`alert()` e `confirm()` funcionam. O caso do `print()` é o mais traiçoeiro por não lançar
nada: numa máquina com impressora padrão configurada, o clique simplesmente não produz efeito.

## Endereço da API

O cliente guarda o endereço em `localStorage`, e a **tela de login permite alterá-lo** — ela
mostra qual está valendo, no painel da esquerda. O padrão compilado é `http://localhost:5199`,
que é o certo para a instalação em que a API roda na mesma máquina.

Essa tela não pode exigir login: para entrar é preciso alcançar o servidor, e é justamente o
endereço dele que se configura ali.
