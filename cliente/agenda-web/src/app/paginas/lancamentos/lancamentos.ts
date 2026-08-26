import {
  ChangeDetectionStrategy, Component, ElementRef, computed, inject, signal, viewChild,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Api } from '../../nucleo/api';
import { Conta, Despesa, FiltroConsulta, Lancamento, Subdespesa } from '../../nucleo/modelos';
import {
  formatarData, formatarInteiro, formatarMoeda, hojeIso, lerMoeda, somarDias, somarMeses,
  somarMesesNoCalendario,
} from '../../nucleo/moeda';
import { baixarArquivo } from '../../nucleo/arquivos';
import { Confirmacao } from '../../nucleo/confirmacao';
import { MascaraMoeda } from '../../nucleo/mascara-moeda';

/**
 * Período que cobre a base inteira, usado na busca por documento.
 *
 * O fim vai longe de propósito: há financiamentos com parcelas vencendo anos à frente, e um
 * fim em "hoje" esconderia justamente a parcela que a pessoa está procurando.
 */
const INICIO_DE_TUDO = '2000-01-01';
const FIM_DE_TUDO = '2099-12-31';

/** Tamanho da coluna DESCRICAO no banco do legado. */
const TAMANHO_MAXIMO_DESCRICAO = 200;

/**
 * Uma linha da tabela de ajuste das parcelas.
 *
 * O valor fica como **texto**, do jeito que foi digitado, e só vira número na hora de somar
 * ou de enviar. Guardar número aqui obrigaria a reformatar a cada tecla e a operadora perderia
 * a vírgula no meio da digitação.
 */
interface LinhaParcela {
  numero: number;
  vencimento: string;
  valor: string;
  descricao: string;
}

/** Texto de campo numérico: vazio ou não numérico vira "sem filtro", nunca zero. */
function numeroOuNada(texto: string): number | undefined {
  const limpo = texto.trim();
  if (limpo === '') return undefined;
  const valor = Number(limpo);
  return Number.isFinite(valor) ? valor : undefined;
}

@Component({
  selector: 'app-lancamentos',
  standalone: true,
  imports: [FormsModule, MascaraMoeda],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './lancamentos.html',
  styleUrl: './lancamentos.css',
})
export class Lancamentos {
  private readonly api = inject(Api);
  private readonly router = inject(Router);
  private readonly rota = inject(ActivatedRoute);
  private readonly confirmacao = inject(Confirmacao);

  readonly moeda = formatarMoeda;
  readonly data = formatarData;
  readonly inteiro = formatarInteiro;
  /** Exposto para o template: o modelo não alcança globais do JavaScript. */
  readonly Math = Math;

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
  readonly exportando = signal(false);

  readonly despesas = signal<Despesa[]>([]);
  readonly contas = signal<Conta[]>([]);
  readonly todasSubdespesas = signal<Subdespesa[]>([]);

  // ---- Busca avançada: é a segunda aba de pesquisa do legado ----
  readonly buscaAvancadaAberta = signal(false);
  readonly subdespesa = signal('');
  readonly notaFiscal = signal('');
  readonly cheque = signal('');
  readonly chequeCompensado = signal<'' | 'sim' | 'nao'>('');
  readonly situacao = signal<'' | 'aguardando' | 'liberada' | 'nenhuma'>('');
  readonly valorMinimoTexto = signal('');
  readonly valorMaximoTexto = signal('');
  readonly faixaSobreValorPago = signal(false);

  /** Só as subdespesas da despesa escolhida — ou todas, se não houver despesa escolhida. */
  readonly subdespesasDisponiveis = computed(() => {
    const despesa = this.despesa();
    if (!despesa) return this.todasSubdespesas();

    const id = this.despesas().find((d) => d.descricao === despesa)?.id;
    return id === undefined
      ? this.todasSubdespesas()
      : this.todasSubdespesas().filter((s) => s.despesaId === id);
  });

  /**
   * Quantos filtros avançados estão valendo.
   *
   * O painel fica fechado por padrão, e filtro ativo escondido é armadilha: a pessoa
   * pesquisa, vê pouca coisa e não entende por quê. O número aparece ao lado do título.
   */
  readonly filtrosAvancadosAtivos = computed(() =>
    [this.subdespesa(), this.notaFiscal(), this.cheque(), this.chequeCompensado(),
     this.situacao(), this.valorMinimoTexto(), this.valorMaximoTexto()]
      .filter((v) => v !== '').length);

