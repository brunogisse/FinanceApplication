import {
  ChangeDetectionStrategy, Component, DestroyRef, ElementRef, computed, effect, inject,
  signal, viewChild,
} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Api } from '../../nucleo/api';
import { Lancamento, Painel as DadosDoPainel } from '../../nucleo/modelos';
import { formatarData, formatarInteiro, formatarMoeda, hojeIso, somarDias } from '../../nucleo/moeda';

/** Quantas despesas aparecem no gráfico antes de o resto virar "Outras". */
const DESPESAS_NO_GRAFICO = 8;

/**
 * Área de desenho dos gráficos.
 *
 * **O `viewBox` acompanha a largura real do cartão**, medida por `ResizeObserver`, para que
 * uma unidade do desenho valha um pixel na tela. Antes era fixo em 640, e o SVG inteiro
 * escalava: num cartão de 367px o texto de 12 unidades saía a 6px, ilegível. O gráfico
 * equivalente do Fechamento Petrotorque não tem esse problema porque desenha em canvas, onde
 * o texto é sempre do tamanho pedido.
 *
 * Este valor é só o ponto de partida, usado antes da primeira medição.
 */
const LARGURA_INICIAL = 640;

/*
 * Altura da curva: 300, e não 230.
 *
 * O número de destaque passou a ocupar uma linha própria, com a variação e o previsto
 * embaixo — o que faz o cartão crescer. Crescer sem o gráfico crescer junto só produziria
 * espaço em branco, então a plotagem recebe a folga: de 184px úteis (230 − 16 de topo − 30
 * de base) para 254px.
 *
 * O alvo é a altura da rosca ao lado, que lista oito despesas e chega a ~500px. Com estes
 * 300 as duas colunas terminam quase juntas, em vez de uma sobrar meia altura da outra.
 */
const ALTURA_LINHA = 300;

/*
 * Escada de índigo da rosca, do maior para o menor.
 *
 * Escala SEQUENCIAL, não categórica: a posição na escada diz a ordem de grandeza. Uma paleta
 * de matizes diferentes sugeriria que cada despesa "é" uma cor, e elas mudam de posição todo
 * mês — o roxo seria CHACARA em agosto e ESCRITORIO em setembro.
 *
 * São oito tons para sete despesas mais o agrupamento "Outras": o último se repete se
 * aparecerem mais.
 */
const ESCADA_DA_ROSCA = [
  '#2e1a8f', '#4f31d9', '#6d53e8', '#8b75ee',
  '#a99bf0', '#c4bbf5', '#ddd7fa', '#ebe7fd',
] as const;
const MARGEM_LINHA = { esquerda: 60, direita: 14, topo: 16, base: 30 };

/** O mesmo valor que o Fechamento Petrotorque usa no gráfico de acumulado. */
const TENSAO = 0.2;

const MESES = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];
const DIAS_DA_SEMANA = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];

interface Celula {
  dia: number;
  iso: string;
  quantidade: number;
  aPagar: number;
  total: number;
  hoje: boolean;
}

/**
 * A tela inicial.
 *
 * **Este sistema é contas a pagar**, e o painel diz isso com todas as letras: não há entrada,
 * sobra nem saldo, porque não existe receita em lugar nenhum do banco. Os quatro cards contam
 * a história que existe — o que venceu, o que está chegando, o que já saiu e o compromisso do
 * mês.
 *
 * O primeiro card é o aviso que o legado dá ao abrir o sistema, promovido a destaque: é a
 * primeira coisa que a operadora vê há três anos.
 */
@Component({
  selector: 'app-painel',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './painel.html',
  styleUrl: './painel.css',
})
export class Painel {
  private readonly api = inject(Api);
  private readonly router = inject(Router);
  private readonly rota = inject(ActivatedRoute);
  private readonly destruir = inject(DestroyRef);

  readonly moeda = formatarMoeda;
  readonly inteiro = formatarInteiro;
  readonly data = formatarData;

  readonly dados = signal<DadosDoPainel | null>(null);
  readonly carregando = signal(true);
  readonly erro = signal<string | null>(null);

  /**
   * Largura real da área de desenho, em pixels, alimentada por `ResizeObserver`.
   *
   * É ela que vira a largura do `viewBox`, para uma unidade valer um pixel e o texto do
   * gráfico sair no tamanho pedido. Ver a nota em LARGURA_INICIAL.
   */
  readonly larguraDoDesenho = signal(LARGURA_INICIAL);

