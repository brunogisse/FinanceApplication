import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Confirmacao } from '../../nucleo/confirmacao';
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
    <div class="barra-impressao nao-imprime" [class.deitada]="deitada()">
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
  private readonly confirmacao = inject(Confirmacao);

  readonly inteiro = formatarInteiro;

  /** Quantas linhas o relatório tem. Nulo enquanto carrega. */
  readonly quantidade = input<number | null>(null);
  readonly unidade = input('lançamento(s)');
  readonly nomeDoPdf = input.required<string>();
  readonly voltarPara = input<string>('/lancamentos');
  readonly ocupado = input(false);

  /**
   * O relatório sai deitado (A4 paisagem)?
   *
   * A barra acompanha a largura da folha. Sem isto ela ficaria com a largura do A4 em pé,
   * desalinhada da folha larga logo abaixo.
   */
  readonly deitada = input(false);

  readonly aviso = signal<string | null>(null);
  readonly noAplicativo = this.impressao.noAplicativo;

  readonly paginas = computed(() =>
    Math.max(1, Math.ceil((this.quantidade() ?? 0) / LINHAS_POR_PAGINA)));

  readonly longo = computed(() => this.paginas() > PAGINAS_QUE_MERECEM_AVISO);

  async imprimir(): Promise<void> {
    if (this.longo()) {
      const ok = await this.confirmacao.perguntar({
        titulo: `Imprimir cerca de ${this.inteiro(this.paginas())} páginas?`,
        linhas: [`O relatório tem ${this.inteiro(this.quantidade())} linhas.`],
        alerta: 'Confira o período antes: um recorte largo consome muito papel.',
        confirmar: 'Imprimir',
      });
      if (!ok) return;
    }

    this.aviso.set(await this.impressao.imprimir());
  }

  async salvarPdf(): Promise<void> {
    this.aviso.set(await this.impressao.salvarPdf(this.nomeDoPdf()));
  }

  /**
   * `navigateByUrl` e não `navigate([...])` porque o endereço de volta carrega os filtros da
   * tela de origem na consulta — e `navigate` trataria isso como parte do caminho.
   */
  voltar(): void {
    this.router.navigateByUrl(this.voltarPara());
  }
}
