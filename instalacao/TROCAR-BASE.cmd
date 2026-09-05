@echo off
rem ============================================================================
rem  Agenda Financeira - passar a usar a base que veio no pacote
rem
rem  DOIS CLIQUES NESTE ARQUIVO.
rem
rem  Use quando a maquina JA tem a Agenda funcionando e voce quer trocar os
rem  dados por uma base nova - por exemplo para homologar.
rem
rem  A base que estava em uso NAO e apagada: fica no disco com o nome de antes.
rem
rem  O Windows vai pedir permissao de administrador: e para reiniciar o servico
rem  da API. Clique em Sim.
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0trocar-base.ps1"

echo.
pause