  /**
   * A área de desenho do gráfico de barras.
   *
   * Vive dentro de um `@if` — não existe enquanto os dados não chegam —, por isso a medição
   * é ligada por `effect` quando o elemento aparece, e não no construtor.
   */
  private readonly areaBarras = viewChild<ElementRef<HTMLElement>>('areaBarras');

  /**
   * Mês em foco, como aaaa-mm.
   *
   * Mora na URL para o painel continuar sendo uma página por si só: recarregar volta ao mesmo
   * mês, e o endereço descreve o que está em tela.
   */
  readonly mes = signal(hojeIso().slice(0, 7));

  readonly hoje = hojeIso();

  // ---- Dia escolhido no calendário ----
  readonly diaEscolhido = signal<string | null>(null);
  readonly lancamentosDoDia = signal<Lancamento[]>([]);
  readonly carregandoDia = signal(false);

  /** O que vence de hoje até daqui a sete dias, do mais urgente para o menos. */
  readonly proximosVencimentos = signal<Lancamento[]>([]);
  readonly carregandoProximos = signal(false);

  // ---- Dica que segue o ponteiro nos gráficos ----
  readonly dica = signal<{ x: number; y: number; titulo: string; linhas: string[] } | null>(null);

  constructor() {
    const daUrl = this.rota.snapshot.queryParamMap.get('mes');
    if (daUrl && /^\d{4}-\d{2}$/.test(daUrl)) this.mes.set(daUrl);
    this.carregar();

    // A área de desenho só existe depois que os dados chegam, por isso o observador é
    // ligado quando o elemento aparece, e religado se ele for trocado.
    let observador: ResizeObserver | null = null;

    effect(() => {
      const elemento = this.areaBarras()?.nativeElement;
      observador?.disconnect();
      if (!elemento) return;

      observador = new ResizeObserver((entradas) => {
        const largura = Math.round(entradas[0].contentRect.width);
        // Zero acontece enquanto o cartão está oculto; adotar isso quebraria a escala.
        if (largura > 0) this.larguraDoDesenho.set(largura);
      });
      observador.observe(elemento);
    });

    this.destruir.onDestroy(() => observador?.disconnect());
  }

  /** Troca o mês e reflete a mudança no endereço, sem empilhar histórico. */
  private irPara(mes: string): void {
    this.mes.set(mes);
    this.router.navigate([], {
      relativeTo: this.rota,
      queryParams: { mes },
      replaceUrl: true,
    });
    this.carregar();
  }

  // ---------------- Carga ----------------

  private carregar(): void {
    this.carregando.set(true);
    this.erro.set(null);
    this.diaEscolhido.set(null);
    this.lancamentosDoDia.set([]);

    this.api.painel(this.mes()).subscribe({
      next: (d) => {
        this.dados.set(d);
        this.carregando.set(false);
      },
      error: (e: Error) => {
        this.erro.set(e.message);
        this.carregando.set(false);
      },
    });

    this.carregarProximosVencimentos();
  }

  /**
   * A lista do que vence de hoje até daqui a sete dias.
   *
   * Vem da mesma consulta da grade, não de endpoint próprio: o `GET /painel` devolve os
   * totais, não os lançamentos. Reusar a consulta significa que esta lista e a grade sempre
   * concordam — se divergissem, seria por caminhos diferentes chegarem ao mesmo número, que
   * é o defeito mais caro de achar.
   *
   * O recorte é sempre de HOJE, mesmo quando o mês em tela é outro. "O que vence nos
   * próximos dias" não muda de sentido porque a pessoa foi olhar março.
   */
  private carregarProximosVencimentos(): void {
    const inicio = hojeIso();
    const fim = somarDias(inicio, 7);

    this.carregandoProximos.set(true);
    this.api.consultar({ inicio, fim, porData: 'vencimento' }).subscribe({
      next: (r) => {
        // Só o que ainda se paga, e do mais urgente para o menos.
        const abertos = r.lancamentos
          .filter((l) => !l.pago)
          .sort((a, b) => (a.dataVencimento ?? '').localeCompare(b.dataVencimento ?? ''));
        // Doze, e não seis: a coluna da esquerda precisa alcançar a da direita, senão o
        // calendário fica com uma sobra branca embaixo ou é decepado no meio da tela. Doze
        // linhas dão cerca de 590px de tabela, que somados à curva empatam com rosca +
        // calendário. Acima disso a lista deixaria de ser "os próximos" e viraria uma
        // segunda grade — para isso existe o "Ver todos".
        this.proximosVencimentos.set(abertos.slice(0, 12));
        this.carregandoProximos.set(false);
      },
      error: () => {
        // Falhar aqui não derruba o painel: os totais já estão na tela, e esta lista é
        // detalhe. O cartão mostra o vazio, e o erro do topo continua reservado à carga
        // principal.
        this.proximosVencimentos.set([]);
        this.carregandoProximos.set(false);
      },
    });
  }

