import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Api } from '../../nucleo/api';
import { FiltroConsulta, Lancamento } from '../../nucleo/modelos';
import { formatarData, formatarInteiro, formatarMoeda, hojeIso } from '../../nucleo/moeda';
import { BarraImpressao } from '../relatorios/barra-impressao';

/**
 * Relatório de Lançamentos — equivale a `Lançamento.fr3` e `LancamentoConsulta.fr3`, que no
 * legado são o mesmo layout ligado às duas abas de pesquisa.
 *
 * Traz os oito campos do relatório do legado (descrição, conta, NF, cheque, previsto, pago,
 * vencimento e pagamento), o período, a data de geração e, no rodapé, os totais e a contagem.
 *
 * Os filtros chegam pela URL. Assim o relatório é uma página inteira por si só: dá para
 * recarregar, voltar e imprimir de novo sem depender do estado da tela anterior.
 */
@Component({
  selector: 'app-relatorio-lancamentos',
  standalone: true,
  imports: [BarraImpressao],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './relatorio-lancamentos.html',
})
export class RelatorioLancamentos {
  private readonly api = inject(Api);
  private readonly rota = inject(ActivatedRoute);

  readonly moeda = formatarMoeda;
  readonly data = formatarData;
  readonly inteiro = formatarInteiro;

  readonly lancamentos = signal<Lancamento[]>([]);
  readonly totalPrevisto = signal(0);
  readonly totalPago = signal(0);
  readonly carregando = signal(true);
  readonly erro = signal<string | null>(null);

  readonly geradoEm = formatarData(hojeIso());
  readonly nomeDoPdf = `lancamentos-${hojeIso()}.pdf`;

  readonly filtro = signal<FiltroConsulta>({});
  readonly quantidade = computed(() => this.lancamentos().length);

  /**
   * A frase que descreve o recorte, no cabeçalho.
   *
   * Um relatório impresso perde o contexto da tela: sem dizer sobre qual data o período vale
   * e quais filtros valeram, a folha na mesa de alguém não se explica.
   */
  readonly descricaoDoRecorte = computed(() => {
    const f = this.filtro();
    const coluna = f.porData === 'pagamento' ? 'pagamento'
                 : f.porData === 'cadastro' ? 'cadastro'
                 : 'vencimento';

    const partes: string[] = [];
    if (f.pagamento === 'pagos') partes.push('somente pagos');
    if (f.pagamento === 'naopagos') partes.push('somente a pagar');
    if (f.despesa) partes.push(`despesa ${f.despesa}`);
    if (f.subdespesa) partes.push(`subdespesa ${f.subdespesa}`);
    if (f.conta) partes.push(`conta ${f.conta}`);
    if (f.descricao) partes.push(`descrição contendo "${f.descricao}"`);
    if (f.notaFiscal) partes.push(`nota fiscal ${f.notaFiscal}`);
    if (f.cheque) partes.push(`cheque ${f.cheque}`);
    if (f.chequeCompensado !== undefined) {
      partes.push(f.chequeCompensado ? 'cheque compensado' : 'cheque não compensado');
    }
    if (f.situacao) partes.push(`situação ${f.situacao}`);
    if (f.valorMinimo !== undefined || f.valorMaximo !== undefined) {
      const sobre = f.faixaSobreValorPago ? 'pago' : 'previsto';
      const de = f.valorMinimo !== undefined ? formatarMoeda(f.valorMinimo) : '—';
      const ate = f.valorMaximo !== undefined ? formatarMoeda(f.valorMaximo) : '—';
      partes.push(`valor ${sobre} de ${de} até ${ate}`);
    }

    return { coluna, filtros: partes };
  });

  constructor() {
    const p = this.rota.snapshot.queryParamMap;

    const filtro: FiltroConsulta = {
      inicio: p.get('inicio') ?? undefined,
      fim: p.get('fim') ?? undefined,
      porData: (p.get('porData') as FiltroConsulta['porData']) ?? undefined,
      pagamento: (p.get('pagamento') as FiltroConsulta['pagamento']) ?? undefined,
      descricao: p.get('descricao') ?? undefined,
      despesa: p.get('despesa') ?? undefined,
      subdespesa: p.get('subdespesa') ?? undefined,
      conta: p.get('conta') ?? undefined,
      notaFiscal: numero(p.get('notaFiscal')),
      cheque: numero(p.get('cheque')),
      chequeCompensado: p.get('chequeCompensado') === null
        ? undefined
        : p.get('chequeCompensado') === 'true',
      situacao: (p.get('situacao') as FiltroConsulta['situacao']) ?? undefined,
      valorMinimo: numero(p.get('valorMinimo')),
      valorMaximo: numero(p.get('valorMaximo')),
      faixaSobreValorPago: p.get('faixaSobreValorPago') === 'true' || undefined,
    };

    this.filtro.set(filtro);

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
}

function numero(texto: string | null): number | undefined {
  if (texto === null || texto.trim() === '') return undefined;
  const valor = Number(texto);
  return Number.isFinite(valor) ? valor : undefined;
}
