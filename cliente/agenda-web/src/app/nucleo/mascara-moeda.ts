import { Directive, ElementRef, HostListener, inject } from '@angular/core';
import { mascararMoeda } from './moeda';

/**
 * Máscara de dinheiro em campo de digitação: `mascaraMoeda` num `<input>`.
 *
 * A operadora digita só os números e o campo se monta sozinho, dos centavos para a esquerda:
 * `123456` vira `R$ 1.234,56`. É o comportamento que ela já conhece dos sistemas bancários,
 * e tira a dúvida de onde vai a vírgula — que no legado era fonte de erro de casa decimal.
 *
 * ## Por que reemitir o evento
 *
 * O `ngModel` escuta o mesmo `input` que esta diretiva. Quem roda primeiro depende da ordem
 * de registro, e se o `ngModel` lesse antes o modelo ficaria com o texto cru enquanto a tela
 * mostra o formatado — as duas coisas discordando sem ninguém ver.
 *
 * Por isso, quando o texto muda, a diretiva **dispara um novo `input`**. A trava
 * `reentrante` impede o laço: na segunda passagem esta diretiva sai na primeira linha, e
 * quem escuta recebe o valor já corrigido. Vale igual para os campos ligados por
 * `[value]` + `(input)`, como a tabela de parcelas.
 */
@Directive({
  selector: 'input[mascaraMoeda]',
  standalone: true,
})
export class MascaraMoeda {
  private readonly campo = inject<ElementRef<HTMLInputElement>>(ElementRef);
  private reentrante = false;

  @HostListener('input')
  aoDigitar(): void {
    this.aplicar();
  }

  /**
   * Também ao sair do campo: um valor colado de fora — "1234,5", "R$ 1.234,50" — chega
   * inteiro num único evento, e sair sem reformatar deixaria na tela um texto que não é o
   * que a máscara produz.
   */
  @HostListener('blur')
  aoSair(): void {
    this.aplicar();
  }

  private aplicar(): void {
    if (this.reentrante) return;

    const campo = this.campo.nativeElement;
    const formatado = mascararMoeda(campo.value);
    if (formatado === campo.value) return;

    this.reentrante = true;
    try {
      campo.value = formatado;
      // Sempre no fim: a máscara remonta o texto inteiro a cada tecla, então guardar a
      // posição anterior colocaria o cursor no meio de um separador que acabou de mudar
      // de lugar.
      campo.setSelectionRange(formatado.length, formatado.length);
      campo.dispatchEvent(new Event('input', { bubbles: true }));
    } finally {
      this.reentrante = false;
    }
  }
}
