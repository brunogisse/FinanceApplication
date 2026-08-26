import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { Api } from '../nucleo/api';
import { Confirmacao } from '../nucleo/confirmacao';

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
  private readonly confirmacao = inject(Confirmacao);

  readonly usuario = this.api.usuario;
  readonly nivel = this.api.nivel;
  readonly podeImportar = this.api.podeImportar;
  readonly podeCadastrarUsuarios = this.api.podeCadastrarUsuarios;

  /** Recado da troca de senha. Some sozinho — é confirmação, não erro para resolver. */
  readonly recado = signal<string | null>(null);

  /**
   * Menu recolhido, guardado entre sessões.
   *
   * Quem opera passa o dia na grade de lançamentos e quer a largura de volta; quem entra de
   * vez em quando quer os rótulos. A escolha é de cada máquina, então mora no
   * `localStorage` — e a leitura vai dentro de `try`, porque em janela anônima o próprio
   * acesso ao objeto pode lançar.
   */
  readonly recolhido = signal<boolean>(Casca.lerRecolhido());

  private static lerRecolhido(): boolean {
    try {
      return localStorage.getItem('menu-recolhido') === '1';
    } catch {
      return false;
    }
  }

  alternarMenu(): void {
    const novo = !this.recolhido();
    this.recolhido.set(novo);
    try {
      localStorage.setItem('menu-recolhido', novo ? '1' : '0');
    } catch {
      /* Sem armazenamento a escolha vale só para esta sessão, o que é aceitável. */
    }
  }

  /**
   * Trocar a própria senha.
   *
   * Mora no rodapé do menu, junto do nome, porque é a única ação que **todo** nível pode
   * fazer sobre si mesmo — inclusive quem só consulta e nunca vê a tela de usuários.
   */
  async trocarMinhaSenha(): Promise<void> {
    const senha = await this.confirmacao.pedirTexto({
      titulo: 'Trocar a sua senha',
      linhas: [
        'De 4 a 20 caracteres. O limite é o tamanho do campo no sistema antigo.',
        'A senha nova vale para os dois sistemas a partir de agora.',
      ],
      rotulo: 'Nova senha',
      confirmar: 'Trocar senha',
      sigiloso: true,
      tamanhoMaximo: 20,
    });
    if (!senha) return;

    this.api.trocarSenha(this.api.usuarioId(), senha).subscribe({
      next: () => this.mostrarRecado('Senha trocada.'),
      error: (e: Error) => this.mostrarRecado(e.message),
    });
  }

  private mostrarRecado(texto: string): void {
    this.recado.set(texto);
    setTimeout(() => this.recado.set(null), 5000);
  }

  sair(): void {
    this.api.sair();
    this.router.navigate(['/login']);
  }
}
