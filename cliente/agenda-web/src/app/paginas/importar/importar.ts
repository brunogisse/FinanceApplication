import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Api } from '../../nucleo/api';
import {
  Conta, Despesa, FormaPagamento, PreviaImportacao, ResultadoImportacao, Subdespesa,
} from '../../nucleo/modelos';
import { formatarData, formatarInteiro, formatarMoeda } from '../../nucleo/moeda';

/**
 * Importação de um lote de pagamentos a partir de planilha.
 *
 * A tela é dividida em dois momentos porque a operação é: o lote entra inteiro, já quitado,
 * com as datas históricas da planilha, e **não tem desfazer**. Primeiro a pessoa vê o que
 * sairia dali; só depois grava.
 */
@Component({
  selector: 'app-importar',
  standalone: true,
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './importar.html',
  styleUrl: './importar.css',
})
export class Importar {
  private readonly api = inject(Api);
  private readonly router = inject(Router);

  readonly moeda = formatarMoeda;
  readonly data = formatarData;
  readonly inteiro = formatarInteiro;

  readonly usuario = this.api.usuario;
  /** Só nível 3 importa, como no legado. O servidor recusa de todo jeito. */
  readonly podeImportar = this.api.podeImportar;

  readonly despesas = signal<Despesa[]>([]);
  readonly subdespesas = signal<Subdespesa[]>([]);
  readonly contas = signal<Conta[]>([]);
  readonly formas = signal<FormaPagamento[]>([]);

  readonly despesaId = signal(0);
  readonly subdespesaId = signal(0);
  readonly contaId = signal(0);
  readonly formaPagamentoId = signal(0);

  readonly arquivo = signal<File | null>(null);
  readonly previa = signal<PreviaImportacao | null>(null);
  readonly resultado = signal<ResultadoImportacao | null>(null);

  readonly carregando = signal(false);
  readonly erro = signal<string | null>(null);

  readonly nomeDoArquivo = computed(() => this.arquivo()?.name ?? '');

  /** Tudo escolhido e planilha conferida: só então dá para gravar. */
  readonly podeGravar = computed(() =>
    this.previa() !== null &&
    Number(this.subdespesaId()) > 0 &&
    Number(this.contaId()) > 0 &&
    Number(this.formaPagamentoId()) > 0);

  readonly despesaEscolhida = computed(() =>
    this.despesas().find((d) => d.id === Number(this.despesaId()))?.descricao ?? '');

  readonly destino = computed(() => {
    const sub = this.subdespesas().find((s) => s.id === Number(this.subdespesaId()));
    const conta = this.contas().find((c) => c.id === Number(this.contaId()));
    const forma = this.formas().find((f) => f.id === Number(this.formaPagamentoId()));
    if (!sub || !conta || !forma) return null;
    return { subdespesa: sub.descricao, conta: conta.descricao, forma: forma.descricao };
  });

  constructor() {
    this.api.despesas().subscribe({
      next: (d) => this.despesas.set(d.filter((x) => x.descricao.trim() !== '')),
      error: (e: Error) => this.erro.set(e.message),
    });
    this.api.contas().subscribe({
      next: (c) => this.contas.set(c),
      error: (e: Error) => this.erro.set(e.message),
    });
    this.api.formasPagamento().subscribe({
      next: (f) => this.formas.set(f),
      error: (e: Error) => this.erro.set(e.message),
    });
  }

  /** Trocar a despesa recarrega as subdespesas e zera a escolha anterior. */
  trocarDespesa(id: number): void {
    this.despesaId.set(Number(id));
    this.subdespesaId.set(0);
    this.subdespesas.set([]);
    if (!Number(id)) return;

    this.api.subdespesas(Number(id)).subscribe({
      next: (s) => this.subdespesas.set(s),
      error: (e: Error) => this.erro.set(e.message),
    });
  }

  escolherArquivo(evento: Event): void {
    const entrada = evento.target as HTMLInputElement;
    const escolhido = entrada.files?.[0] ?? null;

    this.arquivo.set(escolhido);
    // Trocar de arquivo invalida o que estava conferido: a prévia é daquele arquivo.
    this.previa.set(null);
    this.resultado.set(null);
    this.erro.set(null);

    if (escolhido) this.conferir();
  }

  /** Lê a planilha no servidor e mostra o que ela produziria, sem gravar nada. */
  conferir(): void {
    const arquivo = this.arquivo();
    if (!arquivo) { this.erro.set('Escolha a planilha.'); return; }

    this.carregando.set(true);
    this.erro.set(null);

    this.api.previaImportacao(arquivo).subscribe({
      next: (p) => { this.previa.set(p); this.carregando.set(false); },
      error: (e: Error) => {
        // Erro de formato aparece aqui, antes de qualquer escrita — que é o objetivo.
        this.erro.set(e.message);
        this.previa.set(null);
        this.carregando.set(false);
      },
    });
  }

  importar(): void {
    const arquivo = this.arquivo();
    const p = this.previa();
    const d = this.destino();
    if (!arquivo || !p || !d) return;

    const pergunta =
      `Importar ${p.quantidade} lançamento(s), somando ${this.moeda(p.total)}?\n\n` +
      `Todos entram QUITADOS, com a data de pagamento que está na planilha, em:\n` +
      `  ${d.subdespesa} / ${d.conta} / ${d.forma}\n\n` +
      `Esta operação não tem desfazer.`;
    if (!confirm(pergunta)) return;

    this.carregando.set(true);
    this.erro.set(null);

    this.api.importarPlanilha(
      arquivo, Number(this.subdespesaId()), Number(this.contaId()), Number(this.formaPagamentoId()),
    ).subscribe({
      next: (r) => {
        this.resultado.set(r);
        this.previa.set(null);
        this.arquivo.set(null);
        this.carregando.set(false);
      },
      error: (e: Error) => {
        // O lote é uma transação só: se falhou, nada foi gravado.
        this.erro.set(e.message);
        this.carregando.set(false);
      },
    });
  }

  recomecar(): void {
    this.arquivo.set(null);
    this.previa.set(null);
    this.resultado.set(null);
    this.erro.set(null);
  }

  voltar(): void {
    this.router.navigate(['/lancamentos']);
  }
}
