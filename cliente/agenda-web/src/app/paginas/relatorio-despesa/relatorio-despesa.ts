import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Api } from '../../nucleo/api';
import { Conta, Despesa, TotalPorSubdespesa } from '../../nucleo/modelos';
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

  // ---- Mais filtros ----
  //
  // Por enquanto só conta, a pedido de quem opera: "quanto saiu desta conta, nesta despesa".
  // O painel já nasce como lista para o próximo filtro ser uma linha, não uma reforma.
  readonly maisFiltrosAberto = signal(false);
  readonly contas = signal<Conta[]>([]);
  readonly conta = signal('');

  /**
   * Quantos filtros do painel estão valendo.
   *
   * O painel fica fechado, e filtro ativo escondido é armadilha: a pessoa consulta, vê um
   * total menor do que esperava e não descobre por quê. O número aparece no próprio botão.
   */
  readonly maisFiltrosAtivos = computed(() => [this.conta()].filter((v) => v !== '').length);

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

  /**
   * Como os filtros de agora aparecem no endereço.
   *
   * A conta entra só quando vale alguma coisa: um `conta=` vazio no endereço sujaria a barra
   * e a impressão sem dizer nada.
   */
  private parametros(): Record<string, string> {
    const p: Record<string, string> = {
      despesa: this.despesa(),
      inicio: this.inicio(),
      fim: this.fim(),
      pagos: String(this.pagos()),
    };
    if (this.conta()) p['conta'] = this.conta();
    return p;
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
    this.conta.set('');
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

    this.api.contas().subscribe({
      next: (c) => this.contas.set(c.filter((x) => x.descricao.trim() !== '')),
      error: () => {},
    });

    // Volta ao recorte que estava no endereço — é o que faz "voltar" do detalhado funcionar.
    const p = this.rota.snapshot.queryParamMap;
    if (p.get('inicio')) this.inicio.set(p.get('inicio')!);
    if (p.get('fim')) this.fim.set(p.get('fim')!);
    if (p.get('pagos')) this.pagos.set(p.get('pagos') !== 'false');
    if (p.get('conta')) {
      this.conta.set(p.get('conta')!);
      // Voltando com a conta valendo, o painel abre: senão o filtro estaria em vigor e
      // escondido, e o total pareceria errado.
      this.maisFiltrosAberto.set(true);
    }
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

    this.api
      .consolidadoPorDespesa(
        this.despesa(), this.inicio(), this.fim(), this.pagos(), this.conta() || undefined)
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
        // A conta vai junto porque o detalhado tem de somar o MESMO total que a linha
        // clicada. Sem ela, o detalhe traria lançamentos de outras contas e o rodapé não
        // fecharia com o número de onde a pessoa veio.
        ...(this.conta() ? { conta: this.conta() } : {}),
      },
    });
  }

  voltar(): void { this.router.navigate(['/lancamentos']); }
}
