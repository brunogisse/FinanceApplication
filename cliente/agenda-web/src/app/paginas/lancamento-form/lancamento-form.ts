import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Api } from '../../nucleo/api';
import { Conta, EntradaLancamento, FormaPagamento, Subdespesa } from '../../nucleo/modelos';
import { formatarMoeda, hojeIso, lerMoeda } from '../../nucleo/moeda';

@Component({
  selector: 'app-lancamento-form',
  standalone: true,
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './lancamento-form.html',
  styleUrl: './lancamento-form.css',
})
export class LancamentoForm {
  private readonly api = inject(Api);
  private readonly router = inject(Router);
  private readonly rota = inject(ActivatedRoute);

  readonly moeda = formatarMoeda;

  readonly id = signal<number | null>(null);
  readonly editando = computed(() => this.id() !== null);

  // ---- Campos ----
  readonly descricao = signal('');
  readonly subdespesaId = signal<number | null>(null);
  readonly contaId = signal<number | null>(null);
  readonly formaPagamentoId = signal<number | null>(null);
  readonly valorPrevistoTexto = signal('');
  readonly dataVencimento = signal(hojeIso());
  readonly confirmarPagamento = signal(false);
  readonly dataPagamento = signal(hojeIso());
  readonly valorPagoTexto = signal('');
  readonly notaFiscal = signal('');
  readonly cheque = signal('');
  readonly chequeCompensado = signal(false);
  readonly situacao = signal('nenhuma');
  readonly observacao = signal('');

  // ---- Apoio ----
  readonly subdespesas = signal<Subdespesa[]>([]);
  readonly contas = signal<Conta[]>([]);
  readonly formas = signal<FormaPagamento[]>([]);
  readonly buscaSubdespesa = signal('');

  readonly erro = signal<string | null>(null);
  readonly salvando = signal(false);
  readonly carregando = signal(false);

  /** A despesa não é escolhida: vem da subdespesa, como no legado. */
  readonly despesaDaSubdespesa = computed(() => {
    const id = this.subdespesaId();
    return this.subdespesas().find((s) => s.id === id)?.despesa ?? '';
  });

  readonly subdespesasFiltradas = computed(() => {
    const busca = this.buscaSubdespesa().trim().toUpperCase();
    const todas = this.subdespesas();
    if (!busca) return todas;
    return todas.filter(
      (s) => s.descricao.toUpperCase().includes(busca) ||
             (s.despesa ?? '').toUpperCase().includes(busca));
  });

  constructor() {
    this.carregarApoio();

    const parametro = this.rota.snapshot.paramMap.get('id');
    if (parametro) {
      this.id.set(Number(parametro));
      this.carregar(Number(parametro));
    }
  }

  private carregarApoio(): void {
    this.api.subdespesas().subscribe({ next: (s) => this.subdespesas.set(s), error: () => {} });
    this.api.contas().subscribe({ next: (c) => this.contas.set(c), error: () => {} });
    this.api.formasPagamento().subscribe({ next: (f) => this.formas.set(f), error: () => {} });
  }

  private carregar(id: number): void {
    this.carregando.set(true);
    this.api.lancamento(id).subscribe({
      next: (l) => {
        this.descricao.set(l.descricao);
        this.valorPrevistoTexto.set(l.valorPrevisto.toFixed(2).replace('.', ','));
        this.dataVencimento.set(l.dataVencimento ?? hojeIso());
        this.confirmarPagamento.set(l.pago);
        this.dataPagamento.set(l.dataPagamento ?? hojeIso());
        this.valorPagoTexto.set(l.pago ? l.valorPago.toFixed(2).replace('.', ',') : '');
        this.notaFiscal.set(l.notaFiscal ? String(l.notaFiscal) : '');
        this.cheque.set(l.cheque ? String(l.cheque) : '');
        this.chequeCompensado.set(l.chequeCompensado);
        this.situacao.set(l.situacao.toLowerCase());
        this.observacao.set(l.observacao ?? '');

        // Casa a subdespesa pelo nome, já que a consulta devolve o texto.
        const sub = this.subdespesas().find(
          (s) => s.descricao === l.subdespesa && s.despesa === l.despesa);
        if (sub) this.subdespesaId.set(sub.id);

        this.contaId.set(this.contas().find((c) => c.descricao === l.conta)?.id ?? null);
        this.formaPagamentoId.set(
          this.formas().find((f) => f.descricao === l.formaPagamento)?.id ?? null);

        this.carregando.set(false);
      },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  /**
   * Enter na descrição não salva — comportamento suprimido de propósito no legado, para
   * evitar gravação acidental. É reflexo que a operadora já tem.
   */
  aoTeclarNaDescricao(evento: KeyboardEvent): void {
    if (evento.key === 'Enter') evento.preventDefault();
  }

  salvar(): void {
    if (this.salvando()) return;
    this.erro.set(null);

    const valorPrevisto = lerMoeda(this.valorPrevistoTexto());

    // As mesmas quatro obrigatoriedades do legado, mais a forma de pagamento, que o banco
    // exige e ninguém verificava.
    if (!this.descricao().trim()) { this.erro.set('Informe a descrição.'); return; }
    if (valorPrevisto === null) { this.erro.set('Informe o valor previsto.'); return; }
    if (!this.subdespesaId()) { this.erro.set('Escolha a subdespesa.'); return; }
    if (!this.contaId()) { this.erro.set('Escolha a conta.'); return; }
    if (!this.formaPagamentoId()) { this.erro.set('Escolha a forma de pagamento.'); return; }

    const pago = this.confirmarPagamento();
    const valorPago = pago ? lerMoeda(this.valorPagoTexto()) : null;

    const dados: EntradaLancamento = {
      descricao: this.descricao().trim(),
      subdespesaId: this.subdespesaId()!,
      contaId: this.contaId()!,
      formaPagamentoId: this.formaPagamentoId()!,
      valorPrevisto,
      dataVencimento: this.dataVencimento(),
      pago,
      dataPagamento: pago ? this.dataPagamento() : null,
      valorPago,
      notaFiscal: this.notaFiscal() ? Number(this.notaFiscal()) : null,
      cheque: this.cheque() ? Number(this.cheque()) : null,
      chequeCompensado: this.chequeCompensado(),
      situacao: this.situacao(),
      observacao: this.observacao().trim() || null,
    };

    this.salvando.set(true);
    const chamada = this.editando()
      ? this.api.alterar(this.id()!, dados)
      : this.api.lancar(dados);

    chamada.subscribe({
      next: () => this.router.navigate(['/lancamentos']),
      error: (e: Error) => { this.erro.set(e.message); this.salvando.set(false); },
    });
  }

  cancelar(): void { this.router.navigate(['/lancamentos']); }
}
