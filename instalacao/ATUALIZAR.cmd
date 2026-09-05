@echo off
rem ============================================================================
rem  Agenda Financeira - atualizar uma instalacao que JA EXISTE
rem
rem  DOIS CLIQUES NESTE ARQUIVO. So isso.
rem
rem  Use este quando a maquina ja tem a Agenda funcionando e chegou uma versao
rem  nova. O banco de trabalho NAO e tocado.
rem
rem  Para instalar pela PRIMEIRA vez, use INSTALAR.cmd, nao este.
rem
rem  O Windows vai pedir permissao de administrador: e para reapontar o servico
rem  da API. Clique em Sim.
rem ============================================================================

rem Reabre a si mesmo com permissao de administrador quando ainda nao tem.
rem O "net session" so funciona elevado - e o teste mais confiavel sem depender
rem de idioma do Windows.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  Pedindo permissao de administrador...
    echo  Uma janela do Windows vai perguntar. Clique em Sim.
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0atualizar-no-notebook.ps1"

echo.
pause
