import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Api } from '../../nucleo/api';
import { Conta, Despesa, FiltroConsulta, Lancamento } from '../../nucleo/modelos';
import { formatarData, formatarInteiro, formatarMoeda, hojeIso, somarMeses } from '../../nucleo/moeda';

@Component({
  selector: 'app-lancamentos',
  standalone: true,
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './lancamentos.html',
  styleUrl: './lancamentos.css',
})
export class Lancamentos {
  private readonly api = inject(Api);
  private readonly router = inject(Router);

  readonly moeda = formatarMoeda;
  readonly data = formatarData;
  readonly inteiro = formatarInteiro;

  // ---- Filtros. O período padrão é o mesmo da tela do legado: últimos seis meses. ----
  readonly inicio = signal(somarMeses(hojeIso(), -6));
  readonly fim = signal(hojeIso());
  readonly porData = signal<'vencimento' | 'pagamento' | 'cadastro'>('vencimento');
  readonly pagamento = signal<'todos' | 'pagos' | 'naopagos'>('todos');
  readonly descricao = signal('');
  readonly despesa = signal('');
  readonly conta = signal('');

  // ---- Estado da tela ----
  readonly lancamentos = signal<Lancamento[]>([]);
  readonly totalPrevisto = signal(0);
  readonly totalPago = signal(0);
  readonly carregando = signal(false);
  readonly erro = signal<string | null>(null);
  readonly aviso = signal<string | null>(null);
  readonly selecionados = signal<ReadonlySet<number>>(new Set());

  readonly despesas = signal<Despesa[]>([]);
  readonly contas = signal<Conta[]>([]);

  /**
   * Aviso de vencimentos, equivalente ao "Há N despesa(s) a pagar" que o legado mostra ao
   * abrir. É a primeira coisa que a operadora vê no sistema atual.
   */
  readonly vencidos = signal(0);
  readonly totalVencido = signal(0);
  readonly avisoDispensado = signal(false);

  readonly usuario = this.api.usuario;
  readonly podeLancar = this.api.podeLancar;

  readonly quantidade = computed(() => this.lancamentos().length);
  readonly temSelecao = computed(() => this.selecionados().size > 0);
  readonly quantidadeSelecionada = computed(() => this.selecionados().size);

  /** Quanto os selecionados somam. Vem da lista já carregada, apenas para orientar. */
  readonly previstoSelecionado = computed(() => {
    const escolhidos = this.selecionados();
    // Soma em centavos inteiros: number com decimal acumula erro, e dinheiro não perdoa.
    const centavos = this.lancamentos()
      .filter((l) => escolhidos.has(l.id))
      .reduce((s, l) => s + Math.round(l.valorPrevisto * 100), 0);
    return centavos / 100;
  });

  constructor() {
    this.carregarCadastros();
    this.carregarVencimentos();
    this.pesquisar();
  }

  private carregarCadastros(): void {
    this.api.despesas().subscribe({ next: (d) => this.despesas.set(d), error: () => {} });
    this.api.contas().subscribe({ next: (c) => this.contas.set(c), error: () => {} });
  }

  private carregarVencimentos(): void {
    this.api.vencimentos().subscribe({
      next: (r) => {
        this.vencidos.set(r.quantidade);
        this.totalVencido.set(r.totalPrevisto);
      },
      error: () => {},
    });
  }

  /** Deixa na tela apenas o que está vencido ou vence hoje e ainda não foi pago. */
  verVencimentos(): void {
    this.porData.set('vencimento');
    this.pagamento.set('naopagos');
    this.descricao.set('');
    this.despesa.set('');
    this.conta.set('');
    // Começo bem atrás para não esconder atraso antigo — o legado não limita o início.
    this.inicio.set(somarMeses(hojeIso(), -120));
    this.fim.set(hojeIso());
    this.pesquisar();
  }

