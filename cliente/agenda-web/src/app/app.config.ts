import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter, withHashLocation } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';

import { routes } from './app.routes';
import { tokenInterceptor } from './nucleo/token-interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    /*
     * Rotas por hash (`#/painel`).
     *
     * Empacotado, o aplicativo carrega de `file://`, e a estratégia normal do Angular
     * chamaria `history.pushState` para um caminho que não existe no disco. O sintoma é o
     * pior possível: navega bem no `ng serve` e quebra só no aplicativo instalado.
     *
     * Vale **também em desenvolvimento**, de propósito. Ligar só no empacotado criaria dois
     * comportamentos, e o defeito voltaria a aparecer apenas na máquina de quem usa.
     */
    provideRouter(routes, withHashLocation()),
    provideHttpClient(withInterceptors([tokenInterceptor])),
  ],
};