  /**
   * Há faixa de valor de verdade?
   *
   * "Faixa sobre" não é um filtro: é o modificador de "de" e "até". Sem pelo menos um dos
   * dois, o servidor não aplica nada — medido em 23/08/2026 contra a base real: 4.741
   * lançamentos com a faixa em "pago", em "previsto" e sem escolher nada. Com "de 1.000",
   * previsto dá 1.614 e pago dá 1.425.
   *
   * A regra do servidor está certa, e é a do legado. Quem enganava era esta tela, que punha
   * o "sobre" solto ao lado, com a mesma cara de um filtro independente.
   *
   * `lerMoeda` e não `!== ''`: um campo com texto que não vira número — só espaço, um
   * traço — também não produz faixa nenhuma.
   */
  readonly temFaixaDeValor = computed(() =>
    lerMoeda(this.valorMinimoTexto()) !== null || lerMoeda(this.valorMaximoTexto()) !== null);

  /**
   * Procurar por NF ou por número de cheque é procurar um documento: a data em que ele foi
   * lançado não vem ao caso, e limitar aos últimos seis meses faria a busca falhar sem
   * explicar por quê. O legado tem a mesma intenção — força o início em 01/01/2018 quando a
   * busca é por nota fiscal.
   *
   * Divergência intencional: no legado, a busca por cheque compensado também ignora o
   * período, o que devolve a base inteira. Aqui só a busca por documento amplia; as demais
   * respeitam o período que está na tela, que é o que ela mostra.
   */
  readonly buscaPorDocumento = computed(() =>
    this.notaFiscal() !== '' || this.cheque() !== '');

  // ---- Parcelamento ----
  readonly dialogoParcelar = viewChild<ElementRef<HTMLDialogElement>>('dialogoParcelar');
  readonly parcelando = signal<Lancamento | null>(null);
  readonly parcelas = signal('2');

  /**
   * Prévia da divisão, antes de confirmar.
   *
   * O legado divide e arredonda cada parcela, e a soma não fecha o valor original. Aqui a
   * conta é a mesma do servidor: divisão em centavos inteiros, com o resto distribuído nas
   * primeiras parcelas. Mostrar isso antes é o que permite conferir.
   *
   * A aritmética é em centavos inteiros justamente para não repetir em JavaScript o defeito
   * que motivou a migração — ver o comentário em modelos.ts.
   */
  readonly previaParcelas = computed(() => {
    const l = this.parcelando();
    const n = Number(this.parcelas());
    if (!l || !Number.isInteger(n) || n < 2) return null;

    const centavos = Math.round(l.valorPrevisto * 100);
    const base = Math.floor(centavos / n);
    const resto = centavos - base * n;

    const maior = formatarMoeda((base + 1) / 100);
    const menor = formatarMoeda(base / 100);

    const texto = resto === 0
      ? `${n} parcelas de ${menor}`
      : `${resto} parcela(s) de ${maior} e ${n - resto} de ${menor}`;

    return { texto, soma: formatarMoeda(centavos / 100) };
  });

  // ---- Segundo passo: as parcelas na tela, para ajustar antes de gravar ----
  //
  // Elas ficam em memória até a operadora mandar gravar. Gravar primeiro e corrigir depois
  // devolveria dois problemas de uma vez: a parcela nasce uma por mês, então a maioria cai
  // fora do período em tela no instante seguinte e vira caça; e o parcelamento deixaria de
  // ser uma transação só, que é justamente a divergência intencional em relação ao legado.
  readonly passoParcelamento = signal<1 | 2>(1);
  readonly parcelasEditaveis = signal<LinhaParcela[]>([]);

  /** Soma das parcelas em centavos inteiros — nunca em ponto flutuante. */
  readonly somaDasParcelas = computed(() =>
    this.parcelasEditaveis().reduce(
      (total, p) => total + Math.round((lerMoeda(p.valor) ?? 0) * 100), 0));

