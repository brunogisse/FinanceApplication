@echo off
rem ============================================================================
rem  Agenda Financeira - reiniciar a API e conferir qual banco ela usa
rem
rem  DOIS CLIQUES NESTE ARQUIVO.
rem
rem  Use depois de trocar a base no appsettings.Production.json.
rem
rem  O Windows vai pedir permissao de administrador: parar e subir um servico
rem  exige isso. Clique em Sim.
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0reiniciar-api.ps1"

echo.
pause
