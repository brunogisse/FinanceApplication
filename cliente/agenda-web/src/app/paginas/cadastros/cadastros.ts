import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { Api } from '../../nucleo/api';
import { Confirmacao } from '../../nucleo/confirmacao';
import { Conta, Despesa, FormaPagamento, Subdespesa } from '../../nucleo/modelos';
import { formatarInteiro } from '../../nucleo/moeda';

/**
 * As três abas. Despesa e subdespesa moram na mesma aba porque são um par: no legado elas
 * dividem a tela UcategoriaGeral, e escolher a despesa é o que dá sentido à lista de baixo.
 */
type Aba = 'contas' | 'formas' | 'despesas';

/** Contas, formas de pagamento e despesas têm a mesma forma: um nome e nada mais. */
interface Simples {
  id: number;
  descricao: string;
}

@Component({
  selector: 'app-cadastros',
  standalone: true,
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './cadastros.html',
  styleUrl: './cadastros.css',
})
export class Cadastros {
  private readonly api = inject(Api);
  private readonly router = inject(Router);
  private readonly confirmacao = inject(Confirmacao);

  readonly inteiro = formatarInteiro;
  readonly usuario = this.api.usuario;

  /** Nível 2 ou 3. O servidor decide de verdade; aqui é só para não oferecer o que será negado. */
  readonly podeEditar = this.api.podeLancar;

  readonly aba = signal<Aba>('contas');

  readonly contas = signal<Conta[]>([]);
  readonly formas = signal<FormaPagamento[]>([]);
  readonly despesas = signal<Despesa[]>([]);
  readonly subdespesas = signal<Subdespesa[]>([]);

  readonly despesaSelecionada = signal<Despesa | null>(null);

  readonly carregando = signal(false);
  readonly erro = signal<string | null>(null);
  readonly aviso = signal<string | null>(null);

  // ---- Edição do nível de cima (a aba corrente) ----
  readonly editandoId = signal<number | null>(null);
  readonly texto = signal('');
  readonly criando = signal(false);

  // ---- Edição da subdespesa, independente da de cima ----
  readonly subEditandoId = signal<number | null>(null);
  readonly subTexto = signal('');
  readonly subDespesaId = signal(0);
  readonly subCriando = signal(false);

  /** A lista que a aba corrente mostra. */
  readonly itens = computed<Simples[]>(() => {
    switch (this.aba()) {
      case 'contas': return this.contas();
      case 'formas': return this.formas();
      case 'despesas': return this.despesas();
    }
  });

  /** Nome do que está sendo cadastrado, no singular, para títulos e mensagens. */
  readonly nomeDoItem = computed(() => {
    switch (this.aba()) {
      case 'contas': return 'conta';
      case 'formas': return 'forma de pagamento';
      case 'despesas': return 'despesa';
    }
  });

  constructor() {
    this.recarregarTudo();
  }

  // ---------------- Carga ----------------

  private recarregarTudo(): void {
    this.carregando.set(true);

    this.api.contas().subscribe({
      next: (c) => this.contas.set(c),
      error: (e: Error) => this.erro.set(e.message),
    });

    this.api.formasPagamento().subscribe({
      next: (f) => this.formas.set(f),
      error: (e: Error) => this.erro.set(e.message),
    });

    this.api.despesas().subscribe({
      next: (d) => {
        this.despesas.set(d);
        this.carregando.set(false);
        // Mantém a despesa escolhida se ela ainda existir. Senão, cai na primeira que tenha
        // nome: o banco de produção carrega uma despesa de descrição vazia (id 41, sem
        // subdespesas e sem uso), e abrir a tela nela não mostraria nada.
        const atual = this.despesaSelecionada();
        const continua = atual ? d.find((x) => x.id === atual.id) : undefined;
        const primeiraComNome = d.find((x) => x.descricao.trim() !== '');
        this.selecionarDespesa(continua ?? primeiraComNome ?? d[0] ?? null);
      },
      error: (e: Error) => {
        this.erro.set(e.message);
        this.carregando.set(false);
      },
    });
  }

