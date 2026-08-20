const { app, BrowserWindow, dialog, ipcMain, shell } = require('electron');
const { writeFile } = require('node:fs/promises');
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
      // Mesmo com sandbox ligado, o preload pode expor uma ponte pelo contextBridge. É por
      // ela que a impressão acontece — ver o comentário em preload.js.
      preload: path.join(__dirname, 'preload.js'),
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

  // Exportação de planilha. O Electron abre a caixa de "Salvar como" por conta própria,
  // mas deixar isto explícito é o que permite escolher a pasta inicial e o filtro — e, mais
  // importante, o que torna o comportamento uma decisão nossa em vez de um padrão herdado.
  janela.webContents.session.on('will-download', (_evento, item) => {
    item.setSaveDialogOptions({
      title: 'Salvar planilha',
      defaultPath: path.join(app.getPath('downloads'), item.getFilename()),
      filters: [{ name: 'Planilha do Excel', extensions: ['xlsx'] }],
    });
  });

  return janela;
}

/**
 * Impressão e geração de PDF.
 *
 * Ambas rodam aqui, no processo principal, porque `window.print()` não funciona no Electron —
 * ver preload.js. As duas devolvem o que aconteceu de verdade, para a tela poder dizer à
 * pessoa em vez de supor que deu certo.
 */
function registrarImpressao() {
  ipcMain.handle('imprimir', async (evento) => {
    const conteudo = evento.sender;
    return new Promise((resolve) => {
      conteudo.print({ silent: false, printBackground: true }, (sucesso, motivo) => {
        // Fechar a caixa sem imprimir chega aqui como "cancelled". Não é erro.
        if (sucesso) resolve({ situacao: 'impresso' });
        else if (motivo === 'cancelled') resolve({ situacao: 'cancelado' });
        else resolve({ situacao: 'falhou', motivo });
      });
    });
  });

  ipcMain.handle('salvar-pdf', async (evento, nomeSugerido) => {
    const conteudo = evento.sender;

    // preferCSSPageSize deixa o `@page` da folha mandar no tamanho e na orientação. Sem
    // isto, o que está aqui vence, e o relatório detalhado de subdespesas — que precisa
    // sair deitado, senão perde colunas — sairia em pé e cortado.
    const pdf = await conteudo.printToPDF({
      pageSize: 'A4',
      printBackground: true,
      preferCSSPageSize: true,
    });

    const escolha = await dialog.showSaveDialog({
      title: 'Salvar relatório em PDF',
      defaultPath: path.join(app.getPath('documents'), nomeSugerido || 'relatorio.pdf'),
      filters: [{ name: 'PDF', extensions: ['pdf'] }],
    });

    if (escolha.canceled || !escolha.filePath) return { situacao: 'cancelado' };

    await writeFile(escolha.filePath, pdf);
    // Abrir o arquivo é o que fecha o ciclo: a pessoa vê o resultado, não uma mensagem.
    shell.openPath(escolha.filePath);
    return { situacao: 'salvo', caminho: escolha.filePath };
  });
}

app.whenReady().then(() => {
  registrarImpressao();
  criarJanela();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) criarJanela();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
