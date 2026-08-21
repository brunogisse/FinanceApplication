import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { Observable, from, throwError } from 'rxjs';
import { catchError, switchMap, tap } from 'rxjs/operators';
import {
  Conta, Despesa, EntradaLancamento, FiltroConsulta, FormaPagamento, Lancamento,
  Painel, PreviaImportacao, ResultadoConsulta, ResultadoImportacao, ResultadoPagamentoEmLote,
  ResultadoParcelamento, Sessao, Subdespesa, TotalPorSubdespesa,
} from './modelos';

/** Endereço da API. Numa instalação real, isto vem da tela de configuração. */
const ENDERECO_PADRAO = 'http://localhost:5199';

const CHAVE_SESSAO = 'agenda.sessao';

@Injectable({ providedIn: 'root' })
export class Api {
  private readonly http = inject(HttpClient);

  /** Estado da sessão. Signal, porque tudo que a tela observa precisa ser signal. */
  private readonly _sessao = signal<Sessao | null>(lerSessaoGuardada());

  readonly sessao = this._sessao.asReadonly();
  readonly autenticado = computed(() => this._sessao() !== null);
  readonly usuario = computed(() => this._sessao()?.nome ?? '');
  readonly podeLancar = computed(() => this._sessao()?.podeLancar ?? false);
  readonly podeImportar = computed(() => this._sessao()?.podeImportarPlanilha ?? false);

  /** Nome do nível como a pessoa entende, não o número da coluna NIVEL. */
  readonly nivel = computed(() => {
    switch (this._sessao()?.nivel) {
      case 'Administracao': return 'Administração';
      case 'Operacao': return 'Operação';
      case 'Consulta': return 'Consulta';
      default: return '';
    }
  });

  readonly endereco = signal(localStorage.getItem('agenda.endereco') ?? ENDERECO_PADRAO);

  definirEndereco(url: string): void {
    const limpo = url.trim().replace(/\/+$/, '');
    localStorage.setItem('agenda.endereco', limpo);
    this.endereco.set(limpo);
  }

  // ---------------- Sessão ----------------

  entrar(usuario: string, senha: string): Observable<Sessao> {
    return this.http
      .post<Sessao>(`${this.endereco()}/sessao`, { usuario, senha })
      .pipe(
        tap((s) => {
          this._sessao.set(s);
          localStorage.setItem(CHAVE_SESSAO, JSON.stringify(s));
        }),
        catchError(traduzirErro),
      );
  }

  sair(): void {
    this._sessao.set(null);
    localStorage.removeItem(CHAVE_SESSAO);
  }

  trocarSenha(usuarioId: number, senhaNova: string): Observable<unknown> {
    return this.http
      .post(`${this.endereco()}/sessao/trocar-senha`, { usuarioId, senhaNova })
      .pipe(catchError(traduzirErro));
  }

  // ---------------- Painel ----------------

  /** Os números da tela inicial, para o mês informado como `aaaa-mm`. */
  painel(mes?: string): Observable<Painel> {
    const params = mes ? new HttpParams().set('mes', mes) : undefined;
    return this.http
      .get<Painel>(`${this.endereco()}/painel`, { params })
      .pipe(catchError(traduzirErro));
  }

  // ---------------- Lançamentos ----------------

  consultar(filtro: FiltroConsulta): Observable<ResultadoConsulta> {
    return this.http
      .get<ResultadoConsulta>(`${this.endereco()}/lancamentos`, { params: paraParametros(filtro) })
      .pipe(catchError(traduzirErro));
  }

  /**
   * A mesma consulta, entregue como planilha.
   *
   * Os filtros são montados pela mesma função da consulta em tela, de propósito: o que sai na
   * planilha tem de ser o que está na grade.
   */
  exportar(filtro: FiltroConsulta): Observable<Blob> {
    return this.http
      .get(`${this.endereco()}/lancamentos/exportar`, {
        params: paraParametros(filtro),
        responseType: 'blob',
      })
      .pipe(catchError(traduzirErroDeArquivo));
  }

  vencimentos(ate?: string): Observable<ResultadoConsulta> {
    const params = ate ? new HttpParams().set('ate', ate) : undefined;
    return this.http
      .get<ResultadoConsulta>(`${this.endereco()}/lancamentos/vencimentos`, { params })
      .pipe(catchError(traduzirErro));
  }

  lancamento(id: number): Observable<Lancamento> {
    return this.http
      .get<Lancamento>(`${this.endereco()}/lancamentos/${id}`)
      .pipe(catchError(traduzirErro));
  }

  lancar(dados: EntradaLancamento): Observable<Lancamento> {
    return this.http
      .post<Lancamento>(`${this.endereco()}/lancamentos`, dados)
      .pipe(catchError(traduzirErro));
  }

