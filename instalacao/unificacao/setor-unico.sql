/* =============================================================================
   Preparar uma base de UM SETOR SO

   Serve para toda base que nao passou pela unificacao: as de teste, as de
   desenvolvimento, e a de qualquer instalacao que tenha uma operadora so.

   Faz o mesmo que a etapa 1 da unificacao, sem a copia: cria a tabela SETOR,
   acrescenta a coluna SETOR_ID as seis tabelas e marca TUDO como setor 1,
   inclusive os usuarios.

   Rodar com:
     isql -b -user SYSDBA -password masterkey -i setor-unico.sql "localhost:CAMINHO.FDB"

   O -b e obrigatorio: sem ele o isql continua depois de um erro e a base fica
   pela metade, com codigo de saida zero.

   NAO acrescenta SENHA_HASH. Essa e da convivencia com o Delphi (ADR 0010) e
   pode ja existir; ver preparar-base.ps1.
   ============================================================================= */

CREATE TABLE SETOR (
  SETOR_ID  INTEGER NOT NULL PRIMARY KEY,
  DESCRICAO VARCHAR(40) NOT NULL
);
COMMIT;

INSERT INTO SETOR (SETOR_ID, DESCRICAO) VALUES (1, 'FINANCEIRO');
COMMIT;

ALTER TABLE REGISTRO_DE_GASTOS ADD SETOR_ID INTEGER;
ALTER TABLE CATEGORIA          ADD SETOR_ID INTEGER;
ALTER TABLE SUBCATEGORIA       ADD SETOR_ID INTEGER;
ALTER TABLE CONTAS             ADD SETOR_ID INTEGER;
ALTER TABLE FORMA_DE_PAGAMENTO ADD SETOR_ID INTEGER;
ALTER TABLE LOGIN              ADD SETOR_ID INTEGER;
COMMIT;

UPDATE REGISTRO_DE_GASTOS SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
UPDATE CATEGORIA          SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
UPDATE SUBCATEGORIA       SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
UPDATE CONTAS             SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
UPDATE FORMA_DE_PAGAMENTO SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
UPDATE LOGIN              SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
COMMIT;

/* A rede de seguranca da convivencia.

   O Delphi nao conhece a coluna, entao tudo que ele gravar entra com SETOR_ID
   nulo - e registro sem setor NAO APARECE PARA NINGUEM na API. Esta trigger
   deduz o setor pelo autor do lancamento, que e exatamente como os setores
   foram descobertos na unificacao.

   POSITION 1 a coloca depois da REGISTRO_DE_GASTOS_BI, que e a que atribui o
   identificador pelo generator e esta na posicao 0.

   Quando nem assim der para deduzir - usuario tambem sem setor - o registro
   fica sem setor de proposito, em vez de ser atribuido a um lado por chute. O
   endpoint /saude conta esses registros. */
SET TERM ^ ;
CREATE TRIGGER REGISTRO_DE_GASTOS_BI_SETOR FOR REGISTRO_DE_GASTOS
ACTIVE BEFORE INSERT POSITION 1
AS
BEGIN
  IF (NEW.SETOR_ID IS NULL) THEN
    NEW.SETOR_ID = (SELECT SETOR_ID FROM LOGIN WHERE LOGIN_ID = NEW.USERID);
END^
SET TERM ; ^
COMMIT;