  /**
   * Quanto a soma se afastou do valor original, em centavos.
   *
   * Diferença **não impede de gravar**: juros de financiamento fazem a soma passar do previsto
   * legitimamente, e recusar obrigaria a lançar tudo de novo por fora. A tela mostra e deixa
   * decidir.
   */
  readonly diferencaDasParcelas = computed(() => {
    const l = this.parcelando();
    if (!l) return 0;
    return this.somaDasParcelas() - Math.round(l.valorPrevisto * 100);
  });

  /** A primeira linha com problema, para o rodapé dizer o que falta antes de gravar. */
  readonly problemaNasParcelas = computed(() => {
    const linhas = this.parcelasEditaveis();

    for (const p of linhas) {
      const valor = lerMoeda(p.valor);
      if (valor === null || Math.round(valor * 100) === 0)
        return `A parcela ${p.numero} está sem valor.`;
      if (valor < 0)
        return `A parcela ${p.numero} tem valor negativo.`;
      if (!p.vencimento)
        return `A parcela ${p.numero} está sem vencimento.`;
      if (p.descricao.trim() === '')
        return `A parcela ${p.numero} está sem descrição.`;
    }

    return null;
  });

  /**
   * Quando a grade está mostrando as parcelas que acabaram de nascer, e não o resultado do
   * filtro. Sem isto elas sumiriam da vista no instante em que foram criadas.
   */
  readonly parcelasRecemCriadas = signal(false);

  /**
   * De onde a pessoa veio, quando chegou por um card do painel.
   *
   * O aviso "Há N despesa(s) a pagar" que o legado dá ao abrir virou o primeiro card do
   * painel, e é ele que traz para cá já filtrado. Repetir o aviso nesta tela seria dizer duas
   * vezes a mesma coisa.
   */
  readonly descricaoDoAtalho = signal<string | null>(null);

