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

export interface Sessao {
  token: string;
  expiraEm: string;
  id: number;
  nome: string;
  nivel: NivelAcesso;
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
