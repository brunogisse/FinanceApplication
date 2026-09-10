@echo off
rem ============================================================================
rem  Unificar a base do FINANCEIRO com a do FATURAMENTO
rem
rem  DOIS CLIQUES NESTE ARQUIVO.
rem
rem  Gera uma base unica onde cada lancamento e cada cadastro carrega o setor a
rem  que pertence. Cada operaria continua vendo exatamente o que ve hoje.
rem
rem  AS BASES DE ORIGEM NAO SAO TOCADAS. Elas so sao lidas.
rem
rem  O que ele pergunta:
rem    - onde esta a base do FINANCEIRO   (a da Juliana, nivel 3)
rem    - onde esta a base do FATURAMENTO  (a da aline)
rem    - onde gravar a base unificada
rem
rem  No fim ele confere contagem, somas e ate a quantidade de bytes de texto
rem  contra as duas origens. Se algo divergir, ele recusa o resultado.
rem
rem  Ver docs\unificacao-das-bases.md para o levantamento completo.
rem
rem  O Windows vai pedir permissao de administrador. Clique em Sim.
rem ============================================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  Pedindo permissao de administrador...
    echo  Uma janela do Windows vai perguntar. Clique em Sim.
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

setlocal
set /p FIN=Caminho da base do FINANCEIRO (Juliana):
set /p FAT=Caminho da base do FATURAMENTO (aline):
set /p DEST=Onde gravar a base unificada:

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0unificar-bases.ps1" -Financeiro "%FIN%" -Faturamento "%FAT%" -Destino "%DEST%"

echo.
pause
