const { app, BrowserWindow, shell } = require('electron');
const path = require('node:path');

/**
 * Processo principal do cliente desktop.
 *
 * Em desenvolvimento carrega o servidor do Angular; empacotado, carrega os arquivos gerados
 * pelo build. A configuração do usuário mora em `userData`, que sobrevive à atualização —
 * a pasta de instalação é apagada pelo desinstalador da versão anterior.
 */

const desenvolvimento = process.argv.includes('--dev') || !app.isPackaged;
const ENDERECO_DEV = 'http://localhost:4200';

function criarJanela() {
  const janela = new BrowserWindow({
    width: 1360,
    height: 800,
    minWidth: 1024,
    minHeight: 640,
    title: 'Agenda Financeira',
    show: false,
    webPreferences: {
      // O cliente só fala com a API por HTTP; não precisa de acesso a Node no renderizador.
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
    },
  });

  // Só mostra quando estiver pronta, para não piscar uma janela em branco.
  janela.once('ready-to-show', () => janela.show());

  if (desenvolvimento) {
    janela.loadURL(ENDERECO_DEV);
  } else {
    janela.loadFile(path.join(__dirname, 'web', 'browser', 'index.html'));
  }

  // Link externo abre no navegador do sistema, não dentro do aplicativo.
  janela.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  return janela;
}

app.whenReady().then(() => {
  criarJanela();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) criarJanela();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
