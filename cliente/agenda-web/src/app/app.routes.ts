import { Routes } from '@angular/router';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { Api } from './nucleo/api';

/** Sem sessão, volta para o login. A regra de verdade está no servidor; isto é conveniência. */
const exigirSessao = () => {
  const api = inject(Api);
  const router = inject(Router);
  return api.autenticado() ? true : router.createUrlTree(['/login']);
};

export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'lancamentos' },
  {
    path: 'login',
    loadComponent: () => import('./paginas/login/login').then((m) => m.Login),
  },
  {
    path: 'lancamentos',
    canActivate: [exigirSessao],
    loadComponent: () => import('./paginas/lancamentos/lancamentos').then((m) => m.Lancamentos),
  },
  {
    path: 'relatorios/por-despesa',
    canActivate: [exigirSessao],
    loadComponent: () =>
      import('./paginas/relatorio-despesa/relatorio-despesa').then((m) => m.RelatorioDespesa),
  },
  {
    path: 'lancamentos/novo',
    canActivate: [exigirSessao],
    loadComponent: () =>
      import('./paginas/lancamento-form/lancamento-form').then((m) => m.LancamentoForm),
  },
  {
    path: 'lancamentos/:id',
    canActivate: [exigirSessao],
    loadComponent: () =>
      import('./paginas/lancamento-form/lancamento-form').then((m) => m.LancamentoForm),
  },
  {
    path: 'cadastros',
    canActivate: [exigirSessao],
    loadComponent: () => import('./paginas/cadastros/cadastros').then((m) => m.Cadastros),
  },
  { path: '**', redirectTo: 'lancamentos' },
];
