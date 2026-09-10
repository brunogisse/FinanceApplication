/**
 * Modelos que espelham os contratos da API.
 *
 * O vocabulário é o da tela do legado, não o do banco: despesa e subdespesa, nunca
 * categoria e subcategoria. A operadora conhece o sistema por esses nomes.
 */

/**
 * Valor monetário como vem da API.
 *
 * ATENÇÃO: no JSON, um decimal vira `number`, que em JavaScript é ponto flutuante binário —
 * o mesmo tipo de problema que motivou toda esta migração. Por isso vale uma regra firme:
 *
 *   **o cliente não faz aritmética com dinheiro.**
 *
 * Todos os totais vêm calculados da API, que usa decimal de verdade. Aqui os valores só são
 * exibidos. Se algum dia for inevitável somar no cliente, converta para centavos inteiros
 * antes — ver `paraCentavos` em moeda.ts.
 */
export type Valor = number;

export type SituacaoLancamento = 'Nenhuma' | 'Aguardando' | 'Liberada';

export interface Lancamento {
  id: number;
  descricao: string;
  despesa: string;
  subdespesa: string;
  conta: string;
  formaPagamento: string;
  valorPrevisto: Valor;
  valorPago: Valor;
  pago: boolean;
  /** Data de calendário no formato aaaa-mm-dd. Nunca um instante com fuso. */
  dataVencimento: string | null;
  dataPagamento: string | null;
  dataCadastro: string | null;
  notaFiscal: number | null;
  cheque: number | null;
  chequeCompensado: boolean;
  situacao: SituacaoLancamento;
  observacao: string | null;
  usuarioId: number;
}

export interface ResultadoConsulta {
  lancamentos: Lancamento[];
  quantidade: number;
  totalPrevisto: Valor;
  totalPago: Valor;
}

export interface Conta { id: number; descricao: string; }
export interface FormaPagamento { id: number; descricao: string; }
export interface Despesa { id: number; descricao: string; }

export interface Subdespesa {
  id: number;
  descricao: string;
  despesaId: number;
  despesa: string | null;
}

export type NivelAcesso = 'Consulta' | 'Operacao' | 'Administracao';

/** Setor — o recorte do que cada pessoa enxerga. Tabela SETOR, criada na unificação. */
export interface Setor {
  id: number;
  descricao: string;
}

/** Usuário do sistema — tabela LOGIN do legado. A senha nunca vem do servidor. */
export interface Usuario {
  id: number;
  nome: string;
  nivel: NivelAcesso;
  /**
   * O setor desta pessoa. **Nulo é cadastro feito pela tela do sistema antigo**, que não conhece
   * a coluna — e quem está sem setor não consegue entrar até alguém informar qual é.
   */
  setor: number | null;
  /** Quem ainda não entrou pela API e portanto depende da senha em texto plano do legado. */
  aindaSemHash: boolean;
}

export interface Sessao {
  token: string;
  expiraEm: string;
  id: number;
  nome: string;
  nivel: NivelAcesso;
  /** O setor de quem entrou. Todo número da tela é recortado por ele, no servidor. */
  setor: number;
  podeLancar: boolean;
  podeImportarPlanilha: boolean;
  podeCadastrarUsuarios: boolean;
  senhaMigradaAgora: boolean;
}

/** Filtros da consulta, equivalentes às duas abas de pesquisa do legado. */
export interface FiltroConsulta {
  inicio?: string;
  fim?: string;
  /** Qual coluna o período filtra. Regra fácil de perder — ver docs/dominio.md. */
  porData?: 'vencimento' | 'pagamento' | 'cadastro';
  pagamento?: 'todos' | 'pagos' | 'naopagos';
  descricao?: string;
  despesa?: string;
  subdespesa?: string;
  conta?: string;
  notaFiscal?: number;
  cheque?: number;
  chequeCompensado?: boolean;
  situacao?: 'aguardando' | 'liberada' | 'nenhuma';
  valorMinimo?: number;
  valorMaximo?: number;
  faixaSobreValorPago?: boolean;
}

