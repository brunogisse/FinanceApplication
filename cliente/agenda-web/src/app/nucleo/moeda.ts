/**
 * Formatação brasileira de dinheiro e datas.
 *
 * O legado usa vírgula decimal em todo lugar, inclusive na entrada de dados, e a operadora
 * digita assim há três anos. Mudar isso custaria produtividade sem ganho nenhum.
 */

const FORMATO_MOEDA = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

const FORMATO_NUMERO = new Intl.NumberFormat('pt-BR', {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

/** R$ 1.234,56 */
export function formatarMoeda(valor: number | null | undefined): string {
  if (valor === null || valor === undefined) return '';
  return FORMATO_MOEDA.format(valor);
}

/** 1.234,56 — sem o símbolo, para colunas de grade */
export function formatarNumero(valor: number | null | undefined): string {
  if (valor === null || valor === undefined) return '';
  return FORMATO_NUMERO.format(valor);
}

const FORMATO_INTEIRO = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 0 });

/** 1.492 — contagens grandes com separador de milhar, para serem lidas de relance. */
export function formatarInteiro(valor: number | null | undefined): string {
  if (valor === null || valor === undefined) return '';
  return FORMATO_INTEIRO.format(valor);
}

/**
 * Converte "1.234,56" digitado pela operadora em 1234.56.
 *
 * Aceita o que ela costuma digitar: com ou sem separador de milhar, com ou sem "R$".
 * Devolve null quando não dá para entender, em vez de zero — zero silencioso em campo de
 * dinheiro é um erro caro.
 */
export function lerMoeda(texto: string | null | undefined): number | null {
  if (!texto) return null;

  const limpo = texto.replace(/[^\d,.-]/g, '').trim();
  if (!limpo) return null;

  // Se tem vírgula, ela é o separador decimal e o ponto é milhar.
  const normalizado = limpo.includes(',')
    ? limpo.replace(/\./g, '').replace(',', '.')
    : limpo;

  const valor = Number(normalizado);
  return Number.isFinite(valor) ? valor : null;
}

/**
 * Converte para centavos inteiros.
 *
 * Só use se for realmente inevitável somar dinheiro no cliente. O caminho certo é pedir o
 * total à API, que calcula com decimal de verdade.
 */
export function paraCentavos(valor: number): number {
  return Math.round(valor * 100);
}

/** dd/mm/aaaa a partir de "aaaa-mm-dd". Sem passar por Date, para não haver fuso no caminho. */
export function formatarData(iso: string | null | undefined): string {
  if (!iso) return '';
  const [ano, mes, dia] = iso.split('-');
  return dia && mes && ano ? `${dia}/${mes}/${ano}` : iso;
}

/**
 * Data de hoje como "aaaa-mm-dd", no fuso local.
 *
 * NUNCA use toISOString() para isso: ele converte para UTC e, no Brasil, 01/07 vira 30/06.
 */
export function hojeIso(): string {
  const agora = new Date();
  const mes = String(agora.getMonth() + 1).padStart(2, '0');
  const dia = String(agora.getDate()).padStart(2, '0');
  return `${agora.getFullYear()}-${mes}-${dia}`;
}

/** Desloca uma data "aaaa-mm-dd" em meses, sem sair do calendário local. */
export function somarMeses(iso: string, meses: number): string {
  const [ano, mes, dia] = iso.split('-').map(Number);
  const data = new Date(ano, mes - 1 + meses, dia);
  const m = String(data.getMonth() + 1).padStart(2, '0');
  const d = String(data.getDate()).padStart(2, '0');
  return `${data.getFullYear()}-${m}-${d}`;
}
