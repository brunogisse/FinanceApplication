import { Component, inject, signal, ChangeDetectionStrategy, ElementRef, viewChild, afterNextRender } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Api } from '../../nucleo/api';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './login.html',
  styleUrl: './login.css',
})
export class Login {
  private readonly api = inject(Api);
  private readonly router = inject(Router);

  readonly usuario = signal('');
  readonly senha = signal('');
  readonly erro = signal<string | null>(null);
  readonly entrando = signal(false);
  readonly mostrarConfiguracao = signal(false);
  readonly endereco = signal(this.api.endereco());

  private readonly campoUsuario = viewChild<ElementRef<HTMLInputElement>>('campoUsuario');

  constructor() {
    afterNextRender(() => this.campoUsuario()?.nativeElement.focus());
  }

  entrar(): void {
    if (this.entrando()) return;

    const usuario = this.usuario().trim();
    if (!usuario) { this.erro.set('Informe o usuário.'); return; }
    if (!this.senha()) { this.erro.set('Informe a senha.'); return; }

    this.erro.set(null);
    this.entrando.set(true);

    this.api.entrar(usuario, this.senha()).subscribe({
      next: () => {
        this.entrando.set(false);
        this.router.navigate(['/lancamentos']);
      },
      error: (e: Error) => {
        this.entrando.set(false);
        // Diferente do legado, que encerra o programa quando a senha está errada.
        this.erro.set(e.message);
        this.senha.set('');
      },
    });
  }

  salvarEndereco(): void {
    this.api.definirEndereco(this.endereco());
    this.mostrarConfiguracao.set(false);
    this.erro.set(null);
  }
}
