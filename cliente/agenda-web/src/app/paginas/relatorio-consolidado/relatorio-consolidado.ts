import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Api } from '../../nucleo/api';
import { TotalPorSubdespesa } from '../../nucleo/modelos';
import { formatarData, formatarInteiro, formatarMoeda, hojeIso } from '../../nucleo/moeda';
import { BarraImpressao } from '../relatorios/barra-impressao';

/**
 * Relatório de Despesa/Subdespesa — equivale a `relatorioDespesa.fr3`.
 *
 * É a versão impressa do consolidado que já existe em tela: uma linha por subdespesa, com
 * previsto e pago, e os totais no rodapé.
 *
 * Os dois modos usam colunas de data diferentes, e é a regra central deste relatório. Por
 * isso o cabeçalho diz qual dos dois valeu — no papel não há como perguntar.
 */
@Component({
  selector: 'app-relatorio-consolidado',
  standalone: true,
  imports: [BarraImpressao],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './relatorio-consolidado.html',
})
export class RelatorioConsolidado {
  private readonly api = inject(Api);
  private readonly rota = inject(ActivatedRoute);

  readonly moeda = formatarMoeda;
  readonly data = formatarData;
  readonly inteiro = formatarInteiro;

  readonly linhas = signal<TotalPorSubdespesa[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal<string | null>(null);

  readonly despesa = signal('');
  readonly inicio = signal('');
  readonly fim = signal('');
  /** true = "quanto gastei", pela data de pagamento; false = "quanto devo", pelo vencimento. */
  readonly pagos = signal(true);
  /**
   * Conta, quando a tela filtrou por uma.
   *
   * Precisa viajar e precisa aparecer no cabeçalho: uma folha que traz o recorte de uma
   * conta sem dizer qual vira um número solto na mesa de alguém.
   */
  readonly conta = signal('');

  readonly geradoEm = formatarData(hojeIso());
  readonly nomeDoPdf = computed(() =>
    `despesa-${this.despesa().toLowerCase().replace(/\s+/g, '-')}-${hojeIso()}.pdf`);

  readonly quantidade = computed(() =>
    this.linhas().reduce((s, l) => s + l.quantidade, 0));

  /** Volta para o consolidado em tela com o mesmo recorte; o endereço vem pronto de lá. */
  readonly voltarPara = signal('/relatorios/por-despesa');

  /** Somado em centavos inteiros: o cliente não faz aritmética de dinheiro com decimal. */
  readonly total = computed(() => {
    const campo = this.pagos()
      ? (l: TotalPorSubdespesa) => l.totalPago
      : (l: TotalPorSubdespesa) => l.totalPrevisto;
    return this.linhas().reduce((s, l) => s + Math.round(campo(l) * 100), 0) / 100;
  });

  constructor() {
    const p = this.rota.snapshot.queryParamMap;

    this.despesa.set(p.get('despesa') ?? '');
    this.inicio.set(p.get('inicio') ?? '');
    this.fim.set(p.get('fim') ?? '');
    this.pagos.set(p.get('pagos') !== 'false');
    this.conta.set(p.get('conta') ?? '');
    if (p.get('voltarPara')) this.voltarPara.set(p.get('voltarPara')!);

    if (!this.despesa()) {
      this.erro.set('O relatório precisa de uma despesa.');
      this.carregando.set(false);
      return;
    }

    this.api
      .consolidadoPorDespesa(
        this.despesa(), this.inicio(), this.fim(), this.pagos(), this.conta() || undefined)
      .subscribe({
        next: (linhas) => {
          this.linhas.set(linhas);
          this.carregando.set(false);
        },
        error: (e: Error) => {
          this.erro.set(e.message);
          this.carregando.set(false);
        },
      });
  }
}
