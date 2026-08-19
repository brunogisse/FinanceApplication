# 0011 — Autorização verificada no servidor, com token

- **Situação:** Aceita
- **Data:** 2026-08-19

## Contexto

No legado, toda a autorização é feita **escondendo controles da interface**: o nível 1 perde os
menus de Cadastros e Lançamentos, o nível 3 ganha a importação por planilha, e só o usuário 1
enxerga o backup. Não existe verificação alguma no banco.

Quem alcançasse o banco fazia o que quisesse — e a senha do Firebird é a padrão de instalação,
com `SYSDBA` / `masterkey` em texto plano num `config.ini` versionado.

A Etapa 3 introduziu os primeiros endpoints de escrita, e eles subiram sem exigir autenticação.
Isso ficou declarado como pendência no Swagger e no commit. Avançar para os lançamentos com
essa lacuna aberta significaria acumular dívida no ponto mais sensível do sistema.

## Decisão

A API exige **token de acesso** em tudo que toca dados, e verifica o nível **no servidor**.

**Emissão.** `POST /sessao` valida as credenciais pela estratégia de convivência do
[ADR 0010](0010-autenticacao-durante-a-convivencia.md) e devolve um JWT válido por 12 horas,
com o identificador, o nome e o nível do usuário.

**Políticas**, espelhando os níveis do legado:

| Política | Exige | Cobre |
|---|---|---|
| autenticado | qualquer nível | consultar lançamentos e cadastros |
| `PodeOperar` | nível 2 ou 3 | criar, alterar e excluir cadastros |
| `PodeAdministrar` | nível 3 | listar usuários, trocar senha de terceiros |

Continuam abertos apenas `POST /sessao`, `/saude` e a documentação.

**Troca de senha:** cada um troca a própria; o nível 3 troca a de qualquer um.

**Recusa uniforme:** usuário inexistente e senha errada devolvem exatamente a mesma resposta,
para não revelar quais usuários existem.

### A chave de assinatura não vive no repositório

A chave vem da configuração — variável de ambiente `Jwt__Chave` ou user-secrets — e **a API se
recusa a subir sem ela**, com uma mensagem que explica como configurar e já sugere uma chave
aleatória pronta para uso. Também recusa chave com menos de 32 bytes, que tornaria o HMAC o
elo fraco.

Falhar fechada é deliberado. O caminho oposto — um valor padrão no `appsettings.json` — produz
exatamente o problema que o legado tem hoje: um segredo que acompanha qualquer cópia do
repositório e que todo mundo com acesso ao código conhece.

## Verificação executada

Com a API no ar, contra uma cópia:

```
sem token:   GET /contas 401 · POST /contas 401 · GET /lancamentos 401 · GET /usuarios 401
abertos:     GET /saude 200 · GET /swagger 200
nível 1:     GET /contas 200 · POST /contas 403 · DELETE /contas/20 403 · GET /usuarios 403
nível 3:     GET /usuarios 200 · POST /contas 201
token adulterado: 401
```

E confirmado que o cadastro recusado ao nível 1 **não foi criado** — a recusa não é só de
resposta.

Os 19 testes de `AutorizacaoApiTeste` sobem a API de verdade contra uma cópia descartável e
fixam esse comportamento.

## Consequências

**Mais fácil:** o cliente Electron não precisa reimplementar regra de permissão; ele esconde
menus por conveniência, mas quem decide é o servidor.

**Mais difícil:** rodar a API exige configurar a chave uma vez por máquina. É atrito
proposital — ver as instruções no [CLAUDE.md](../../CLAUDE.md#configuração-da-api).

**Passa a ser obrigatório:** todo endpoint novo nasce protegido. Deixar algo aberto é decisão
explícita, com `AllowAnonymous` visível no código.

**Fica registrado como limitação:** o token é validado por assinatura e prazo, sem lista de
revogação. Trocar a senha de alguém não invalida os tokens que já emitiu, que continuam
valendo até expirar. Para o uso atual — rede local, poucos usuários — é aceitável; se um dia
deixar de ser, a revogação vira ADR próprio.