  alterar(id: number, dados: EntradaLancamento): Observable<Lancamento> {
    return this.http
      .put<Lancamento>(`${this.endereco()}/lancamentos/${id}`, dados)
      .pipe(catchError(traduzirErro));
  }

  excluir(id: number): Observable<unknown> {
    return this.http
      .delete(`${this.endereco()}/lancamentos/${id}`)
      .pipe(catchError(traduzirErro));
  }

  definirSituacao(id: number, situacao: string): Observable<Lancamento> {
    return this.http
      .put<Lancamento>(`${this.endereco()}/lancamentos/${id}/situacao`, { situacao })
      .pipe(catchError(traduzirErro));
  }

  parcelar(id: number, parcelas: number): Observable<ResultadoParcelamento> {
    return this.http
      .post<ResultadoParcelamento>(`${this.endereco()}/lancamentos/${id}/parcelar`, { parcelas })
      .pipe(catchError(traduzirErro));
  }

  pagarEmLote(ids: number[]): Observable<ResultadoPagamentoEmLote> {
    return this.http
      .post<ResultadoPagamentoEmLote>(`${this.endereco()}/lancamentos/pagar-em-lote`, { ids })
      .pipe(catchError(traduzirErro));
  }

  // ---------------- Importação de planilha ----------------

  /** Lê a planilha e devolve o que sairia dela, sem gravar nada. */
  previaImportacao(planilha: File): Observable<PreviaImportacao> {
    const corpo = new FormData();
    corpo.append('planilha', planilha);
    return this.http
      .post<PreviaImportacao>(`${this.endereco()}/lancamentos/importar/previa`, corpo)
      .pipe(catchError(traduzirErro));
  }

  importarPlanilha(
    planilha: File, subdespesaId: number, contaId: number, formaPagamentoId: number,
    descricoes?: Record<number, string>,
  ): Observable<ResultadoImportacao> {
    const corpo = new FormData();
    corpo.append('planilha', planilha);

    // Descrições digitadas na prévia, para as linhas que a planilha trouxe sem histórico.
    // Só o que tem texto viaja: o servidor recusa linha que continua em branco.
    const preenchidas = Object.entries(descricoes ?? {})
      .filter(([, texto]) => texto.trim() !== '');
    if (preenchidas.length > 0)
      corpo.append('descricoes', JSON.stringify(Object.fromEntries(preenchidas)));

    const params = new HttpParams()
      .set('subdespesaId', subdespesaId)
      .set('contaId', contaId)
      .set('formaPagamentoId', formaPagamentoId);

    return this.http
      .post<ResultadoImportacao>(`${this.endereco()}/lancamentos/importar`, corpo, { params })
      .pipe(catchError(traduzirErro));
  }

  // ---------------- Cadastros ----------------

  contas(): Observable<Conta[]> {
    return this.http.get<Conta[]>(`${this.endereco()}/contas`).pipe(catchError(traduzirErro));
  }

  formasPagamento(): Observable<FormaPagamento[]> {
    return this.http
      .get<FormaPagamento[]>(`${this.endereco()}/formas-pagamento`)
      .pipe(catchError(traduzirErro));
  }

  despesas(): Observable<Despesa[]> {
    return this.http.get<Despesa[]>(`${this.endereco()}/despesas`).pipe(catchError(traduzirErro));
  }

  subdespesas(despesaId?: number): Observable<Subdespesa[]> {
    const params = despesaId ? new HttpParams().set('despesaId', despesaId) : undefined;
    return this.http
      .get<Subdespesa[]>(`${this.endereco()}/subdespesas`, { params })
      .pipe(catchError(traduzirErro));
  }

  consolidadoPorDespesa(
    despesa: string, inicio: string, fim: string, pagos: boolean,
  ): Observable<TotalPorSubdespesa[]> {
    const params = new HttpParams()
      .set('despesa', despesa).set('inicio', inicio).set('fim', fim).set('pagos', pagos);
    return this.http
      .get<TotalPorSubdespesa[]>(`${this.endereco()}/relatorios/por-despesa`, { params })
      .pipe(catchError(traduzirErro));
  }

  // ---------------- Cadastros: escrita ----------------
  //
  // As quatro famílias falam o mesmo formato de endpoint, então três funções privadas dão
  // conta de todas. A subdespesa é a única diferente: carrega no corpo a despesa a que
  // pertence, porque ela nunca existe solta.

  criarConta(descricao: string): Observable<Conta> {
    return this.criar<Conta>('contas', { descricao });
  }

  alterarConta(id: number, descricao: string): Observable<Conta> {
    return this.alterarCadastro<Conta>('contas', id, { descricao });
  }

  excluirConta(id: number): Observable<unknown> {
    return this.excluirCadastro('contas', id);
  }

