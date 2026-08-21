import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Api } from '../../nucleo/api';
import { Lancamento, Painel as DadosDoPainel } from '../../nucleo/modelos';
import { formatarData, formatarInteiro, formatarMoeda, hojeIso } from '../../nucleo/moeda';

/** Quantas despesas aparecem no gráfico antes de o resto virar "Outras". */
const DESPESAS_NO_GRAFICO = 8;

/**
 * Área de desenho dos gráficos, em coordenadas próprias — o CSS escala para a largura do
 * cartão.
 *
 * As margens da esquerda são diferentes de propósito: o gráfico de barras precisa de espaço
 * para o nome da despesa, e o de linhas só para "24 mil".
 */
const LARGURA = 640;
const ALTURA_LINHA = 230;
const MARGEM_BARRAS = { esquerda: 168, direita: 14 };
const MARGEM_LINHA = { esquerda: 60, direita: 14, topo: 16, base: 30 };

/** Além disto o nome da despesa é cortado com reticências; o inteiro fica na dica. */
const LETRAS_NO_ROTULO = 16;

/** O mesmo valor que o Fechamento Petrotorque usa no gráfico de acumulado. */
const TENSAO = 0.2;

const MESES = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];
const DIAS_DA_SEMANA = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];

/** Uma barra do gráfico de despesas, já com a geometria pronta. */
interface Barra {
  caminho: string;
  rotulo: string;
  curto: string;
  valor: string;
  percentual: string;
  quantidade: number;
  y: number;
}

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

  readonly moeda = formatarMoeda;
  readonly inteiro = formatarInteiro;
  readonly data = formatarData;

  readonly dados = signal<DadosDoPainel | null>(null);
  readonly carregando = signal(true);
  readonly erro = signal<string | null>(null);

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

  // ---- Dica que segue o ponteiro nos gráficos ----
  readonly dica = signal<{ x: number; y: number; titulo: string; linhas: string[] } | null>(null);

  constructor() {
    const daUrl = this.rota.snapshot.queryParamMap.get('mes');
    if (daUrl && /^\d{4}-\d{2}$/.test(daUrl)) this.mes.set(daUrl);
    this.carregar();
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

  /** Geometria das barras. Cada uma é um caminho com só as pontas do dado arredondadas. */
  readonly barras = computed<{ altura: number; marcas: Barra[] }>(() => {
    const itens = this.despesas();
    if (itens.length === 0) return { altura: 60, marcas: [] };

    const maior = Math.max(...itens.map((d) => d.total), 0.01);
    const total = this.totalDasDespesas();
    const passo = 34;
    const espessura = 16;
    const largura = LARGURA - MARGEM_BARRAS.esquerda - MARGEM_BARRAS.direita;

    const marcas = itens.map((d, i) => {
      const y = i * passo + 8;
      const comprimento = Math.max((d.total / maior) * largura, 2);
      return {
        caminho: barraHorizontal(MARGEM_BARRAS.esquerda, y, comprimento, espessura, 4),
        rotulo: d.despesa,
        curto: d.despesa.length > LETRAS_NO_ROTULO
          ? `${d.despesa.slice(0, LETRAS_NO_ROTULO - 1)}…`
          : d.despesa,
        valor: formatarMoeda(d.total),
        percentual: total > 0 ? `${Math.round((d.total / total) * 100)}%` : '',
        quantidade: d.quantidade,
        y,
      };
    });

    return { altura: itens.length * passo + 12, marcas };
  });

  /** Onde os rótulos do eixo do gráfico de barras terminam. */
  readonly eixoDasBarras = MARGEM_BARRAS.esquerda - 8;
  readonly inicioDoPlot = MARGEM_LINHA.esquerda;
  readonly eixoDaLinha = MARGEM_LINHA.esquerda - 8;

  // ---------------- Gráfico dos doze meses ----------------

  readonly serie = computed(() => {
    const meses = this.dados()?.serie ?? [];
    if (meses.length === 0) return null;

    const maior = Math.max(...meses.flatMap((m) => [m.previsto, m.pago]), 1);
    const largura = LARGURA - MARGEM_LINHA.esquerda - MARGEM_LINHA.direita;
    const altura = ALTURA_LINHA - MARGEM_LINHA.topo - MARGEM_LINHA.base;
    const passo = meses.length > 1 ? largura / (meses.length - 1) : 0;

    const x = (i: number) => MARGEM_LINHA.esquerda + i * passo;
    const y = (v: number) => MARGEM_LINHA.topo + altura - (v / maior) * altura;

    const pontos = meses.map((m, i) => ({
      mes: m.mes,
      rotulo: rotuloCurtoDoMes(m.mes),
      // Doze rótulos não cabem lado a lado e se encavalam. De dois em dois cabem — contando
      // do fim, para o último mês, que é o que dá nome ao gráfico, aparecer sempre e o
      // espaçamento continuar regular.
      mostrarRotulo: (meses.length - 1 - i) % 2 === 0,
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
      largura: LARGURA,
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

/** Barra horizontal com só as pontas do dado arredondadas; a base fica reta no eixo. */
function barraHorizontal(x: number, y: number, comprimento: number, altura: number, r: number) {
  const raio = Math.min(r, comprimento / 2, altura / 2);
  const fim = x + comprimento;
  return `M ${x} ${y} H ${fim - raio} Q ${fim} ${y} ${fim} ${y + raio} ` +
         `V ${y + altura - raio} Q ${fim} ${y + altura} ${fim - raio} ${y + altura} ` +
         `H ${x} Z`;
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
