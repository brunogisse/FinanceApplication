@echo off
rem ============================================================================
rem  RODAR NO NOTEBOOK - habilitar acesso remoto
rem
rem  DOIS CLIQUES NESTE ARQUIVO. Uma vez so.
rem
rem  Depois disto a maquina do Bruno consegue atualizar a Agenda daqui sem
rem  ninguem precisar clicar nesta maquina.
rem
rem  No fim ele imprime o nome e o IP deste computador. ANOTE.
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0habilitar-remoto-no-notebook.ps1"

echo.
pause
