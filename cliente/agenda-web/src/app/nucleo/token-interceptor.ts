import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Api } from './api';

/** Anexa o token de acesso a toda chamada, menos a própria autenticação. */
export const tokenInterceptor: HttpInterceptorFn = (requisicao, seguir) => {
  const api = inject(Api);
  const sessao = api.sessao();

  if (!sessao || requisicao.url.endsWith('/sessao')) return seguir(requisicao);

  return seguir(requisicao.clone({
    setHeaders: { Authorization: `Bearer ${sessao.token}` },
  }));
};
