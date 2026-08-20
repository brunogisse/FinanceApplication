import { Injectable } from '@angular/core';

/** O que o preload do Electron expõe. Ver `cliente/agenda-desktop/preload.js`. */
interface PonteDoAplicativo {
  ehAplicativo: boolean;
  imprimir(): Promise<{ situacao: string; motivo?: string }>;
  salvarPdf(nome: string): Promise<{ situacao: string; caminho?: string }>;
}

declare global {
  interface Window {
    agenda?: PonteDoAplicativo;
  }
}

/**
 * Impressão e geração de PDF.
 *
 * **`window.print()` não funciona no Electron.** A chamada retorna sem erro, sem abrir caixa
 * nenhuma e sem imprimir — verificado na janela real, numa máquina com sete impressoras e uma
 * delas padrão. Por isso, dentro do aplicativo, tudo passa pelo processo principal.
 *
 * No navegador não há ponte, e aí `window.print()` funciona normalmente. As duas situações
 * existem: o desenvolvimento roda no navegador e a operadora roda no aplicativo.
 */
@Injectable({ providedIn: 'root' })
export class Impressao {
  private get ponte(): PonteDoAplicativo | undefined {
    return typeof window !== 'undefined' ? window.agenda : undefined;
  }

  /** Dentro do aplicativo dá para salvar em PDF; no navegador, só imprimir. */
  get noAplicativo(): boolean {
    return this.ponte?.ehAplicativo === true;
  }

  /** Devolve o que dizer à pessoa, ou nulo quando não há nada a dizer. */
  async imprimir(): Promise<string | null> {
    const ponte = this.ponte;

    if (!ponte) {
      window.print();
      return null;
    }

    const r = await ponte.imprimir();
    if (r.situacao === 'impresso') return 'Enviado para a impressora.';
    if (r.situacao === 'cancelado') return null;   // fechou a caixa; não é erro
    return `Não foi possível imprimir: ${r.motivo ?? 'motivo não informado'}.`;
  }

  async salvarPdf(nomeSugerido: string): Promise<string | null> {
    const ponte = this.ponte;

    if (!ponte) {
      // Sem ponte, a caixa de impressão do navegador já oferece "Salvar em PDF".
      window.print();
      return null;
    }

    const r = await ponte.salvarPdf(nomeSugerido);
    if (r.situacao === 'salvo') return `PDF salvo em ${r.caminho}.`;
    return null;
  }
}
