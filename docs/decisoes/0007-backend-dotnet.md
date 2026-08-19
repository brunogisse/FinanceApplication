# 0007 — Backend em .NET com C#

- **Situação:** Aceita
- **Data:** 2026-08-19

## Contexto

A nova stack precisa de uma API. A recomendação foi pedida como técnica e honesta, com a
observação de que há familiaridade com C# — mas explicitamente sem que isso fosse tratado como
resposta pronta.

O que o sistema exige de uma stack de backend, em ordem de importância:

1. **Aritmética decimal confiável.** O defeito que motivou a migração é de tipo numérico.
2. **Tipagem estática forte.** Pelo mesmo motivo: o erro que custou caro foi um tipo errado que
   ninguém percebeu por três anos.
3. **Acesso maduro ao Firebird**, porque a Etapa 1 roda sobre ele
   ([0005](0005-estrategia-de-banco.md)).
4. **Manutenível por uma pessoa**, por anos, sem equipe de plantão.

Este último critério pesa mais aqui do que pesaria em outro projeto. O sistema é mantido por
uma pessoa em transição de Delphi para C#/Angular. Uma arquitetura que exija equipe para
evoluir é a arquitetura errada para este caso — não por conforto, mas porque um sistema que o
mantenedor não consegue evoluir volta a apodrecer, e é exatamente disso que estamos saindo.

## Alternativas consideradas

**Node.js com TypeScript.** Ecossistema enorme, mas o JavaScript não tem decimal nativo:
dinheiro exige `decimal.js` ou inteiros de centavos, e a disciplina precisa ser mantida
manualmente em cada operação. Num sistema cujo defeito central é justamente aritmética
monetária, adotar uma linguagem que torna esse erro fácil é escolher errado de propósito.

**Java com Spring.** Robusto, `BigDecimal` sólido, mas verboso e com curva íngreme sem base
prévia. Ganha pouco sobre .NET e custa mais para quem vai manter.

**Python com FastAPI.** Rápido de escrever e `Decimal` na biblioteca padrão, mas a tipagem é
opcional e verificada por ferramenta externa. Para um sistema financeiro de vida longa mantido
por uma pessoa, tipagem opcional é risco.

**Go.** Excelente para serviços, mas sem decimal nativo e distante de tudo que já se conhece
aqui.

**PHP com Laravel.** Produtivo, mas a aritmética decimal depende de extensão e o modelo mental
é o mais distante do Delphi entre os avaliados.

## Decisão

O backend é escrito em **C# sobre .NET**, com ASP.NET Core expondo uma API HTTP com JSON.

Os motivos, na ordem em que pesam:

**`decimal` é nativo e é o tipo certo.** 128 bits, base 10, feito para valores monetários. Não
é biblioteca, não é convenção, não é disciplina de equipe — é o tipo da linguagem. Dado que o
defeito central do legado é aritmética monetária, isso sozinho já ordenaria a escolha.

**Tipagem estática forte, com `DateOnly` para data de calendário.** Vencimento e pagamento são
datas, não instantes; `DateTime` convertido para UTC faz `01/07` virar `30/06` no Brasil, e o
tipo certo elimina a classe inteira de erro.

**A transição a partir do Delphi é a mais curta que existe.** Não é coincidência: Anders
Hejlsberg foi o arquiteto do Turbo Pascal e do Delphi antes de projetar o C#. Propriedades,
tipos-valor, `using` como equivalente do `try..finally`, e o mesmo modelo de tipagem forte com
compilação. Conceitos do legado têm tradução direta: o DataModule vira injeção de dependência,
o `TFDQuery` vira repositório, os eventos de formulário viram serviços de aplicação.

**O ferramental cobre os dois bancos do plano.** `FirebirdSql.Data.FirebirdClient` para a
Etapa 1 e Npgsql para uma eventual Etapa 3, sem trocar de linguagem no caminho.

### Acesso a dados: decidir por spike, não por preferência

Há duas opções e a escolha depende de um fato que ainda não foi verificado: **quão bem o
provider Entity Framework Core para Firebird lida com um banco 2.5** — ODS 11.2, dialect 3,
sem constraint alguma e com três colunas `FLOAT` mapeando para `decimal`.

- **Dapper com SQL explícito.** Depende apenas do provider ADO.NET, que é maduro. As consultas
  do legado já estão catalogadas em [fluxos.md](../fluxos.md) e podem ser reaproveitadas quase
  como estão. Controle total sobre o SQL emitido, que num banco sem índice de data importa.
- **EF Core com o provider Firebird.** Mais produtivo para CRUD, migrações versionadas, e
  recursos que o legado precisaria muito — em especial `HasQueryFilter`, que resolveria baixa
  lógica com uma linha por entidade em vez de uma lembrança por consulta.

**A decisão fica condicionada a um spike** que conecte no banco real de trabalho, leia e
escreva um lançamento com valor monetário, e confirme o comportamento das colunas `FLOAT` e das
datas. O resultado vira um ADR próprio. Até lá, a recomendação de partida é **Dapper**, por
depender de menos coisa que ainda não foi verificada.

Independente da escolha, o SQL da nova stack usa **sempre parâmetros**, nunca concatenação —
o legado monta consulta por concatenação em toda parte.

## Consequências

**Mais fácil:** aritmética monetária correta por construção; refatorar com o compilador
apoiando; contratar ajuda pontual, se necessário, num ecossistema grande.

**Mais difícil:** o suporte a Firebird em .NET é de comunidade, não de fornecedor. Se o
provider tiver limitação séria com a versão 2.5, o plano de acesso a dados muda — e é por isso
que existe o spike antes do compromisso.

**Passa a ser obrigatório:** rodar o spike de acesso a dados antes de escrever o primeiro
endpoint de escrita.

Uma verificação que já foi feita e vale registrar: a API **pode** inserir em
`REGISTRO_DE_GASTOS` sem informar o identificador, porque `GEN_REGISTRO_DE_GASTOS_ID` está
correto e sincronizado, e a trigger o atribui. O mesmo vale para as demais tabelas do módulo
financeiro. O defeito dos generators compartilhados atinge apenas `ITEM_NF`, `SAIDA_PRODUTO` e
`TIPO_PRODUTO` — ver [triggers-e-procedures.md](../triggers-e-procedures.md).
