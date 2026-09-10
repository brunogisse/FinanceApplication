/* =============================================================================
   ETAPA 1 - Estrutura e marcacao do que ja esta na base
   Roda sobre o DESTINO (copia do financeiro, feita por gbak).
   ============================================================================= */

CREATE TABLE SETOR (
  SETOR_ID  INTEGER NOT NULL PRIMARY KEY,
  DESCRICAO VARCHAR(40) NOT NULL
);
COMMIT;

INSERT INTO SETOR (SETOR_ID, DESCRICAO) VALUES (1, 'FINANCEIRO');
INSERT INTO SETOR (SETOR_ID, DESCRICAO) VALUES (2, 'FATURAMENTO');
COMMIT;

/* SETOR_ID vai nos cadastros tambem, e nao so nos lancamentos.

   Casar "CHACARA 2" de uma base com "CHACARA 2" da outra seria ASSUMIR que sao a
   mesma propriedade. Com setor no cadastro, cada operaria ve a lista dela, sem
   nome repetido no seletor e sem ninguem perder nada. */
ALTER TABLE REGISTRO_DE_GASTOS ADD SETOR_ID INTEGER;
ALTER TABLE CATEGORIA          ADD SETOR_ID INTEGER;
ALTER TABLE SUBCATEGORIA       ADD SETOR_ID INTEGER;
ALTER TABLE CONTAS             ADD SETOR_ID INTEGER;
ALTER TABLE FORMA_DE_PAGAMENTO ADD SETOR_ID INTEGER;
ALTER TABLE LOGIN              ADD SETOR_ID INTEGER;
COMMIT;

/* A coluna de convivencia da autenticacao. O Delphi ignora colunas que nao
   conhece - ADR 0010 - e assim a base ja sai pronta para a API. */
ALTER TABLE LOGIN ADD SENHA_HASH VARCHAR(200);
COMMIT;

/* Tudo que ja estava aqui e do financeiro. */
UPDATE REGISTRO_DE_GASTOS SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
UPDATE CATEGORIA          SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
UPDATE SUBCATEGORIA       SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
UPDATE CONTAS             SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
UPDATE FORMA_DE_PAGAMENTO SET SETOR_ID = 1 WHERE SETOR_ID IS NULL;
COMMIT;

/* Os 6 usuarios sao IDENTICOS nas duas bases - mesmos IDs, mesmos nomes, mesmos
   niveis. Entao LOGIN nao e copiado: cada pessoa recebe o setor a que pertence.

   Medido em 08/09/2026, por quem lancou o que:
     JULIANA  17.743 no financeiro  |  aline  6.874 no faturamento
     ALINEAP     51 / 65            |  HAYOLLA  112 no faturamento           */
UPDATE LOGIN SET SETOR_ID = 1 WHERE UPPER(TRIM(NOME)) IN ('JULIANA', 'EGLECIR', 'KA');
UPDATE LOGIN SET SETOR_ID = 2 WHERE UPPER(TRIM(NOME)) IN ('ALINE', 'HAYOLLA', 'ALINEAP');
COMMIT;

/* A rede de seguranca da convivencia com o Delphi.

   Ele nao conhece a coluna, entao tudo que ele gravar entra com SETOR_ID nulo -
   e registro sem setor NAO APARECE PARA NINGUEM na API. Esta trigger deduz o
   setor pelo autor, que e exatamente como os setores foram descobertos aqui:
   JULIANA lancou 100% do financeiro, aline 98% do faturamento.

   POSITION 1 a coloca depois da REGISTRO_DE_GASTOS_BI, que atribui o
   identificador pelo generator e esta na posicao 0.

   A copia da etapa 2 informa o setor explicitamente, entao a trigger nao
   interfere nela.

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
