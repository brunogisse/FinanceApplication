import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { Api } from '../nucleo/api';

/**
 * A casca do sistema: menu à esquerda, conteúdo à direita.
 *
 * As opções que antes moravam em botões no topo de cada tela vieram para cá. Isso tira a
 * navegação de dentro do conteúdo — cada página passa a cuidar só do que ela faz — e dá ao
 * sistema um lugar fixo para crescer.
 *
 * As telas de relatório ficam **fora** desta casca, de propósito: são páginas de impressão, e
 * uma folha não tem menu.
 */
@Component({
  selector: 'app-casca',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './casca.html',
  styleUrl: './casca.css',
})
export class Casca {
  private readonly api = inject(Api);
  private readonly router = inject(Router);

  readonly usuario = this.api.usuario;
  readonly nivel = this.api.nivel;
  readonly podeImportar = this.api.podeImportar;

  sair(): void {
    this.api.sair();
    this.router.navigate(['/login']);
  }
}