  criarFormaPagamento(descricao: string): Observable<FormaPagamento> {
    return this.criar<FormaPagamento>('formas-pagamento', { descricao });
  }

  alterarFormaPagamento(id: number, descricao: string): Observable<FormaPagamento> {
    return this.alterarCadastro<FormaPagamento>('formas-pagamento', id, { descricao });
  }

  excluirFormaPagamento(id: number): Observable<unknown> {
    return this.excluirCadastro('formas-pagamento', id);
  }

  criarDespesa(descricao: string): Observable<Despesa> {
    return this.criar<Despesa>('despesas', { descricao });
  }

  alterarDespesa(id: number, descricao: string): Observable<Despesa> {
    return this.alterarCadastro<Despesa>('despesas', id, { descricao });
  }

  excluirDespesa(id: number): Observable<unknown> {
    return this.excluirCadastro('despesas', id);
  }

  criarSubdespesa(descricao: string, despesaId: number): Observable<Subdespesa> {
    return this.criar<Subdespesa>('subdespesas', { descricao, despesaId });
  }

  alterarSubdespesa(id: number, descricao: string, despesaId: number): Observable<Subdespesa> {
    return this.alterarCadastro<Subdespesa>('subdespesas', id, { descricao, despesaId });
  }

  excluirSubdespesa(id: number): Observable<unknown> {
    return this.excluirCadastro('subdespesas', id);
  }

  private criar<T>(recurso: string, corpo: unknown): Observable<T> {
    return this.http
      .post<T>(`${this.endereco()}/${recurso}`, corpo)
      .pipe(catchError(traduzirErro));
  }

  private alterarCadastro<T>(recurso: string, id: number, corpo: unknown): Observable<T> {
    return this.http
      .put<T>(`${this.endereco()}/${recurso}/${id}`, corpo)
      .pipe(catchError(traduzirErro));
  }

  private excluirCadastro(recurso: string, id: number): Observable<unknown> {
    return this.http
      .delete(`${this.endereco()}/${recurso}/${id}`)
      .pipe(catchError(traduzirErro));
  }
}

/** Filtros viram parâmetros de URL, ignorando o que está vazio. */
function paraParametros(filtro: FiltroConsulta): HttpParams {
  let params = new HttpParams();
  for (const [chave, valor] of Object.entries(filtro)) {
    if (valor !== undefined && valor !== null && valor !== '') {
      params = params.set(chave, String(valor));
    }
  }
  return params;
}

/**
 * Erro numa resposta que pedia arquivo.
 *
 * Quando a resposta é `blob`, o corpo do erro **também** vem como Blob — inclusive o JSON com
 * a explicação do servidor. Sem ler o texto, a razão real se perde e sobra uma mensagem
 * genérica, justamente no caso em que a pessoa precisa saber o que houve.
 */
function traduzirErroDeArquivo(erro: HttpErrorResponse) {
  if (!(erro.error instanceof Blob)) return traduzirErro(erro);

  return from(erro.error.text()).pipe(
    switchMap((texto) => {
      let mensagem: string | undefined;
      try {
        mensagem = (JSON.parse(texto) as { erro?: string }).erro;
      } catch {
        // Corpo que não era JSON: cai na mensagem genérica abaixo.
      }
      return throwError(() => new Error(
        mensagem ?? `Não foi possível gerar a planilha (${erro.status}).`));
    }),
  );
}

function lerSessaoGuardada(): Sessao | null {
  try {
    const guardado = localStorage.getItem(CHAVE_SESSAO);
    if (!guardado) return null;
    const sessao = JSON.parse(guardado) as Sessao;
    // Token vencido não serve para nada: melhor pedir login do que falhar na primeira chamada.
    return new Date(sessao.expiraEm) > new Date() ? sessao : null;
  } catch {
    return null;
  }
}

/**
 * Repassa a mensagem que o servidor mandou, sem reescrever.
 *
 * O motivo real da recusa é o que permite ao operador resolver sozinho. Só quando não há
 * mensagem alguma é que entra um texto genérico.
 */
function traduzirErro(erro: HttpErrorResponse) {
  const doServidor = erro.error?.erro as string | undefined;

  if (doServidor) return throwError(() => new Error(doServidor));

  if (erro.status === 0) {
    return throwError(() => new Error(
      'Não foi possível falar com o servidor. Verifique se ele está no ar e se o endereço está correto.',
    ));
  }
  if (erro.status === 401) {
    return throwError(() => new Error('Sessão expirada. Entre novamente.'));
  }
  if (erro.status === 403) {
    return throwError(() => new Error('Seu nível de acesso não permite esta operação.'));
  }

  return throwError(() => new Error(`Falha na comunicação com o servidor (${erro.status}).`));
}