  /**
   * A quantos dias do vencimento, em palavras.
   *
   * Comparação por texto ISO, não por `Date`: `new Date('2026-08-24')` é interpretado como
   * UTC e no Brasil volta um dia. Duas datas em `aaaa-mm-dd` se comparam como string sem
   * fuso nenhum no caminho.
   */
  situacaoDoVencimento(iso: string | null): { texto: string; classe: string } {
    if (!iso) return { texto: 'Sem vencimento', classe: 'futuro' };

    const hoje = hojeIso();
    if (iso === hoje) return { texto: 'Vence hoje', classe: 'hoje' };

    const dias = Math.round(
      (Date.parse(iso + 'T00:00:00') - Date.parse(hoje + 'T00:00:00')) / 86_400_000,
    );

    if (dias < 0) {
      const atraso = Math.abs(dias);
      return { texto: atraso === 1 ? 'Vencido há 1 dia' : `Vencido há ${atraso} dias`, classe: 'vencido' };
    }
    return { texto: dias === 1 ? 'Em 1 dia' : `Em ${dias} dias`, classe: 'futuro' };
  }

  /** Leva à grade já filtrada pelos próximos sete dias. */
  verProximosSete(): void {
    this.router.navigate(['/lancamentos'], { queryParams: { atalho: 'proximos' } });
  }

  novoLancamento(): void {
    this.router.navigate(['/lancamentos/novo']);
  }

