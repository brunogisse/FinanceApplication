// Gera o icone do aplicativo (build/icone.ico) a partir de um desenho HTML.
// Rodar com: npm run icone
//
// O Windows aceita PNG dentro de um .ico desde o Vista, entao montamos o arquivo com um PNG
// por resolucao — sem depender de conversor externo.
const { app, BrowserWindow } = require('electron');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const TAMANHOS = [256, 128, 64, 48, 32, 16];
const DESTINO = path.join(__dirname, 'icone.ico');

// O mesmo calendario do menu lateral, branco sobre o verde da marca. O icone e a primeira
// coisa que a pessoa procura na barra de tarefas: precisa ser o desenho que ela ja conhece
// de dentro do sistema, nao outro.
const DESENHO = `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <style>
      html, body { margin: 0; width: 256px; height: 256px; background: transparent; }
      .fundo {
        width: 256px; height: 256px;
        display: flex; align-items: center; justify-content: center;
        background: linear-gradient(165deg, #5ec26a 0%, #3d9950 100%);
        border-radius: 56px;
      }
      svg { width: 148px; height: 148px; }
    </style>
  </head>
  <body>
    <div class="fundo">
      <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none"
           stroke="#ffffff" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">
        <rect x="3" y="5" width="18" height="16" rx="2" />
        <path d="M3 10h18M8 3v4M16 3v4" />
      </svg>
    </div>
  </body>
</html>`;

/** Monta o container .ico a partir dos PNGs de cada resolucao. */
function montarIco(imagens) {
  const cabecalho = Buffer.alloc(6);
  cabecalho.writeUInt16LE(0, 0); // reservado
  cabecalho.writeUInt16LE(1, 2); // tipo 1 = icone
  cabecalho.writeUInt16LE(imagens.length, 4);

  const entradas = [];
  let deslocamento = 6 + imagens.length * 16;

  for (const { tamanho, png } of imagens) {
    const entrada = Buffer.alloc(16);
    // 256 e gravado como 0 no formato ICO.
    entrada.writeUInt8(tamanho >= 256 ? 0 : tamanho, 0); // largura
    entrada.writeUInt8(tamanho >= 256 ? 0 : tamanho, 1); // altura
    entrada.writeUInt8(0, 2);   // cores da paleta
    entrada.writeUInt8(0, 3);   // reservado
    entrada.writeUInt16LE(1, 4);  // planos
    entrada.writeUInt16LE(32, 6); // bits por pixel
    entrada.writeUInt32LE(png.length, 8);
    entrada.writeUInt32LE(deslocamento, 12);

    entradas.push(entrada);
    deslocamento += png.length;
  }

  return Buffer.concat([cabecalho, ...entradas, ...imagens.map((i) => i.png)]);
}

app.whenReady().then(async () => {
  // Arquivo temporario em vez de data: URL — este ultimo falha de forma intermitente.
  const arquivoHtml = path.join(os.tmpdir(), 'agenda-icone.html');
  fs.writeFileSync(arquivoHtml, DESENHO, 'utf-8');

  const janela = new BrowserWindow({
    width: 256, height: 256, show: false, frame: false, transparent: true,
  });

  await janela.loadFile(arquivoHtml);
  await new Promise((r) => setTimeout(r, 800));

  const original = await janela.webContents.capturePage({ x: 0, y: 0, width: 256, height: 256 });

  // Redimensionar pelo NativeImage sai mais nitido que re-renderizar com zoom.
  const imagens = TAMANHOS.map((tamanho) => {
    const png = tamanho === 256
      ? original.toPNG()
      : original.resize({ width: tamanho, height: tamanho, quality: 'best' }).toPNG();

    console.log(`  ${tamanho}x${tamanho} ok (${png.length} bytes)`);
    return { tamanho, png };
  });

  fs.writeFileSync(DESTINO, montarIco(imagens));
  console.log('Icone gravado em', DESTINO);

  fs.writeFileSync(path.join(__dirname, 'icone-256.png'), imagens[0].png);

  fs.unlinkSync(arquivoHtml);
  janela.destroy();
  app.quit();
});
