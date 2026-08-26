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
 * Quantos dígitos a máscara aceita antes de parar de crescer.
 *
 * 13 dígitos são R$ 99.999.999.999,99. O maior lançamento da base tem seis dígitos; o limite
 * existe só para o campo não virar um número que ninguém consegue ler nem conferir.
 */
const MAXIMO_DE_DIGITOS = 13;

/**
 * Máscara de dinheiro, dos centavos para a esquerda.
 *
 * Recebe o que está no campo, joga fora tudo que não é dígito e remonta: os dois últimos são
 * os centavos, o resto ganha ponto de milhar. Digitar `123456` vira `R$ 1.234,56`.
 *
 * **É manipulação de texto, não aritmética.** Nada aqui divide por 100 nem passa por
 * `Number` — dinheiro não nasce de ponto flutuante, e este é justamente o caminho por onde
 * ele entra no sistema.
 *
 * Campo só com zeros volta VAZIO, de propósito: é o que permite apagar tudo com a tecla de
 * retrocesso. Sem isso, `R$ 0,01` menos um dígito daria `R$ 0,00` e o campo nunca esvaziaria
 * — e vazio tem significado nos três lugares onde a máscara é usada: "sem filtro" na faixa
 * de valor e "igual ao previsto" no valor pago.
 */
export function mascararMoeda(texto: string | null | undefined): string {
  if (!texto) return '';

  const digitos = texto.replace(/\D/g, '').slice(0, MAXIMO_DE_DIGITOS);
  if (digitos === '' || /^0*$/.test(digitos)) return '';

  const comCentavos = digitos.padStart(3, '0');
  const centavos = comCentavos.slice(-2);
  const inteiro = comCentavos.slice(0, -2).replace(/^0+/, '') || '0';

  // Ponto de milhar da direita para a esquerda, sem regex de lookbehind: o Electron aqui
  // suporta, mas a conta em pedaços de três é mais fácil de conferir de cabeça.
  const grupos: string[] = [];
  for (let fim = inteiro.length; fim > 0; fim -= 3) {
    grupos.unshift(inteiro.slice(Math.max(0, fim - 3), fim));
  }

  return `R$ ${grupos.join('.')},${centavos}`;
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

/**
 * Desloca uma data em meses **grudando no fim do mês** quando o dia não existe no destino.
 *
 * É a conta que o servidor faz — `DateOnly.AddMonths` — e precisa bater, porque os
 * vencimentos das parcelas são gerados aqui e enviados prontos. 31/01 mais um mês dá
 * **28/02**, e não 03/03.
 *
 * `somarMeses`, logo abaixo, é a outra conta: `new Date(2026, 1, 31)` transborda para março.
 * Serve para o período do filtro, onde alguns dias a mais não mudam nada. Aqui mudaria: o
 * vencimento gravado seria o do mês seguinte ao pretendido.
 */
export function somarMesesNoCalendario(iso: string, meses: number): string {
  const [ano, mes, dia] = iso.split('-').map(Number);

  const alvo = new Date(ano, mes - 1 + meses, 1);
  const ultimoDia = new Date(alvo.getFullYear(), alvo.getMonth() + 1, 0).getDate();

  const m = String(alvo.getMonth() + 1).padStart(2, '0');
  const d = String(Math.min(dia, ultimoDia)).padStart(2, '0');
  return `${alvo.getFullYear()}-${m}-${d}`;
}

/**
 * Desloca uma data "aaaa-mm-dd" em dias, sem sair do calendário local.
 *
 * Existe num lugar só de propósito: o alerta "vence nos próximos 7 dias" do painel e o
 * atalho que abre a grade com esse mesmo recorte precisam calcular a MESMA data-fim. Se cada
 * um fizesse a própria conta, um erro de um dia apareceria como "o painel diz 14 e a grade
 * mostra 15", e ninguém saberia qual dos dois está certo.
 *
 * `new Date(iso + 'T00:00:00')` é hora local; sem o horário, o navegador lê como UTC e no
 * Brasil a data volta um dia.
 */
export function somarDias(iso: string, dias: number): string {
  const data = new Date(`${iso}T00:00:00`);
  data.setDate(data.getDate() + dias);
  const m = String(data.getMonth() + 1).padStart(2, '0');
  const d = String(data.getDate()).padStart(2, '0');
  return `${data.getFullYear()}-${m}-${d}`;
}

/** Desloca uma data "aaaa-mm-dd" em meses, sem sair do calendário local. */
export function somarMeses(iso: string, meses: number): string {
  const [ano, mes, dia] = iso.split('-').map(Number);
  const data = new Date(ano, mes - 1 + meses, dia);
  const m = String(data.getMonth() + 1).padStart(2, '0');
  const d = String(data.getDate()).padStart(2, '0');
  return `${data.getFullYear()}-${m}-${d}`;
}
