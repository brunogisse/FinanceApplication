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

/**
 * Caixa de confirmação do sistema, no lugar do `confirm()` do navegador.
 *
 * O `confirm()` funciona, mas quem aparece é a caixa do Windows, com o título
 * "agenda-desktop" e os botões OK/Cancelar — dentro de uma tela que não se parece nada com
 * ela. Além do visual, ele não deixa escrever qual é a ação nem destacar o que não tem volta.
 *
 * O diálogo é montado direto no documento, e não como componente de template, porque as
 * telas de relatório vivem **fora** da casca: um host fixo não alcançaria elas.
 *
 * Usa `<dialog>` nativo com `showModal()`, que dá Esc, armadilha de foco e fundo escurecido
 * sem biblioteca. Verificado no Electron — ao contrário de `prompt()` e `print()`, que não
 * funcionam lá.
 */
@Injectable({ providedIn: 'root' })
export class Confirmacao {
  perguntar(p: Pergunta): Promise<boolean> {
    return new Promise((resolver) => {
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
      const responder = (resposta: boolean) => {
        if (respondido) return;
        respondido = true;
        caixa.close();
        caixa.remove();
        resolver(resposta);
      };

      cancelar.addEventListener('click', () => responder(false));
      confirmar.addEventListener('click', () => responder(true));
      // Esc fecha o <dialog> por conta própria; sem isto a promessa ficaria pendurada.
      caixa.addEventListener('close', () => responder(false));

      caixa.showModal();

      // Numa ação destrutiva o foco começa no cancelar: Enter sem ler não deve destruir nada.
      (p.perigo ? cancelar : confirmar).focus();
    });
  }
}
