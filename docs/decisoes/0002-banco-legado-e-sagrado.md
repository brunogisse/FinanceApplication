# 0002 — O banco legado é sagrado

- **Situação:** Aceita
- **Data:** 2026-08-18

## Contexto

O banco em produção guarda **13.972 lançamentos financeiros** de março de 2022 a março de
2025, somando **R$ 34,5 milhões** em pagamentos registrados. É a única fonte desses dados.

A proteção existente é frágil:

- O backup automático é uma cópia de arquivo (`CopyFile`) feita com o banco possivelmente
  aberto, o que pode produzir um arquivo inconsistente.
- Os caminhos de origem e destino do backup estão fixos no código, apontando para a área de
  trabalho de um usuário específico.
- O backup manual tem o mesmo problema: os componentes `TFDIBBackup` estão no formulário, mas
  nunca são chamados.
- O `config.ini` traz `SYSDBA` / `masterkey` em texto plano e está versionado no Git.

Durante a própria Fase 2 deste trabalho, uma operação considerada "somente leitura" alterou o
arquivo de produção: o `gbak` conecta pelo servidor, e o Firebird avançou os contadores de
transação no cabeçalho, mudando a data de modificação do arquivo. Nenhum dado foi afetado, mas
o episódio mostra que "só ler" não é automático — precisa ser projetado.

## Decisão

O banco de produção é tratado como fonte imutável durante toda a migração. Concretamente:

1. **Nenhum DDL ou DML é executado no banco de produção.** Toda exploração, teste e validação
   acontece sobre uma cópia de trabalho.
2. A cópia de trabalho é gerada por `gbak -b` seguido de `gbak -c`, nunca por cópia de
   arquivo. O backup lógico é consistente e, de quebra, valida a integridade da origem.
3. Para leitura sem escrita nenhuma, o arquivo é copiado primeiro e a conexão é feita apenas
   contra a cópia — conectar à origem pelo servidor sempre escreve no cabeçalho.
4. Todo script `isql` roda com `-v ON_ERROR_STOP=1`. Sem isso, o `isql` continua após erros e
   termina com código de saída zero, declarando sucesso sobre um trabalho pela metade.
5. Todo script destrutivo mostra o que vai destruir **antes** de perguntar, incluindo
   contagens que permitam a pessoa reconhecer os próprios dados, e confere o código de saída
   de cada passo.
6. Bases de desenvolvimento são anonimizadas: `LOGIN.SENHA` e `FORNECEDOR.CNPJ` no mínimo.
7. Quando a migração exigir alterar o banco legado — como a correção dos generators
   compartilhados —, a mudança tem ADR próprio, é ensaiada na cópia, e só então é aplicada com
   backup imediatamente anterior.

## Consequências

**Mais fácil:** trabalhar sem medo. Qualquer experimento é reversível porque acontece na
cópia.

**Mais difícil:** todo ciclo de investigação passa a exigir o passo de gerar a cópia, o que
custa tempo. É um preço aceitável.

**Passa a ser obrigatório:** antes de qualquer escrita no banco legado, um backup verificado —
verificado significa restaurado com sucesso, não apenas gerado.

**Fica pendente:** o backup de produção continua sendo cópia de arquivo com caminho fixo. Isso
é um risco atual, independente da migração, e deve ser tratado como melhoria de curto prazo no
roadmap da Fase 5.
