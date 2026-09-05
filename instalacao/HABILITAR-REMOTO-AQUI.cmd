@echo off
rem ============================================================================
rem  RODAR NA MAQUINA DO BRUNO - permitir conectar no notebook
rem
rem  DOIS CLIQUES NESTE ARQUIVO. Uma vez so.
rem
rem  Rode DEPOIS de ter rodado o HABILITAR-REMOTO.cmd no notebook. Ele vai
rem  perguntar o nome ou o IP que o script de la imprimiu.
rem
rem  Isto NAO abre esta maquina para ninguem: so diz em quem ela confia para
rem  CONECTAR.
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0habilitar-remoto-aqui.ps1"

echo.
pause