  trocarMes(passo: number): void {
    const [ano, mes] = this.mes().split('-').map(Number);
    const d = new Date(ano, mes - 1 + passo, 1);
    this.irPara(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`);
  }

  voltarParaHoje(): void {
    this.irPara(hojeIso().slice(0, 7));
  }

  // ---------------- Cabeçalho ----------------

  /**
   * "Agosto de 2026".
   *
   * A primeira letra sobe aqui, e não com `text-transform: capitalize`, porque o CSS
   * maiúscula **todas** as palavras e o resultado vira "Agosto De 2026".
   */
  readonly tituloDoMes = computed(() => {
    const [ano, mes] = this.mes().split('-').map(Number);
    const nome = MESES[mes - 1];
    return `${nome.charAt(0).toUpperCase()}${nome.slice(1)} de ${ano}`;
  });

  readonly ehMesCorrente = computed(() => this.mes() === hojeIso().slice(0, 7));

  /** Quanto o pago do mês variou em relação ao anterior. Nulo quando não há com o que comparar. */
  readonly variacaoDoPago = computed(() => {
    const d = this.dados();
    if (!d) return null;

    const anterior = d.pagoNoMesAnterior.total;
    if (anterior === 0) return null;

    const atual = d.pagoNoMes.total;
    const percentual = Math.round(((atual - anterior) / anterior) * 100);
    return { percentual, subiu: percentual > 0 };
  });

  // ---------------- Gráfico de despesas ----------------

  readonly despesas = computed(() => {
    const todas = this.dados()?.porDespesa ?? [];
    if (todas.length <= DESPESAS_NO_GRAFICO) return todas;

    const principais = todas.slice(0, DESPESAS_NO_GRAFICO);
    // Somado em centavos inteiros: dinheiro não passa por aritmética de ponto flutuante.
    const resto = todas.slice(DESPESAS_NO_GRAFICO);
    const centavos = resto.reduce((s, d) => s + Math.round(d.total * 100), 0);

    return [...principais, {
      despesa: `Outras ${resto.length} despesas`,
      quantidade: resto.reduce((s, d) => s + d.quantidade, 0),
      total: centavos / 100,
    }];
  });

  readonly totalDasDespesas = computed(() =>
    this.despesas().reduce((s, d) => s + Math.round(d.total * 100), 0) / 100);

  /**
   * Geometria da rosca: um arco por despesa, do maior para o menor.
   *
   * Substitui as barras horizontais. A barra respondia "quanto", a rosca responde
   * "que fatia" — e a pergunta desta tela é a segunda, porque o total já está escrito no
   * centro. As barras também gastavam 150px de margem só com os nomes das despesas, que
   * agora vivem na lista ao lado, onde cabe o valor E o percentual.
   *
   * O arco é um círculo com `stroke-dasharray`: um traço do tamanho da fatia e um vão do
   * tamanho do resto. O `stroke-dashoffset` acumulado empurra cada fatia para onde a
   * anterior parou. O grupo nasce girado −90° para a primeira começar às 12 horas.
   *
   * A escada de cor vai do índigo escuro ao lilás claro: aqui a cor codifica ORDEM de
   * grandeza, não identidade, então uma escala sequencial é a leitura certa — quem tem mais
   * é mais escuro. Os valores continuam escritos na lista, que é o que garante a leitura de
   * quem não distingue os tons.
   */
  readonly rosca = computed(() => {
    const itens = this.despesas();
    const total = this.totalDasDespesas();
    if (itens.length === 0 || total <= 0) return null;

    const raio = 70;
    const circunferencia = 2 * Math.PI * raio;
    let percorrido = 0;

    const fatias = itens.map((d, i) => {
      const fracao = d.total / total;
      const traco = fracao * circunferencia;
      const fatia = {
        despesa: d.despesa,
        cor: ESCADA_DA_ROSCA[Math.min(i, ESCADA_DA_ROSCA.length - 1)],
        traco: `${traco.toFixed(2)} ${circunferencia.toFixed(2)}`,
        deslocamento: -percorrido,
        valor: d.total,
        quantidade: d.quantidade,
        // Arredondar aqui, e não no template: o percentual da rosca e o da lista têm de ser
        // o mesmo número, senão a fatia parece contradizer a linha ao lado dela.
        percentual: Math.round(fracao * 100),
        /*
         * "<1%" em vez de "0%".
         *
         * PETROTORQUE saiu com R$ 98,90 em dezembro/2024 e a lista dizia "0%" — que se lê
         * como "não saiu nada", ao lado de uma linha que diz que saiu. A soma dos
         * percentuais arredondados também não fecha 100 (deu 99 naquele mês), e isso é
         * inerente ao arredondamento: forçar a bater exigiria mentir em alguma linha.
         */
        rotuloPercentual: fracao > 0 && fracao < 0.005 ? '<1' : String(Math.round(fracao * 100)),
      };
      percorrido += traco;
      return fatia;
    });

    return { raio, fatias };
  });

  // ---------------- Recorte da série ----------------

  /**
   * Quantos meses a curva mostra. O painel devolve sempre doze; aqui só se decide quantos
   * dos últimos aparecem, sem ida ao servidor.
   */
  readonly mesesNaSerie = signal<number>(12);

  readonly periodos = [
    { rotulo: '3M', meses: 3 },
    { rotulo: '6M', meses: 6 },
    { rotulo: '12M', meses: 12 },
  ] as const;

  escolherPeriodo(meses: number): void {
    this.mesesNaSerie.set(meses);
  }

  readonly inicioDoPlot = MARGEM_LINHA.esquerda;
  readonly eixoDaLinha = MARGEM_LINHA.esquerda - 8;

  // ---------------- Gráfico dos doze meses ----------------

  readonly serie = computed(() => {
    const todos = this.dados()?.serie ?? [];
    // Os ÚLTIMOS N: o gráfico termina sempre no mês em tela, e é dele que se olha para trás.
    const meses = todos.slice(-this.mesesNaSerie());
    if (meses.length === 0) return null;

    /*
     * A escala é recalculada sobre o recorte, não herdada dos doze meses.
     *
     * Se o topo continuasse sendo o do ano inteiro, escolher "3M" achataria a curva contra o
     * chão e o botão pareceria não ter feito nada — o recorte existe justamente para ampliar
     * a variação dos meses recentes.
     */
    const maior = Math.max(...meses.flatMap((m) => [m.previsto, m.pago]), 1);
    const largura = this.larguraDoDesenho() - MARGEM_LINHA.esquerda - MARGEM_LINHA.direita;
    const altura = ALTURA_LINHA - MARGEM_LINHA.topo - MARGEM_LINHA.base;
    const passo = meses.length > 1 ? largura / (meses.length - 1) : 0;

    const x = (i: number) => MARGEM_LINHA.esquerda + i * passo;
    const y = (v: number) => MARGEM_LINHA.topo + altura - (v / maior) * altura;

    const pontos = meses.map((m, i) => ({
      mes: m.mes,
      rotulo: rotuloCurtoDoMes(m.mes),
      // Doze rótulos não cabem lado a lado e se encavalam. De dois em dois cabem — contando
      // do fim, para o último mês, que é o que dá nome ao gráfico, aparecer sempre e o
      // espaçamento continuar regular. Em recortes curtos cabem todos, e pular um deixaria
      // o gráfico de três meses com dois rótulos, parecendo incompleto.
      mostrarRotulo: meses.length <= 6 || (meses.length - 1 - i) % 2 === 0,
      x: x(i),
      yPrevisto: y(m.previsto),
      yPago: y(m.pago),
      previsto: m.previsto,
      pago: m.pago,
    }));

    // Três linhas de referência bastam: mais que isso vira grade e some o dado.
    const referencias = [0, 0.5, 1].map((f) => ({
      y: y(maior * f),
      rotulo: formatarCurto(maior * f),
    }));

    const base = MARGEM_LINHA.topo + altura;

    const linhaPrevisto = suavizar(pontos.map((p) => ({ x: p.x, y: p.yPrevisto })));
    const linhaPago = suavizar(pontos.map((p) => ({ x: p.x, y: p.yPago })));

    return {
      pontos,
      referencias,
      caminhoPrevisto: linhaPrevisto,
      caminhoPago: linhaPago,
      // A área é a mesma curva, fechada no eixo. Fica por baixo da linha, em lavagem.
      areaPrevisto: fechar(linhaPrevisto, pontos[0].x, pontos[pontos.length - 1].x, base),
      areaPago: fechar(linhaPago, pontos[0].x, pontos[pontos.length - 1].x, base),
      largura: this.larguraDoDesenho(),
      altura: ALTURA_LINHA,
      base,
    };
  });

  /** Índice do mês sob o ponteiro. Os pontos só aparecem no que está sendo olhado. */
  readonly mesDestacado = signal<number | null>(null);

  // ---------------- Calendário ----------------

  readonly semanas = computed(() => {
    const [ano, mes] = this.mes().split('-').map(Number);
    const porDia = new Map((this.dados()?.dias ?? []).map((d) => [d.data, d]));

    const primeiro = new Date(ano, mes - 1, 1);
    const diasNoMes = new Date(ano, mes, 0).getDate();

    const celulas: (Celula | null)[] = [];
    for (let i = 0; i < primeiro.getDay(); i++) celulas.push(null);

    for (let dia = 1; dia <= diasNoMes; dia++) {
      const iso = `${ano}-${String(mes).padStart(2, '0')}-${String(dia).padStart(2, '0')}`;
      const d = porDia.get(iso);
      celulas.push({
        dia,
        iso,
        quantidade: d?.quantidade ?? 0,
        aPagar: d?.aPagar ?? 0,
        total: d?.total ?? 0,
        hoje: iso === this.hoje,
      });
    }

    while (celulas.length % 7 !== 0) celulas.push(null);

    const semanas: (Celula | null)[][] = [];
    for (let i = 0; i < celulas.length; i += 7) semanas.push(celulas.slice(i, i + 7));
    return semanas;
  });

  readonly diasDaSemana = DIAS_DA_SEMANA;

  /** Os dias do mês que têm vencimento, do primeiro ao último. */
  readonly diasComVencimento = computed(() => this.dados()?.dias ?? []);

  escolherDia(c: Celula | null): void {
    if (!c || c.quantidade === 0) return;

    if (this.diaEscolhido() === c.iso) {
      this.diaEscolhido.set(null);
      this.lancamentosDoDia.set([]);
      return;
    }

    this.diaEscolhido.set(c.iso);
    this.carregandoDia.set(true);

    this.api.consultar({ inicio: c.iso, fim: c.iso, porData: 'vencimento' }).subscribe({
      next: (r) => {
        this.lancamentosDoDia.set(r.lancamentos);
        this.carregandoDia.set(false);
      },
      error: () => {
        this.lancamentosDoDia.set([]);
        this.carregandoDia.set(false);
      },
    });
  }

  // ---------------- Dica dos gráficos ----------------

  mostrarDica(evento: MouseEvent, titulo: string, linhas: string[]): void {
    const alvo = (evento.currentTarget as SVGElement).closest('.grafico') as HTMLElement | null;
    if (!alvo) return;

    const caixa = alvo.getBoundingClientRect();
    this.dica.set({
      x: evento.clientX - caixa.left,
      y: evento.clientY - caixa.top,
      titulo,
      linhas,
    });
  }

  esconderDica(): void {
    this.dica.set(null);
  }

  // ---------------- Navegação ----------------

  /** Abre a grade já filtrada pelo que o card mostra. */
  verVencidos(): void {
    this.router.navigate(['/lancamentos'], {
      queryParams: { atalho: 'vencidos' },
    });
  }

  verDia(iso: string): void {
    this.router.navigate(['/lancamentos'], {
      queryParams: { atalho: 'dia', dia: iso },
    });
  }

  verMes(): void {
    const [ano, mes] = this.mes().split('-').map(Number);
    const ultimo = new Date(ano, mes, 0).getDate();
    this.router.navigate(['/lancamentos'], {
      queryParams: {
        atalho: 'periodo',
        inicio: `${this.mes()}-01`,
        fim: `${this.mes()}-${String(ultimo).padStart(2, '0')}`,
      },
    });
  }

  verDespesa(nome: string): void {
    const [ano, mes] = this.mes().split('-').map(Number);
    const ultimo = new Date(ano, mes, 0).getDate();
    this.router.navigate(['/lancamentos'], {
      queryParams: {
        atalho: 'despesa',
        despesa: nome,
        inicio: `${this.mes()}-01`,
        fim: `${this.mes()}-${String(ultimo).padStart(2, '0')}`,
      },
    });
  }
}

/**
 * Curva suave passando pelos pontos, do jeito que o Chart.js faz com `tension`.
 *
 * É a fórmula do `splineCurve` dele: os pontos de controle de cada vértice apontam na
 * direção da reta entre o vizinho anterior e o seguinte, com o comprimento proporcional à
 * distância de cada lado. Isso dá a onda sem os laços que uma Bézier ingênua produz quando
 * dois pontos ficam muito perto.
 */
function suavizar(p: Array<{ x: number; y: number }>, tensao = TENSAO): string {
  if (p.length < 2) return '';

  const controles = p.map((atual, i) => {
    const antes = p[i - 1] ?? atual;
    const depois = p[i + 1] ?? atual;

    const d01 = Math.hypot(atual.x - antes.x, atual.y - antes.y);
    const d12 = Math.hypot(depois.x - atual.x, depois.y - atual.y);
    const soma = d01 + d12;

    // Pontos coincidentes: sem direção para apontar, o controle fica no próprio vértice.
    const fa = soma === 0 ? 0 : (tensao * d01) / soma;
    const fb = soma === 0 ? 0 : (tensao * d12) / soma;

    return {
      antes: { x: atual.x - fa * (depois.x - antes.x), y: atual.y - fa * (depois.y - antes.y) },
      depois: { x: atual.x + fb * (depois.x - antes.x), y: atual.y + fb * (depois.y - antes.y) },
    };
  });

  let caminho = `M ${p[0].x} ${p[0].y}`;
  for (let i = 1; i < p.length; i++) {
    const c1 = controles[i - 1].depois;
    const c2 = controles[i].antes;
    caminho += ` C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${p[i].x} ${p[i].y}`;
  }
  return caminho;
}

/** Fecha a curva no eixo, virando área. */
function fechar(caminho: string, xInicial: number, xFinal: number, base: number): string {
  return `${caminho} L ${xFinal} ${base} L ${xInicial} ${base} Z`;
}

/** "2026-08" vira "ago/26" — cabe no eixo sem virar diagonal. */
function rotuloCurtoDoMes(iso: string): string {
  const [ano, mes] = iso.split('-').map(Number);
  return `${MESES[mes - 1].slice(0, 3)}/${String(ano).slice(2)}`;
}

/** Valores do eixo em forma curta: 1,2 mi / 340 mil / 850. */
function formatarCurto(valor: number): string {
  if (valor >= 1_000_000) return `${(valor / 1_000_000).toFixed(1).replace('.', ',')} mi`;
  if (valor >= 1_000) return `${Math.round(valor / 1_000)} mil`;
  return String(Math.round(valor));
}

