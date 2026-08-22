import { Injectable } from '@angular/core';

/** O que a caixa pergunta. */
export interface Pergunta {
  titulo: string;
  /** Linhas do corpo. Cada uma vira um parágrafo. */
  linhas?: string[];
  /** Aviso em destaque, para o que não tem volta. */
  alerta?: string;
  confirmar?: string;
  cancelar?: string;
  /** Ação destrutiva: botão vermelho e foco no cancelar. */
  perigo?: boolean;
}

/** Uma pergunta que espera texto digitado, no lugar do `prompt()` do navegador. */
export interface PerguntaDeTexto extends Pergunta {
  /** Rótulo do campo. */
  rotulo: string;
  valorInicial?: string;
  /** Senha: o campo esconde o que é digitado. */
  sigiloso?: boolean;
  tamanhoMaximo?: number;
}

/**
 * Caixas de diálogo do sistema, no lugar de `confirm()` e `prompt()` do navegador.
 *
 * O `confirm()` funciona, mas quem aparece é a caixa do Windows, com o título
 * "agenda-desktop" e os botões OK/Cancelar — dentro de uma tela que não se parece nada com
 * ela. Além do visual, ele não deixa escrever qual é a ação nem destacar o que não tem volta.
 *
 * O `prompt()` é pior: **lança exceção no Electron**, com "prompt() is not supported.". Ele
 * funciona no navegador durante o desenvolvimento e morre no aplicativo empacotado, que é o
 * jeito pior de falhar.
 *
 * O diálogo é montado direto no documento, e não como componente de template, porque as
 * telas de relatório vivem **fora** da casca: um host fixo não alcançaria elas.
 *
 * Usa `<dialog>` nativo com `showModal()`, que dá Esc, armadilha de foco e fundo escurecido
 * sem biblioteca. Verificado no Electron.
 */
@Injectable({ providedIn: 'root' })
export class Confirmacao {
  perguntar(p: Pergunta): Promise<boolean> {
    return new Promise((resolver) => {
      const { caixa, cancelar, confirmar, responder } = this.montar(p, resolver, false);

      cancelar.addEventListener('click', () => responder(false));
      confirmar.addEventListener('click', () => responder(true));

      caixa.showModal();
      (p.perigo ? cancelar : confirmar).focus();
    });
  }

  /**
   * Pede um texto. Devolve `null` quando a pessoa cancela — diferente de string vazia, que
   * seria um texto de fato.
   */
  pedirTexto(p: PerguntaDeTexto): Promise<string | null> {
    return new Promise((resolver) => {
      const campo = document.createElement('input');
      campo.type = p.sigiloso ? 'password' : 'text';
      campo.className = 'confirmacao-campo';
      campo.value = p.valorInicial ?? '';
      campo.setAttribute('aria-label', p.rotulo);
      campo.placeholder = p.rotulo;
      if (p.tamanhoMaximo) campo.maxLength = p.tamanhoMaximo;

      const { caixa, cancelar, confirmar, responder } =
        this.montar<string | null>(p, resolver, true, campo);

      const confirmarTexto = () => {
        const texto = campo.value.trim();
        // Vazio não é resposta: quem confirma sem digitar continua na caixa.
        if (!texto) { campo.focus(); return; }
        responder(texto);
      };

      cancelar.addEventListener('click', () => responder(null));
      confirmar.addEventListener('click', confirmarTexto);
      campo.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') { e.preventDefault(); confirmarTexto(); }
      });

      caixa.showModal();
      campo.focus();
    });
  }

  /**
   * Monta a caixa e devolve as peças. Compartilhado pelos dois tipos de pergunta: duas
   * cópias divergiriam no dia em que o visual mudasse.
   */
  private montar<T>(
    p: Pergunta,
    resolver: (valor: T) => void,
    cancelaComoNulo: boolean,
    campo?: HTMLElement,
  ) {
    const caixa = document.createElement('dialog');
    caixa.className = 'confirmacao';

    const titulo = document.createElement('h2');
    titulo.textContent = p.titulo;
    caixa.appendChild(titulo);

    for (const linha of p.linhas ?? []) {
      const paragrafo = document.createElement('p');
      paragrafo.textContent = linha;
      caixa.appendChild(paragrafo);
    }

    if (p.alerta) {
      const alerta = document.createElement('p');
      alerta.className = 'confirmacao-alerta';
      alerta.textContent = p.alerta;
      caixa.appendChild(alerta);
    }

    if (campo) caixa.appendChild(campo);

    const acoes = document.createElement('div');
    acoes.className = 'confirmacao-acoes';

    const cancelar = document.createElement('button');
    cancelar.type = 'button';
    cancelar.className = 'botao';
    cancelar.textContent = p.cancelar ?? 'Cancelar';

    const confirmar = document.createElement('button');
    confirmar.type = 'button';
    confirmar.className = p.perigo ? 'botao botao-destrutivo' : 'botao botao-primario';
    confirmar.textContent = p.confirmar ?? 'Confirmar';

    acoes.append(cancelar, confirmar);
    caixa.appendChild(acoes);
    document.body.appendChild(caixa);

    // Uma resposta só: o primeiro caminho que fechar a caixa é o que vale.
    let respondido = false;
    const responder = (resposta: T) => {
      if (respondido) return;
      respondido = true;
      caixa.close();
      caixa.remove();
      resolver(resposta);
    };

    // Esc fecha o <dialog> por conta própria; sem isto a promessa ficaria pendurada.
    caixa.addEventListener('close', () => responder((cancelaComoNulo ? null : false) as T));

    return { caixa, cancelar, confirmar, responder };
  }
}
