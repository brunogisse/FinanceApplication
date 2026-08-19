import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import {
  Conta, Despesa, EntradaLancamento, FiltroConsulta, FormaPagamento, Lancamento,
  ResultadoConsulta, ResultadoPagamentoEmLote, ResultadoParcelamento, Sessao,
  Subdespesa, TotalPorSubdespesa,
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

  // ---------------- Lançamentos ----------------

  consultar(filtro: FiltroConsulta): Observable<ResultadoConsulta> {
    let params = new HttpParams();
    for (const [chave, valor] of Object.entries(filtro)) {
      if (valor !== undefined && valor !== null && valor !== '') {
        params = params.set(chave, String(valor));
      }
    }
    return this.http
      .get<ResultadoConsulta>(`${this.endereco()}/lancamentos`, { params })
      .pipe(catchError(traduzirErro));
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
