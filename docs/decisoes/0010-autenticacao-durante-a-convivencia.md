# 0010 — Autenticação durante a convivência

- **Situação:** Aceita
- **Data:** 2026-08-19

## Contexto

As senhas do sistema estão em **texto plano** na coluna `LOGIN.SENHA`, com 3 a 6 caracteres. O
Delphi lê a tabela `LOGIN` inteira para a estação a cada abertura e compara a senha digitada
com o texto do campo, dentro do cliente.

Trocar isso por hash é obrigatório na nova stack, mas esbarra num problema: **enquanto o Delphi
existir, ele continuará comparando texto plano**. Substituir a coluna quebraria o legado no
mesmo dia.

## Decisão

Adicionar uma coluna nova, `LOGIN.SENHA_HASH VARCHAR(200)`, aceitando nulo. O Delphi não a
conhece e continua funcionando com `SENHA`. A API autentica assim:

1. Se `SENHA_HASH` está preenchida, valida contra ela e ignora `SENHA`.
2. Se está vazia, valida contra `SENHA` em texto plano e **grava o hash naquele momento**.
3. Quando a senha é trocada pelo novo sistema, grava nas duas colunas — o hash para a API, o
   texto plano para o Delphi continuar funcionando.

A base migra para hash sozinha, conforme as pessoas entram, sem nenhuma janela de manutenção.
Quando o Delphi for desligado, `SENHA` é apagada e o passo 2 deixa de existir.

Durante a convivência, o texto plano continua existindo — o ganho real de segurança só se
completa no desligamento do legado. O que se ganha desde já é que a API nunca trafega nem
compara senha em claro, e que a transição não exige que ninguém redefina senha manualmente.

## Verificação executada

A dúvida que travava a decisão era se o FireDAC do legado sentiria a coluna nova. Os `TFDQuery`
do Delphi usam campos persistentes declarados no `.dfm` (`LOGIN_ID`, `NOME`, `SENHA`, `NIVEL`)
combinados com `SELECT * FROM LOGIN` — e uma coluna a mais no resultado poderia, em tese,
quebrar o mapeamento.

Testado numa cópia, não em produção:

```sql
ALTER TABLE LOGIN ADD SENHA_HASH VARCHAR(200);
```

Resultados:

| Verificação | Resultado |
|---|---|
| `SELECT * FROM LOGIN` | 6 linhas, os 6 usuários intactos |
| `INSERT` sem informar `SENHA_HASH` | aceito (coluna aceita nulo) |
| `UPDATE` sem tocar `SENHA_HASH` | aceito, valor preservado |
| Gravar hash mantendo `SENHA` | as duas colunas convivem |

E o teste que de fato importava — **abrir o legado contra o banco alterado**:

```
Janelas visiveis do processo:
   TfrmLogin | Tela de Acesso
   TApplication |
```

O aplicativo subiu e chegou à tela de login. Isso prova que `CaminhoBanco` conectou e que
`FDqryLogin.Open` executou o `SELECT *` com os campos persistentes **sem lançar exceção**. Se a
conexão tivesse falhado, o legado mostraria um diálogo de erro e encerraria; se o mapeamento de
campos tivesse quebrado, a exceção apareceria antes da tela de login.

O ambiente de teste ficou montado em `C:\PROGRAMAS\AgendaFinanceira-teste-legado`, com o
executável, os relatórios e um `config.ini` apontando para a cópia — fora do repositório e sem
tocar em produção.

## Consequências

**Mais fácil:** migrar para hash sem janela de manutenção, sem pedir que ninguém redefina
senha, e sem risco de deixar alguém de fora.

**Mais difícil:** durante toda a convivência existem duas representações da mesma senha, e
elas precisam ser mantidas em sincronia na troca de senha. É uma complexidade temporária, com
data para acabar.

**Passa a ser obrigatório:** a API nunca compara nem trafega senha em texto plano, mesmo no
passo 2 — ela lê o valor para validar e imediatamente grava o hash. E a coluna `SENHA` só pode
ser apagada depois de confirmado que nenhum usuário abre o legado.

**Fica registrado como risco aceito:** as senhas continuam em texto plano no banco enquanto o
Delphi estiver em uso. É o preço da convivência, e o [roadmap](../roadmap.md) prevê a remoção
na Etapa 7.

**Fica pendente:** escolher o algoritmo de hash na implementação da Etapa 3. A coluna foi
dimensionada com folga (`VARCHAR(200)`) para não precisar ser alterada depois.
