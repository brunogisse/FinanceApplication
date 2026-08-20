import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Impressao } from '../../nucleo/impressao';
import { formatarInteiro } from '../../nucleo/moeda';

/** Medido gerando o PDF: 39 linhas cabem numa folha A4 com esta fonte e margens. */
export const LINHAS_POR_PAGINA = 39;

/** Acima disto, imprimir passa a pedir confirmação. */
const PAGINAS_QUE_MERECEM_AVISO = 20;

/**
 * Barra de ações dos relatórios: voltar, imprimir e salvar em PDF.
 *
 * É a mesma nos três relatórios, e some no papel (`.nao-imprime`).
 *
 * O aviso de tamanho não é enfeite: a base inteira sai em 358 folhas, e um clique distraído
 * com o período largo esvazia o cartucho de alguém. O legado mostra a prévia do FastReport
 * antes de imprimir; aqui esse aviso faz o papel dela.
 */
@Component({
  selector: 'app-barra-impressao',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="barra-impressao nao-imprime">
      <button class="botao" (click)="voltar()">Voltar</button>

      @if (quantidade() !== null) {
        <span [class.alerta-paginas]="longo()">
          {{ inteiro(quantidade()) }} {{ unidade() }} — aproximadamente
          {{ inteiro(paginas()) }} página(s)
        </span>
      }

      <span class="espaco"></span>

      @if (aviso()) {
        <span>{{ aviso() }}</span>
      }

      @if (noAplicativo) {
        <button class="botao" (click)="salvarPdf()" [disabled]="ocupado()">Salvar em PDF</button>
      }
      <button class="botao botao-primario" (click)="imprimir()" [disabled]="ocupado()">
        Imprimir
      </button>
    </div>
  `,
})
export class BarraImpressao {
  private readonly impressao = inject(Impressao);
  private readonly router = inject(Router);

  readonly inteiro = formatarInteiro;

  /** Quantas linhas o relatório tem. Nulo enquanto carrega. */
  readonly quantidade = input<number | null>(null);
  readonly unidade = input('lançamento(s)');
  readonly nomeDoPdf = input.required<string>();
  readonly voltarPara = input<string>('/lancamentos');
  readonly ocupado = input(false);

  readonly aviso = signal<string | null>(null);
  readonly noAplicativo = this.impressao.noAplicativo;

  readonly paginas = computed(() =>
    Math.max(1, Math.ceil((this.quantidade() ?? 0) / LINHAS_POR_PAGINA)));

  readonly longo = computed(() => this.paginas() > PAGINAS_QUE_MERECEM_AVISO);

  async imprimir(): Promise<void> {
    if (this.longo()) {
      const pergunta =
        `Este relatório tem ${this.inteiro(this.quantidade())} linhas, ` +
        `o que dá cerca de ${this.inteiro(this.paginas())} páginas.\n\n` +
        `Imprimir mesmo assim?`;
      if (!confirm(pergunta)) return;
    }

    this.aviso.set(await this.impressao.imprimir());
  }

  async salvarPdf(): Promise<void> {
    this.aviso.set(await this.impressao.salvarPdf(this.nomeDoPdf()));
  }

  voltar(): void {
    this.router.navigate([this.voltarPara()]);
  }
}