  selecionarDespesa(d: Despesa | null): void {
    this.despesaSelecionada.set(d);
    this.cancelarEdicaoSub();

    if (!d) {
      this.subdespesas.set([]);
      return;
    }

    this.api.subdespesas(d.id).subscribe({
      next: (s) => this.subdespesas.set(s),
      error: (e: Error) => {
        this.erro.set(e.message);
        this.subdespesas.set([]);
      },
    });
  }

  trocarAba(aba: Aba): void {
    this.aba.set(aba);
    this.cancelarEdicao();
    this.cancelarEdicaoSub();
    this.limparMensagens();
  }

  limparMensagens(): void {
    this.erro.set(null);
    this.aviso.set(null);
  }

  // ---------------- Edição do nível de cima ----------------

  novo(): void {
    this.criando.set(true);
    this.editandoId.set(null);
    this.texto.set('');
    this.limparMensagens();
  }

  editar(item: Simples): void {
    this.criando.set(false);
    this.editandoId.set(item.id);
    this.texto.set(item.descricao);
    this.limparMensagens();
  }

  cancelarEdicao(): void {
    this.criando.set(false);
    this.editandoId.set(null);
    this.texto.set('');
  }

  salvar(): void {
    const descricao = this.texto().trim();
    if (!descricao) {
      this.erro.set('Informe a descrição.');
      return;
    }

    const id = this.editandoId();
    const chamada = id === null
      ? this.criarNaAba(descricao)
      : this.alterarNaAba(id, descricao);

    this.executar(chamada, id === null
      ? 'Cadastrado: ' + descricao + '.'
      : 'Alterado para: ' + descricao + '.');
  }

  private criarNaAba(descricao: string): Observable<unknown> {
    switch (this.aba()) {
      case 'contas': return this.api.criarConta(descricao);
      case 'formas': return this.api.criarFormaPagamento(descricao);
      case 'despesas': return this.api.criarDespesa(descricao);
    }
  }

  private alterarNaAba(id: number, descricao: string): Observable<unknown> {
    switch (this.aba()) {
      case 'contas': return this.api.alterarConta(id, descricao);
      case 'formas': return this.api.alterarFormaPagamento(id, descricao);
      case 'despesas': return this.api.alterarDespesa(id, descricao);
    }
  }

  private excluirNaAba(id: number): Observable<unknown> {
    switch (this.aba()) {
      case 'contas': return this.api.excluirConta(id);
      case 'formas': return this.api.excluirFormaPagamento(id);
      case 'despesas': return this.api.excluirDespesa(id);
    }
  }

  async excluir(item: Simples): Promise<void> {
    // A confirmação repete o nome inteiro: numa lista, o que se apaga por engano é a linha vizinha.
    const ok = await this.confirmacao.perguntar({
      titulo: `Excluir a ${this.nomeDoItem()}?`,
      linhas: [this.rotulo(item.descricao)],
      alerta: 'Se houver lançamentos usando esta ' + this.nomeDoItem() + ', a exclusão é recusada.',
      confirmar: 'Excluir',
      perigo: true,
    });
    if (!ok) return;

    this.executar(this.excluirNaAba(item.id), item.descricao + ' foi excluída.');
  }

  // ---------------- Subdespesas ----------------

  novaSub(): void {
    const d = this.despesaSelecionada();
    if (!d) {
      this.erro.set('Escolha primeiro a despesa.');
      return;
    }

    this.subCriando.set(true);
    this.subEditandoId.set(null);
    this.subTexto.set('');
    this.subDespesaId.set(d.id);
    this.limparMensagens();
  }

  editarSub(s: Subdespesa): void {
    this.subCriando.set(false);
    this.subEditandoId.set(s.id);
    this.subTexto.set(s.descricao);
    this.subDespesaId.set(s.despesaId);
    this.limparMensagens();
  }

  cancelarEdicaoSub(): void {
    this.subCriando.set(false);
    this.subEditandoId.set(null);
    this.subTexto.set('');
  }

