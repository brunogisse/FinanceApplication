const { contextBridge, ipcRenderer } = require('electron');

/**
 * Ponte entre a página e o processo principal.
 *
 * Existe por um motivo concreto: **`window.print()` não funciona no Electron**. A chamada
 * retorna sem erro, sem abrir caixa nenhuma e sem imprimir — verificado na janela real, numa
 * máquina com sete impressoras instaladas e uma delas padrão. Um botão de imprimir apoiado
 * nela funcionaria no navegador e falharia calado no aplicativo, que é o pior defeito
 * possível. Imprimir e gerar PDF só são confiáveis a partir do processo principal.
 *
 * A superfície exposta é mínima e nomeada pelo que faz, nunca `ipcRenderer` cru: a página
 * continua sem poder chamar qualquer canal.
 */
contextBridge.exposeInMainWorld('agenda', {
  /** Marca que a página está dentro do aplicativo, e não num navegador. */
  ehAplicativo: true,

  /** Abre a caixa de impressão do Windows. Devolve o que de fato aconteceu. */
  imprimir: () => ipcRenderer.invoke('imprimir'),

  /** Gera o PDF da página e pergunta onde salvar. */
  salvarPdf: (nomeSugerido) => ipcRenderer.invoke('salvar-pdf', nomeSugerido),
});