  pesquisar(): void {
    this.carregando.set(true);
    this.erro.set(null);
    this.selecionados.set(new Set());

    const filtro: FiltroConsulta = {
      inicio: this.inicio(),
      fim: this.fim(),
      porData: this.porData(),
      pagamento: this.pagamento(),
      descricao: this.descricao() || undefined,
      despesa: this.despesa() || undefined,
      conta: this.conta() || undefined,
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
        this.lancamentos.set([]);
      },
    });
  }

  limparFiltros(): void {
    this.descricao.set('');
    this.despesa.set('');
    this.conta.set('');
    this.pagamento.set('todos');
    this.porData.set('vencimento');
    this.inicio.set(somarMeses(hojeIso(), -6));
    this.fim.set(hojeIso());
    this.pesquisar();
  }

  /** Enter no campo de busca dispara a pesquisa — reflexo que a operadora já tem. */
  aoTeclar(evento: KeyboardEvent): void {
    if (evento.key === 'Enter') { evento.preventDefault(); this.pesquisar(); }
  }

  // ---- Seleção ----

  alternarSelecao(id: number): void {
    const novo = new Set(this.selecionados());
    novo.has(id) ? novo.delete(id) : novo.add(id);
    this.selecionados.set(novo);
  }

  estaSelecionado(id: number): boolean {
    return this.selecionados().has(id);
  }

  selecionarNaoPagos(): void {
    this.selecionados.set(new Set(
      this.lancamentos().filter((l) => !l.pago).map((l) => l.id),
    ));
  }

  limparSelecao(): void {
    this.selecionados.set(new Set());
  }

  // ---- Ações ----

  pagarSelecionados(): void {
    const ids = [...this.selecionados()];
    if (ids.length === 0) return;

    const total = this.moeda(this.previstoSelecionado());
    if (!confirm(
      `Confirmar o pagamento de ${ids.length} lançamento(s), somando ${total}?\n\n` +
      `A data de pagamento será hoje e o valor pago receberá o valor previsto.`,
    )) return;

    this.carregando.set(true);
    this.api.pagarEmLote(ids).subscribe({
      next: (r) => {
        // O resultado discrimina o destino de cada item, em vez de silenciar.
        const partes = [`${r.quantidade} lançamento(s) pago(s), somando ${this.moeda(r.totalPago)}.`];
        if (r.jaEstavamPagos.length) partes.push(`${r.jaEstavamPagos.length} já estava(m) pago(s).`);
        if (r.semPermissao.length) partes.push(`${r.semPermissao.length} sem permissão.`);
        if (r.naoEncontrados.length) partes.push(`${r.naoEncontrados.length} não encontrado(s).`);
        this.aviso.set(partes.join(' '));
        this.pesquisar();
      },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  parcelar(l: Lancamento): void {
    const resposta = prompt(
      `Parcelar "${l.descricao}" de ${this.moeda(l.valorPrevisto)} em quantas vezes?`, '2');
    if (!resposta) return;

    const parcelas = Number(resposta);
    if (!Number.isInteger(parcelas) || parcelas < 2) {
      this.erro.set('Informe um número inteiro de parcelas, a partir de 2.');
      return;
    }

    if (!confirm(
      `Serão geradas ${parcelas} parcelas e o lançamento original será excluído.\n\n` +
      `A soma das parcelas será exatamente ${this.moeda(l.valorPrevisto)}.`,
    )) return;

    this.carregando.set(true);
    this.api.parcelar(l.id, parcelas).subscribe({
      next: (r) => {
        this.aviso.set(
          `${r.parcelas.length} parcelas geradas, somando ${this.moeda(r.somaDasParcelas)}` +
          (r.fechou ? ' — fechou o valor original.' : ' — ATENÇÃO: não fechou o valor original.'));
        this.pesquisar();
      },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  excluir(l: Lancamento): void {
    if (!confirm(`Excluir "${l.descricao}" de ${this.moeda(l.valorPrevisto)}?`)) return;

    this.carregando.set(true);
    this.api.excluir(l.id).subscribe({
      next: () => { this.aviso.set('Lançamento excluído.'); this.pesquisar(); },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  novo(): void { this.router.navigate(['/lancamentos/novo']); }
  editar(l: Lancamento): void { this.router.navigate(['/lancamentos', l.id]); }
  relatorio(): void { this.router.navigate(['/relatorios/por-despesa']); }
  cadastros(): void { this.router.navigate(['/cadastros']); }

  sair(): void {
    this.api.sair();
    this.router.navigate(['/login']);
  }

  /** Classe da linha. A cor é informação: a operadora lê a grade por ela antes do texto. */
  classeDaLinha(l: Lancamento): string {
    if (l.situacao === 'Aguardando') return 'linha-aguardando';
    if (l.pago) return 'linha-paga';
    return '';
  }
}