  salvarSub(): void {
    const descricao = this.subTexto().trim();
    if (!descricao) {
      this.erro.set('Informe a descrição da subdespesa.');
      return;
    }

    const despesaId = Number(this.subDespesaId());
    if (!despesaId) {
      this.erro.set('Escolha a despesa da subdespesa.');
      return;
    }

    const id = this.subEditandoId();
    const chamada = id === null
      ? this.api.criarSubdespesa(descricao, despesaId)
      : this.api.alterarSubdespesa(id, descricao, despesaId);

    const destino = this.despesas().find((d) => d.id === despesaId);
    const nomeDoDestino = destino ? this.rotulo(destino.descricao) : '';

    // Mover para outra despesa faz a subdespesa sumir da lista em tela. Dizer para onde ela
    // foi evita a conclusão de que sumiu.
    const mudouDeDespesa = destino !== undefined && this.despesaSelecionada()?.id !== despesaId;

    // A subdespesa nasce na despesa que está marcada na lista da esquerda. Nomear essa
    // despesa na confirmação é o que permite perceber, na hora, que ela caiu no lugar
    // errado — depois de pronta, só se descobre pelo relatório.
    const mensagem = mudouDeDespesa
      ? `${descricao} agora pertence à despesa ${nomeDoDestino}.`
      : id === null
        ? `${descricao} criada na despesa ${nomeDoDestino}.`
        : `Subdespesa salva: ${descricao}.`;

    this.executar(chamada, mensagem);
  }

  async excluirSub(s: Subdespesa): Promise<void> {
    const ok = await this.confirmacao.perguntar({
      titulo: 'Excluir a subdespesa?',
      linhas: [
        s.descricao,
        `da despesa ${this.rotulo(this.despesaSelecionada()?.descricao ?? '')}`,
      ],
      alerta: 'Se houver lançamentos usando esta subdespesa, a exclusão é recusada.',
      confirmar: 'Excluir',
      perigo: true,
    });
    if (!ok) return;

    this.executar(this.api.excluirSubdespesa(s.id), s.descricao + ' foi excluída.');
  }

  // ---------------- Comum ----------------

  /**
   * Executa a chamada e recarrega as listas.
   *
   * Recarregar do servidor em vez de remendar a lista em memória é deliberado: o Delphi mexe
   * no mesmo banco ao mesmo tempo, e a lista em tela não é dona da verdade.
   */
  private executar(chamada: Observable<unknown>, mensagem: string): void {
    this.carregando.set(true);
    this.limparMensagens();

    chamada.subscribe({
      next: () => {
        this.cancelarEdicao();
        this.cancelarEdicaoSub();
        this.aviso.set(mensagem);
        this.recarregarTudo();
      },
      error: (e: Error) => {
        // A recusa do servidor é a razão real — "há 340 lançamentos usando esta conta", por
        // exemplo. Reescrever aqui esconderia o que a pessoa precisa para resolver sozinha.
        this.erro.set(e.message);
        this.carregando.set(false);
      },
    });
  }

  /** Enter salva, Esc cancela — o reflexo de quem cadastra vários itens seguidos. */
  aoTeclar(evento: KeyboardEvent, subdespesa = false): void {
    if (evento.key === 'Enter') {
      evento.preventDefault();
      if (subdespesa) this.salvarSub(); else this.salvar();
    }
    if (evento.key === 'Escape') {
      evento.preventDefault();
      if (subdespesa) this.cancelarEdicaoSub(); else this.cancelarEdicao();
    }
  }

  /**
   * Como o nome aparece na lista.
   *
   * O legado deixou registros de descrição vazia — uma despesa e algumas contas. Mostrar a
   * linha em branco parece defeito da tela; escondê-la esconderia um registro que existe e
   * que alguém precisa poder corrigir ou apagar. O rótulo resolve os dois.
   */
  rotulo(descricao: string): string {
    return descricao.trim() === '' ? '(sem descrição)' : descricao;
  }

  semNome(descricao: string): boolean {
    return descricao.trim() === '';
  }

  voltar(): void {
    this.router.navigate(['/lancamentos']);
  }
}
