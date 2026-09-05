@echo off
rem ============================================================================
rem  Agenda Financeira - apontar a API para qualquer banco
rem
rem  DOIS CLIQUES NESTE ARQUIVO. Abre uma janela para voce escolher o .FDB.
rem
rem  Troca o banco, reinicia a API e prova que ela subiu usando o que voce
rem  escolheu. A configuracao anterior fica guardada ao lado, com a hora no
rem  nome.
rem
rem  Nao copia nem gera banco nenhum: aponta para um que ja existe. Para
rem  instalar dados novos vindos do pacote, use TROCAR-BASE.cmd.
rem
rem  O Windows vai pedir permissao de administrador: e para reiniciar o
rem  servico. Clique em Sim.
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0apontar-para.ps1"

echo.
pause
