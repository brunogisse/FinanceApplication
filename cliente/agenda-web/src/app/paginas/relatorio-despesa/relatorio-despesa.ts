import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
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
  private readonly rota = inject(ActivatedRoute);

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

  /** Como os filtros de agora aparecem no endereço. */
  private parametros(): Record<string, string> {
    return {
      despesa: this.despesa(),
      inicio: this.inicio(),
      fim: this.fim(),
      pagos: String(this.pagos()),
    };
  }

  /**
   * O recorte para o relatório detalhado voltar para cá do jeito que estava.
   *
   * Sem isto, ir ver o detalhe de uma subdespesa e voltar devolvia a tela em branco, com as
   * datas de novo nos últimos seis meses — e a pessoa refazia o filtro toda vez.
   */
  private urlDeVolta(): string {
    const p = new URLSearchParams(this.parametros()).toString();
    return `/relatorios/por-despesa?${p}`;
  }

  /** Guarda o recorte no endereço, sem empilhar histórico a cada consulta. */
  private guardarNaUrl(): void {
    this.router.navigate([], {
      relativeTo: this.rota,
      queryParams: this.parametros(),
      replaceUrl: true,
    });
  }

  limparFiltros(): void {
    this.despesa.set('');
    this.inicio.set(somarMeses(hojeIso(), -6));
    this.fim.set(hojeIso());
    this.pagos.set(true);
    this.linhas.set([]);
    this.consultou.set(false);
    this.erro.set(null);

    this.router.navigate([], { relativeTo: this.rota, queryParams: {}, replaceUrl: true });
  }

  constructor() {
    this.api.despesas().subscribe({
      next: (d) => this.despesas.set(d.filter((x) => x.descricao.trim() !== '')),
      error: () => {},
    });

    // Volta ao recorte que estava no endereço — é o que faz "voltar" do detalhado funcionar.
    const p = this.rota.snapshot.queryParamMap;
    if (p.get('inicio')) this.inicio.set(p.get('inicio')!);
    if (p.get('fim')) this.fim.set(p.get('fim')!);
    if (p.get('pagos')) this.pagos.set(p.get('pagos') !== 'false');
    if (p.get('despesa')) {
      this.despesa.set(p.get('despesa')!);
      this.consultar();
    }
  }

  consultar(): void {
    if (!this.despesa()) { this.erro.set('Escolha a despesa.'); return; }

    this.guardarNaUrl();
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
      queryParams: { ...this.parametros(), voltarPara: this.urlDeVolta() },
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
        // O endereço de volta viaja junto: é assim que o detalhado devolve esta tela com o
        // mesmo recorte, em vez de recomeçá-la em branco.
        voltarPara: this.urlDeVolta(),
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
