import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Api } from '../../nucleo/api';
import { Confirmacao } from '../../nucleo/confirmacao';
import { NivelAcesso, Setor, Usuario } from '../../nucleo/modelos';
import { formatarInteiro } from '../../nucleo/moeda';

/** Os três níveis da coluna LOGIN.NIVEL, com o nome que a pessoa entende. */
const NIVEIS: ReadonlyArray<{ valor: number; nome: string; explica: string }> = [
  { valor: 1, nome: 'Consulta', explica: 'só consulta e relatórios' },
  { valor: 2, nome: 'Operação', explica: 'lança, altera e paga' },
  { valor: 3, nome: 'Administração', explica: 'tudo, mais usuários e importação' },
];

/**
 * Cadastro de usuários.
 *
 * Só o nível 3 chega aqui — a opção nem aparece no menu para os outros, e o servidor recusa
 * de todo jeito.
 *
 * **A tela equivalente do legado não valida nada:** é um `TDBNavigator` sobre
 * `select * from LOGIN`, com a senha visível num campo comum. As recusas que aparecem aqui
 * vêm todas do servidor, e cada uma fecha um buraco que aquela tela deixava aberto.
 */
@Component({
  selector: 'app-usuarios',
  standalone: true,
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './usuarios.html',
  styleUrl: './usuarios.css',
})
export class Usuarios {
  private readonly api = inject(Api);
  private readonly confirmacao = inject(Confirmacao);

  readonly inteiro = formatarInteiro;
  readonly niveis = NIVEIS;

  readonly euSou = this.api.usuarioId;

  readonly lista = signal<Usuario[]>([]);
  readonly setores = signal<Setor[]>([]);
  readonly carregando = signal(false);
  readonly erro = signal<string | null>(null);
  readonly aviso = signal<string | null>(null);

  /** `0` significa "criando"; um id, "editando aquele". `null`, nenhum dos dois. */
  readonly editandoId = signal<number | null>(null);

  readonly nome = signal('');
  readonly nivel = signal(2);
  readonly setor = signal(0);
  readonly senha = signal('');

  readonly criando = computed(() => this.editandoId() === 0);

  /** Quantos ainda dependem da senha em texto plano do legado. */
  readonly semHash = computed(() => this.lista().filter((u) => u.aindaSemHash).length);

  /** Quem está sem setor não consegue entrar — é o recado mais urgente desta tela. */
  readonly semSetor = computed(() => this.lista().filter((u) => u.setor === null).length);

  constructor() {
    this.recarregar();
    this.api.setores().subscribe({
      next: (s) => this.setores.set(s),
      error: (e: Error) => this.erro.set(e.message),
    });
  }

  recarregar(): void {
    this.carregando.set(true);
    this.api.usuarios().subscribe({
      next: (u) => { this.lista.set(u); this.carregando.set(false); },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  nomeDoSetor(setor: number | null): string {
    if (setor === null) return 'sem setor';
    return this.setores().find((s) => s.id === setor)?.descricao ?? `setor ${setor}`;
  }

  nomeDoNivel(nivel: NivelAcesso): string {
    switch (nivel) {
      case 'Administracao': return 'Administração';
      case 'Operacao': return 'Operação';
      default: return 'Consulta';
    }
  }

  private numeroDoNivel(nivel: NivelAcesso): number {
    switch (nivel) {
      case 'Administracao': return 3;
      case 'Operacao': return 2;
      default: return 1;
    }
  }

  /**
   * O usuário 1 é o administrador de fato do legado, e ninguém mexe no próprio nível: as duas
   * travas existem no servidor, e aparecem aqui para o campo já vir desabilitado em vez de a
   * pessoa descobrir depois de digitar.
   */
  nivelEstaTravado(id: number): boolean {
    return id === 1 || id === this.euSou();
  }

  podeExcluir(u: Usuario): boolean {
    return u.id !== 1 && u.id !== this.euSou();
  }

  novo(): void {
    this.editandoId.set(0);
    this.nome.set('');
    this.nivel.set(2);
    // Nasce no setor de quem está cadastrando, que é o caso comum. Trocar é um clique.
    this.setor.set(this.api.setorId());
    this.senha.set('');
    this.limparRecados();
  }

  editar(u: Usuario): void {
    this.editandoId.set(u.id);
    this.nome.set(u.nome);
    this.nivel.set(this.numeroDoNivel(u.nivel));
    this.setor.set(u.setor ?? this.api.setorId());
    this.senha.set('');
    this.limparRecados();
  }

  cancelar(): void {
    this.editandoId.set(null);
    this.limparRecados();
  }

  salvar(): void {
    const id = this.editandoId();
    if (id === null) return;

    this.limparRecados();
    this.carregando.set(true);

    // Criar leva senha; alterar não — a senha tem caminho próprio, senão corrigir um nome
    // reescreveria a senha por descuido.
    const operacao = id === 0
      ? this.api.criarUsuario(this.nome(), Number(this.nivel()), this.senha(), Number(this.setor()))
      : this.api.alterarUsuario(id, this.nome(), Number(this.nivel()), Number(this.setor()));

    operacao.subscribe({
      next: (u) => {
        // "criado/criada" concordaria com um gênero que o nome do usuário não informa.
        this.aviso.set(id === 0
          ? `Usuário ${u.nome} criado. Já pode entrar, nos dois sistemas.`
          : `Usuário ${u.nome} alterado.`);
        this.editandoId.set(null);
        this.carregando.set(false);
        this.recarregar();
      },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  async excluir(u: Usuario): Promise<void> {
    const ok = await this.confirmacao.perguntar({
      titulo: `Excluir ${u.nome}?`,
      linhas: ['A pessoa perde o acesso aos dois sistemas, o novo e o antigo.'],
      alerta: 'Quem já lançou não pode ser removido — o banco recusa, para não perder a autoria.',
      confirmar: 'Excluir',
      perigo: true,
    });
    if (!ok) return;

    this.limparRecados();
    this.carregando.set(true);

    this.api.excluirUsuario(u.id).subscribe({
      next: () => {
        this.aviso.set(`Usuário ${u.nome} excluído.`);
        this.carregando.set(false);
        this.recarregar();
      },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  /** Trocar a senha de outra pessoa. A própria se troca pelo rodapé do menu. */
  async trocarSenha(u: Usuario): Promise<void> {
    const senha = await this.confirmacao.pedirTexto({
      titulo: `Nova senha de ${u.nome}`,
      linhas: [
        'De 4 a 20 caracteres. O limite é o tamanho da coluna do sistema antigo.',
        'A senha vale para os dois sistemas a partir de agora.',
      ],
      rotulo: 'Nova senha',
      confirmar: 'Trocar senha',
      sigiloso: true,
      tamanhoMaximo: 20,
    });
    if (!senha) return;

    this.limparRecados();
    this.carregando.set(true);

    this.api.trocarSenha(u.id, senha).subscribe({
      next: () => {
        this.aviso.set(`A senha de ${u.nome} foi trocada.`);
        this.carregando.set(false);
        this.recarregar();
      },
      error: (e: Error) => { this.erro.set(e.message); this.carregando.set(false); },
    });
  }

  aoTeclar(evento: KeyboardEvent): void {
    if (evento.key === 'Enter') this.salvar();
    if (evento.key === 'Escape') this.cancelar();
  }

  private limparRecados(): void {
    this.erro.set(null);
    this.aviso.set(null);
  }
}