  readonly usuario = this.api.usuario;
  readonly podeLancar = this.api.podeLancar;
  readonly podeImportar = this.api.podeImportar;

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
    this.aplicarAtalho();
    this.pesquisar();
  }

  /**
   * Aplica o filtro que veio do painel, pela URL.
   *
   * Vem pela URL e não por estado compartilhado para a tela continuar sendo uma página por si
   * só: recarregar mantém o mesmo recorte, e o endereço descreve o que está em tela.
   */
  private aplicarAtalho(): void {
    const p = this.rota.snapshot.queryParamMap;
    const atalho = p.get('atalho');
    if (!atalho) return;

    switch (atalho) {
      case 'vencidos':
        this.porData.set('vencimento');
        this.pagamento.set('naopagos');
        // Começo bem atrás para não esconder atraso antigo — o legado não limita o início.
        this.inicio.set(somarMeses(hojeIso(), -120));
        this.fim.set(hojeIso());
        this.descricaoDoAtalho.set('vencidos ou vencendo hoje');
        break;

      /* O mesmo recorte do alerta "vence nos próximos 7 dias" do painel. A data-fim sai de
         `somarDias`, a mesma função que o painel usa — se cada um fizesse a conta, um erro
         de um dia viraria "o painel diz 14 e a grade mostra 15". */
      case 'proximos':
        this.porData.set('vencimento');
        this.pagamento.set('naopagos');
        this.inicio.set(hojeIso());
        this.fim.set(somarDias(hojeIso(), 7));
        this.descricaoDoAtalho.set('vencendo nos próximos 7 dias');
        break;

      case 'dia': {
        const dia = p.get('dia');
        if (!dia) return;
        this.porData.set('vencimento');
        this.pagamento.set('todos');
        this.inicio.set(dia);
        this.fim.set(dia);
        this.descricaoDoAtalho.set(`vencendo em ${formatarData(dia)}`);
        break;
      }

      case 'periodo':
      case 'despesa': {
        const inicio = p.get('inicio');
        const fim = p.get('fim');
        if (inicio) this.inicio.set(inicio);
        if (fim) this.fim.set(fim);
        this.porData.set('vencimento');
        this.pagamento.set('todos');

        if (atalho === 'despesa') {
          const despesa = p.get('despesa') ?? '';
          this.despesa.set(despesa);
          // O card mostra o que foi pago no mês; o recorte aqui precisa ser o mesmo.
          this.porData.set('pagamento');
          this.pagamento.set('pagos');
          this.descricaoDoAtalho.set(`pagos em ${despesa}`);
        } else {
          this.descricaoDoAtalho.set('vencimentos do mês');
        }
        break;
      }
    }
  }

  private carregarCadastros(): void {
    this.api.despesas().subscribe({ next: (d) => this.despesas.set(d), error: () => {} });
    this.api.contas().subscribe({ next: (c) => this.contas.set(c), error: () => {} });
    // São 148 subdespesas: carregar todas de uma vez sai mais barato que ir ao servidor a
    // cada troca de despesa.
    this.api.subdespesas().subscribe({ next: (s) => this.todasSubdespesas.set(s), error: () => {} });
  }

  /**
   * O filtro como está na tela agora.
   *
   * Uma função só, usada pela consulta e pela exportação: a planilha precisa trazer
   * exatamente o que está na grade, e duas montagens separadas divergiriam mais cedo ou
   * mais tarde.
   */
  private filtroAtual(): FiltroConsulta {
    const periodo = this.buscaPorDocumento()
      ? { inicio: INICIO_DE_TUDO, fim: FIM_DE_TUDO }
      : { inicio: this.inicio(), fim: this.fim() };

    return {
      ...periodo,
      porData: this.porData(),
      pagamento: this.pagamento(),
      descricao: this.descricao() || undefined,
      despesa: this.despesa() || undefined,
      conta: this.conta() || undefined,
      subdespesa: this.subdespesa() || undefined,
      notaFiscal: numeroOuNada(this.notaFiscal()),
      cheque: numeroOuNada(this.cheque()),
      chequeCompensado: this.chequeCompensado() === ''
        ? undefined
        : this.chequeCompensado() === 'sim',
      situacao: this.situacao() || undefined,
      // Vírgula decimal, como a operadora digita há três anos.
      valorMinimo: lerMoeda(this.valorMinimoTexto()) ?? undefined,
      valorMaximo: lerMoeda(this.valorMaximoTexto()) ?? undefined,
      // Só viaja com uma faixa junto. Sozinho ele não filtra nada, e mandá-lo assim
      // apareceria no endereço e no cabeçalho do relatório impresso como se filtrasse.
      faixaSobreValorPago:
        this.temFaixaDeValor() && this.faixaSobreValorPago() ? true : undefined,
    };
  }

  limparBuscaAvancada(): void {
    this.subdespesa.set('');
    this.notaFiscal.set('');
    this.cheque.set('');
    this.chequeCompensado.set('');
    this.situacao.set('');
    this.valorMinimoTexto.set('');
    this.valorMaximoTexto.set('');
    this.faixaSobreValorPago.set(false);
  }

  pesquisar(): void {
    this.carregando.set(true);
    this.erro.set(null);
    this.selecionados.set(new Set());
    // Qualquer pesquisa nova encerra o modo "recém-criadas": o que a grade mostra volta a
    // ser o que o filtro diz.
    this.parcelasRecemCriadas.set(false);

    this.api.consultar(this.filtroAtual()).subscribe({
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
    this.limparBuscaAvancada();
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

  /** Todos os não pagos que estão em tela já estão marcados. */
  readonly todosNaoPagosMarcados = computed(() => {
    const naoPagos = this.lancamentos().filter((l) => !l.pago);
    if (naoPagos.length === 0) return false;

    const escolhidos = this.selecionados();
    return naoPagos.every((l) => escolhidos.has(l.id));
  });

  /** Há seleção, mas não é o conjunto inteiro — é o estado indeterminado da caixa. */
  readonly selecaoParcial = computed(() =>
    this.selecionados().size > 0 && !this.todosNaoPagosMarcados());

  /**
   * A caixa do cabeçalho marca e **desmarca**.
   *
   * Antes ela só marcava: clicar de novo repetia a mesma seleção e nada acontecia, o que
   * parece a tela travada. Marcar acrescenta aos já escolhidos em vez de substituir, para
   * não desfazer uma linha paga que a pessoa tenha marcado à mão.
   */
  alternarTodos(): void {
    if (this.todosNaoPagosMarcados()) {
      this.limparSelecao();
      return;
    }

    const novo = new Set(this.selecionados());
    for (const l of this.lancamentos()) {
      if (!l.pago) novo.add(l.id);
    }
    this.selecionados.set(novo);
  }

  limparSelecao(): void {
    this.selecionados.set(new Set());
  }

  // ---- Ações ----

  async pagarSelecionados(): Promise<void> {
    const ids = [...this.selecionados()];
    if (ids.length === 0) return;

    const ok = await this.confirmacao.perguntar({
      titulo: `Pagar ${this.inteiro(ids.length)} lançamentos?`,
      linhas: [
        `Somam ${this.moeda(this.previstoSelecionado())}.`,
        'A data de pagamento será hoje e o valor pago receberá o valor previsto.',
      ],
      confirmar: 'Pagar',
    });
    if (!ok) return;

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

  /**
   * Abre o diálogo de parcelamento.
   *
   * Não use prompt() aqui: o Electron não implementa window.prompt — ele lança
   * "prompt() is not supported." e o parcelamento simplesmente não acontece no aplicativo
   * desktop, embora funcione no navegador. Verificado na janela real.
   */
  parcelar(l: Lancamento): void {
    this.parcelando.set(l);
    this.parcelas.set('2');
    this.passoParcelamento.set(1);
    this.parcelasEditaveis.set([]);
    this.erro.set(null);
    this.dialogoParcelar()?.nativeElement.showModal();
  }

  fecharParcelamento(): void {
    this.dialogoParcelar()?.nativeElement.close();
    this.parcelando.set(null);
    this.passoParcelamento.set(1);
    this.parcelasEditaveis.set([]);
  }

  /**
   * Monta a tabela do segundo passo com a divisão que o servidor faria — valores em centavos
   * inteiros com o resto nas primeiras, uma parcela por mês a partir do vencimento.
   *
   * Preenchida assim, quem não quiser mexer em nada é só mandar gravar: sai igual ao
   * parcelamento automático. Provado por teste no servidor
   * (`Divisao_padrao_e_a_mesma_conta_dos_dois_caminhos`).
   */
  irParaAjusteDasParcelas(): void {
    const l = this.parcelando();
    if (!l) return;

    const n = Number(this.parcelas());
    if (!Number.isInteger(n) || n < 2) {
      this.erro.set('Informe um número inteiro de parcelas, a partir de 2.');
      return;
    }

    const centavos = Math.round(l.valorPrevisto * 100);
    const base = Math.floor(centavos / n);
    const resto = centavos - base * n;
    const vencimento = l.dataVencimento ?? hojeIso();

    // O sufixo "i/N" segue a regra do legado: quando não cabe, corta o texto e não o número —
    // saber que é "3/12" importa mais do que os últimos caracteres da descrição.
    const sufixoMaior = ` ${n}/${n}`;
    const espaco = TAMANHO_MAXIMO_DESCRICAO - sufixoMaior.length;
    const texto = l.descricao.length > espaco ? l.descricao.slice(0, espaco).trimEnd() : l.descricao;

    this.parcelasEditaveis.set(
      Array.from({ length: n }, (_, i) => ({
        numero: i + 1,
        vencimento: somarMesesNoCalendario(vencimento, i),
        valor: formatarMoeda((base + (i < resto ? 1 : 0)) / 100),
        descricao: `${texto} ${i + 1}/${n}`,
      })));

    this.erro.set(null);
    this.passoParcelamento.set(2);
  }

  voltarParaQuantidade(): void {
    this.passoParcelamento.set(1);
  }

  alterarParcela(indice: number, campo: 'vencimento' | 'valor' | 'descricao', valor: string): void {
    this.parcelasEditaveis.update((linhas) =>
      linhas.map((p, i) => (i === indice ? { ...p, [campo]: valor } : p)));
  }

  /**
   * Grava as parcelas como estão na tela.
   *
   * Vai a lista pronta, e não o número de vezes: o servidor grava exatamente aquilo. Se a
   * operadora não ajustou nada, a lista é a divisão padrão e o resultado é o mesmo de antes.
   */
  confirmarParcelamento(): void {
    const l = this.parcelando();
    if (!l) return;

    const problema = this.problemaNasParcelas();
    if (problema) { this.erro.set(problema); return; }

    const valores = this.parcelasEditaveis().map((p) => ({
      // Centavos inteiros divididos por 100 na última hora: o número que sai daqui tem no
      // máximo dois decimais, e o servidor o recebe em decimal.
      valorPrevisto: Math.round((lerMoeda(p.valor) ?? 0) * 100) / 100,
      dataVencimento: p.vencimento,
      descricao: p.descricao.trim(),
    }));

    this.fecharParcelamento();
    this.carregando.set(true);

    this.api.parcelar(l.id, valores.length, valores).subscribe({
      next: (r) => {
        this.aviso.set(
          `${r.parcelas.length} parcelas gravadas, somando ${this.moeda(r.somaDasParcelas)}` +
          (r.fechou
            ? ' — fechou o valor original.'
            : ` — ${this.moeda(Math.abs(r.somaDasParcelas - r.valorOriginal))} ` +
              `${r.somaDasParcelas > r.valorOriginal ? 'a mais' : 'a menos'} que o original.`));
        this.mostrarSomenteAsParcelas(r.parcelas);
      },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  /**
   * Põe as parcelas recém-gravadas na grade, no lugar do resultado do filtro.
   *
   * Sem isto elas somem no instante em que nascem: o filtro em tela é um período, e as
   * parcelas vencem uma por mês — parcelar em cinco dentro de um filtro de junho deixaria
   * quatro delas fora da vista.
   */
  private mostrarSomenteAsParcelas(parcelas: Lancamento[]): void {
    this.lancamentos.set(parcelas);
    this.totalPrevisto.set(
      parcelas.reduce((t, p) => t + Math.round(p.valorPrevisto * 100), 0) / 100);
    this.totalPago.set(
      parcelas.reduce((t, p) => t + Math.round((p.valorPago ?? 0) * 100), 0) / 100);
    this.selecionados.set(new Set());
    this.parcelasRecemCriadas.set(true);
    this.carregando.set(false);
  }

  /** Sai do modo "recém-criadas" e volta ao que o filtro diz. */
  voltarAoFiltro(): void {
    this.parcelasRecemCriadas.set(false);
    this.pesquisar();
  }

  async excluir(l: Lancamento): Promise<void> {
    const ok = await this.confirmacao.perguntar({
      titulo: 'Excluir o lançamento?',
      linhas: [
        l.descricao,
        `${this.moeda(l.valorPrevisto)} — vencimento ${this.data(l.dataVencimento)}`,
      ],
      alerta: 'Esta operação não tem desfazer.',
      confirmar: 'Excluir',
      perigo: true,
    });
    if (!ok) return;

    this.carregando.set(true);
    this.api.excluir(l.id).subscribe({
      next: () => { this.aviso.set('Lançamento excluído.'); this.pesquisar(); },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  /**
   * Exporta o que está na grade para uma planilha.
   *
   * O arquivo é gerado no servidor, onde os valores são decimais de verdade. No legado a
   * exportação abre o Excel por automação OLE e arredonda na hora de escrever, então a
   * planilha pode não bater com o banco.
   */
  exportar(): void {
    this.exportando.set(true);
    this.erro.set(null);

    this.api.exportar(this.filtroAtual()).subscribe({
      next: (arquivo) => {
        baixarArquivo(arquivo, `lancamentos-${hojeIso()}.xlsx`);
        this.exportando.set(false);
      },
      error: (e: Error) => {
        this.erro.set(e.message);
        this.exportando.set(false);
      },
    });
  }

  /**
   * Abre o relatório impresso do que está na grade.
   *
   * Os filtros vão pela URL para o relatório ser uma página por si só: recarregar, voltar e
   * imprimir de novo não dependem do estado desta tela.
   */
  imprimirLista(): void {
    const filtro = this.filtroAtual();
    const params: Record<string, string> = {};

    for (const [chave, valor] of Object.entries(filtro)) {
      if (valor !== undefined && valor !== null && valor !== '') {
        params[chave] = String(valor);
      }
    }

    this.router.navigate(['/relatorios/lancamentos'], { queryParams: params });
  }

  novo(): void { this.router.navigate(['/lancamentos/novo']); }
  editar(l: Lancamento): void { this.router.navigate(['/lancamentos', l.id]); }
  /** Classe da linha. A cor é informação: a operadora lê a grade por ela antes do texto. */
  classeDaLinha(l: Lancamento): string {
    if (l.situacao === 'Aguardando') return 'linha-aguardando';
    if (l.pago) return 'linha-paga';
    return '';
  }
}
