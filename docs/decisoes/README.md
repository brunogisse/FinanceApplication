# Registros de decisão arquitetural (ADR)

Cada decisão relevante do projeto vira um arquivo numerado neste diretório. A ideia é simples:
daqui a um ano, quem abrir o código precisa entender **por que** algo é do jeito que é, sem
depender da memória de quem estava na sala.

## Índice

| # | Decisão | Situação |
|---|---|---|
| [0001](0001-adotar-adrs.md) | Adotar ADRs para registrar decisões | Aceita |
| [0002](0002-banco-legado-e-sagrado.md) | O banco legado é sagrado | Aceita |
| [0003](0003-portugues-do-brasil.md) | Português do Brasil em todo o projeto | Aceita |
| [0004](0004-nao-migrar-estoque.md) | Não migrar o módulo de estoque | Aceita |
| [0005](0005-estrategia-de-banco.md) | Manter Firebird durante a convivência | Aceita |
| [0006](0006-dinheiro-em-decimal.md) | Valores monetários em decimal | Aceita |
| [0007](0007-backend-dotnet.md) | Backend em .NET com C# | Aceita |
| [0008](0008-frontend-angular-electron.md) | Frontend em Angular com Electron | Aceita |
| [0009](0009-acesso-a-dados-dapper-e-charset.md) | Acesso a dados com Dapper e leitura do charset | Aceita |
| [0010](0010-autenticacao-durante-a-convivencia.md) | Autenticação durante a convivência | Aceita |

A proposta que amarra as decisões da Fase 4 está em
[arquitetura-alvo.md](../arquitetura-alvo.md).

## Decisões pendentes

Adiadas de propósito, cada uma aguardando um fato que ainda não temos:

- **Atualizar Firebird 2.5 para a série 5** (Etapa 2 de [0005](0005-estrategia-de-banco.md)).
  Momento a definir; não bloqueia a migração da aplicação.
- **Migrar para PostgreSQL** (Etapa 3 de [0005](0005-estrategia-de-banco.md)). Só faz sentido
  avaliar depois de o legado ser desligado. O plano de portabilidade já está registrado lá.
- **Corrigir o tipo das colunas monetárias no banco.** Depende de recompilar o legado ou de
  desligá-lo, porque alterar o tipo quebra os campos persistentes do Delphi.
- **Ordem de migração dos módulos** e critérios de pronto — é o conteúdo da Fase 5.

## Formato

Arquivos nomeados `NNNN-titulo-em-kebab-case.md`, numerados em sequência, com esta estrutura:

```markdown
# NNNN — Título

- **Situação:** Proposta | Aceita | Substituída por [NNNN] | Revogada
- **Data:** AAAA-MM-DD

## Contexto
O que motivou a decisão. Fatos, não opiniões.

## Decisão
O que foi decidido, em voz ativa.

## Consequências
O que isso torna mais fácil, o que torna mais difícil, e o que passa a ser obrigatório.
```

Um ADR não é editado depois de aceito. Mudou de ideia? Escreva um novo que substitua o
anterior, e marque o antigo como substituído.
