import {
  ChangeDetectionStrategy, Component, OnDestroy, computed, inject, signal,
} from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Api } from '../../nucleo/api';
import { FiltroConsulta, Lancamento } from '../../nucleo/modelos';
import { formatarData, formatarInteiro, formatarMoeda, hojeIso } from '../../nucleo/moeda';
import { BarraImpressao } from '../relatorios/barra-impressao';

/**
 * Relatório detalhado de subdespesas — equivale a `RelatorioSubdespesaDetalhado.fr3`.
 *
 * É o único dos três que não tinha equivalente nenhum no sistema novo: abre uma subdespesa e
 * lista lançamento a lançamento, com conta, nota fiscal, cheque, compensação e as duas datas.
 *
 * Serve para conferir de onde veio um total do consolidado — é o passo seguinte natural
 * depois de olhar aquele relatório e estranhar um número.
 */
@Component({
  selector: 'app-relatorio-subdespesa',
  standalone: true,
  imports: [BarraImpressao],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './relatorio-subdespesa.html',
})
export class RelatorioSubdespesa implements OnDestroy {
  private readonly api = inject(Api);
  private readonly rota = inject(ActivatedRoute);

  /**
   * Este é o único relatório que sai deitado.
   *
   * Nove colunas não cabem em A4 retrato: medido na própria tela, a tabela pede 752px e a
   * folha oferece 679. O que sobra sai **cortado na impressão**, sem aviso nenhum — e um
   * relatório com a coluna de valor faltando é pior do que relatório nenhum.
   *
   * A regra `@page` vale para o documento inteiro, não para o componente. Por isso ela é
   * acrescentada ao entrar e retirada ao sair: senão o próximo relatório sairia deitado
   * junto, sem ninguém entender por quê.
   */
  private readonly estiloPaisagem = document.createElement('style');

  readonly moeda = formatarMoeda;
  readonly data = formatarData;
  readonly inteiro = formatarInteiro;

  readonly lancamentos = signal<Lancamento[]>([]);
  readonly totalPrevisto = signal(0);
  readonly totalPago = signal(0);
  readonly carregando = signal(true);
  readonly erro = signal<string | null>(null);

  readonly despesa = signal('');
  readonly subdespesa = signal('');
  readonly inicio = signal('');
  readonly fim = signal('');
  readonly pagos = signal(true);

  readonly geradoEm = formatarData(hojeIso());
  readonly quantidade = computed(() => this.lancamentos().length);
  readonly nomeDoPdf = computed(() =>
    `subdespesa-${this.subdespesa().toLowerCase().replace(/\s+/g, '-')}-${hojeIso()}.pdf`);

  /**
   * Volta para o consolidado **com o mesmo recorte**, não para o começo.
   *
   * O endereço vem pronto de lá, na consulta. Sem ele, voltar devolvia a tela em branco e a
   * pessoa refazia o filtro toda vez que fosse ver um detalhe.
   */
  readonly voltarPara = signal('/relatorios/por-despesa');

  constructor() {
    this.estiloPaisagem.textContent = '@media print { @page { size: A4 landscape; margin: 12mm; } }';
    document.head.appendChild(this.estiloPaisagem);

    const p = this.rota.snapshot.queryParamMap;

    this.despesa.set(p.get('despesa') ?? '');
    this.subdespesa.set(p.get('subdespesa') ?? '');
    this.inicio.set(p.get('inicio') ?? '');
    this.fim.set(p.get('fim') ?? '');
    this.pagos.set(p.get('pagos') !== 'false');
    if (p.get('voltarPara')) this.voltarPara.set(p.get('voltarPara')!);

    if (!this.subdespesa()) {
      this.erro.set('O relatório precisa de uma subdespesa.');
      this.carregando.set(false);
      return;
    }

    // Os dois modos usam colunas de data diferentes, exatamente como no consolidado: o que
    // foi pago conta pela data do pagamento; o que está em aberto, pelo vencimento.
    const filtro: FiltroConsulta = {
      inicio: this.inicio(),
      fim: this.fim(),
      despesa: this.despesa() || undefined,
      subdespesa: this.subdespesa(),
      porData: this.pagos() ? 'pagamento' : 'vencimento',
      pagamento: this.pagos() ? 'pagos' : 'naopagos',
    };

    this.api.consultar(filtro).subscribe({
      next: (r) => {
        this.lancamentos.set(r.lancamentos);
        this.totalPrevisto.set(r.totalPrevisto);
        this.totalPago.set(r.totalPago);
        this.carregando.set(false);
      },
      error: (e: Error) => {
        this.erro.set(e.message);
        this.carregando.set(false);
      },
    });
  }

  ngOnDestroy(): void {
    this.estiloPaisagem.remove();
  }
}
