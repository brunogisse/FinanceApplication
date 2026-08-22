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
  {
    path: 'login',
    loadComponent: () => import('./paginas/login/login').then((m) => m.Login),
  },

  // Os relatórios ficam fora da casca de propósito: são páginas de impressão, e uma folha
  // não tem menu lateral.
  {
    path: 'relatorios/lancamentos',
    canActivate: [exigirSessao],
    loadComponent: () =>
      import('./paginas/relatorio-lancamentos/relatorio-lancamentos')
        .then((m) => m.RelatorioLancamentos),
  },
  {
    path: 'relatorios/consolidado',
    canActivate: [exigirSessao],
    loadComponent: () =>
      import('./paginas/relatorio-consolidado/relatorio-consolidado')
        .then((m) => m.RelatorioConsolidado),
  },
  {
    path: 'relatorios/subdespesa',
    canActivate: [exigirSessao],
    loadComponent: () =>
      import('./paginas/relatorio-subdespesa/relatorio-subdespesa')
        .then((m) => m.RelatorioSubdespesa),
  },

  // Tudo o mais vive dentro da casca, com o menu à esquerda.
  {
    path: '',
    canActivate: [exigirSessao],
    loadComponent: () => import('./layout/casca').then((m) => m.Casca),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'painel' },
      {
        path: 'painel',
        loadComponent: () => import('./paginas/painel/painel').then((m) => m.Painel),
      },
      {
        path: 'lancamentos',
        loadComponent: () => import('./paginas/lancamentos/lancamentos').then((m) => m.Lancamentos),
      },
      {
        path: 'lancamentos/novo',
        loadComponent: () =>
          import('./paginas/lancamento-form/lancamento-form').then((m) => m.LancamentoForm),
      },
      {
        path: 'lancamentos/:id',
        loadComponent: () =>
          import('./paginas/lancamento-form/lancamento-form').then((m) => m.LancamentoForm),
      },
      {
        path: 'relatorios/por-despesa',
        loadComponent: () =>
          import('./paginas/relatorio-despesa/relatorio-despesa').then((m) => m.RelatorioDespesa),
      },
      {
        path: 'cadastros',
        loadComponent: () => import('./paginas/cadastros/cadastros').then((m) => m.Cadastros),
      },
      {
        path: 'usuarios',
        loadComponent: () => import('./paginas/usuarios/usuarios').then((m) => m.Usuarios),
      },
      {
        path: 'importar',
        loadComponent: () => import('./paginas/importar/importar').then((m) => m.Importar),
      },
    ],
  },

  { path: '**', redirectTo: 'painel' },
];