/** Dados para criar ou alterar um lançamento. */
export interface EntradaLancamento {
  descricao: string;
  subdespesaId: number;
  contaId: number;
  formaPagamentoId: number;
  valorPrevisto: number;
  dataVencimento: string;
  pago?: boolean;
  dataPagamento?: string | null;
  valorPago?: number | null;
  notaFiscal?: number | null;
  cheque?: number | null;
  chequeCompensado?: boolean;
  situacao?: string;
  observacao?: string | null;
}

/**
 * Uma parcela como a operadora decidiu que ela fica, antes de gravar.
 *
 * O valor viaja em reais porque é o que a API recebe, mas quem edita trabalha em centavos
 * inteiros até o envio — ver `parcelasEditaveis` na tela de lançamentos.
 */
export interface ParcelaAjustada {
  valorPrevisto: Valor;
  dataVencimento: string;
  descricao: string;
}

export interface ResultadoParcelamento {
  parcelas: Lancamento[];
  idOriginalExcluido: number;
  valorOriginal: Valor;
  somaDasParcelas: Valor;
  /** A soma das parcelas fechou o total. O legado não fecha. */
  fechou: boolean;
}

export interface ResultadoPagamentoEmLote {
  pagos: number[];
  jaEstavamPagos: number[];
  semPermissao: number[];
  naoEncontrados: number[];
  quantidade: number;
  totalPago: Valor;
}

export interface TotalPorSubdespesa {
  subdespesaId: number;
  subdespesa: string;
  despesa: string;
  quantidade: number;
  totalPrevisto: Valor;
  totalPago: Valor;
}

/** Uma linha da planilha, como o servidor a entendeu. */
export interface LinhaDaPlanilha {
  /** Linha física no arquivo, para a pessoa achar o problema na planilha dela. */
  numeroDaLinha: number;
  data: string;
  descricao: string;
  valor: Valor;
}

/**
 * O que a planilha produziria, sem nada gravado ainda.
 *
 * A importação grava um lote inteiro de lançamentos já quitados e não tem desfazer.
 * Conferir antes é a única defesa.
 */
export interface PreviaImportacao {
  quantidade: number;
  total: Valor;
  linhas: LinhaDaPlanilha[];

  /** Linhas de crédito que ficaram de fora: dinheiro entrando não é despesa. */
  creditosIgnorados: number;

  /** Linhas que herdaram a data da anterior — extrato não repete a data no mesmo dia. */
  datasHerdadas: number;

  /** Onde os dados começaram, depois do título e do cabeçalho. */
  primeiraLinhaComDados: number;
}

export interface ResultadoImportacao {
  quantidade: number;
  total: Valor;
  lancamentos: Lancamento[];
}

/** Uma contagem com o dinheiro que ela representa. */
export interface Montante {
  quantidade: number;
  total: Valor;
}

export interface TotalPorDespesa {
  despesa: string;
  quantidade: number;
  total: Valor;
}

export interface MesDaSerie {
  /** aaaa-mm */
  mes: string;
  previsto: Valor;
  pago: Valor;
}

export interface DiaDoMes {
  /** aaaa-mm-dd */
  data: string;
  quantidade: number;
  total: Valor;
  /** Quantos ainda não foram pagos. É o que pinta o dia no calendário. */
  aPagar: number;
}

/**
 * Os números da tela inicial.
 *
 * Não há entrada, sobra nem saldo: este sistema é contas a pagar e não existe receita em
 * lugar nenhum do banco. O que existe é compromisso.
 */
export interface Painel {
  mes: string;
  vencido: Montante;
  venceEmSeteDias: Montante;
  pagoNoMes: Montante;
  pagoNoMesAnterior: Montante;
  previstoNoMes: Montante;
  porDespesa: TotalPorDespesa[];
  serie: MesDaSerie[];
  dias: DiaDoMes[];
}
