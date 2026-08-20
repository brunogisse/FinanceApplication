import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Api } from '../../nucleo/api';
import { Despesa, TotalPorSubdespesa } from '../../nucleo/modelos';
import { formatarMoeda, hojeIso, somarMeses } from '../../nucleo/moeda';

@Component({
  selector: 'app-relatorio-despesa',
  standalone: true,
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './relatorio-despesa.html',
  styleUrl: './relatorio-despesa.css',
})
export class RelatorioDespesa {
  private readonly api = inject(Api);
  private readonly router = inject(Router);

  readonly moeda = formatarMoeda;

  readonly despesas = signal<Despesa[]>([]);
  readonly despesa = signal('');
  readonly inicio = signal(somarMeses(hojeIso(), -6));
  readonly fim = signal(hojeIso());
  /** true = "quanto gastei"; false = "quanto devo". Muda a coluna de data no servidor. */
  readonly pagos = signal(true);

  readonly linhas = signal<TotalPorSubdespesa[]>([]);
  readonly carregando = signal(false);
  readonly erro = signal<string | null>(null);
  readonly consultou = signal(false);

  /** Somado em centavos inteiros: o cliente não faz aritmética de dinheiro com decimal. */
  readonly total = computed(() => {
    const campo = this.pagos()
      ? (l: TotalPorSubdespesa) => l.totalPago
      : (l: TotalPorSubdespesa) => l.totalPrevisto;
    const centavos = this.linhas().reduce((s, l) => s + Math.round(campo(l) * 100), 0);
    return centavos / 100;
  });

  readonly quantidade = computed(() =>
    this.linhas().reduce((s, l) => s + l.quantidade, 0));

  constructor() {
    this.api.despesas().subscribe({
      next: (d) => this.despesas.set(d.filter((x) => x.descricao.trim() !== '')),
      error: () => {},
    });
  }

  consultar(): void {
    if (!this.despesa()) { this.erro.set('Escolha a despesa.'); return; }

    this.carregando.set(true);
    this.erro.set(null);

    this.api.consolidadoPorDespesa(this.despesa(), this.inicio(), this.fim(), this.pagos())
      .subscribe({
        next: (linhas) => {
          this.linhas.set(linhas);
          this.consultou.set(true);
          this.carregando.set(false);
        },
        error: (e: Error) => {
          this.erro.set(e.message);
          this.carregando.set(false);
          this.linhas.set([]);
        },
      });
  }

  trocarModo(pagos: boolean): void {
    this.pagos.set(pagos);
    if (this.consultou()) this.consultar();
  }

  /** Abre a versão impressa deste mesmo consolidado. */
  imprimir(): void {
    this.router.navigate(['/relatorios/consolidado'], {
      queryParams: {
        despesa: this.despesa(),
        inicio: this.inicio(),
        fim: this.fim(),
        pagos: this.pagos(),
      },
    });
  }

  /**
   * Abre o detalhado de uma subdespesa.
   *
   * É o passo seguinte natural: olhar um total do consolidado e querer ver de onde ele veio.
   */
  detalhar(l: TotalPorSubdespesa): void {
    this.router.navigate(['/relatorios/subdespesa'], {
      queryParams: {
        despesa: this.despesa(),
        subdespesa: l.subdespesa,
        inicio: this.inicio(),
        fim: this.fim(),
        pagos: this.pagos(),
      },
    });
  }

  voltar(): void { this.router.navigate(['/lancamentos']); }
}
