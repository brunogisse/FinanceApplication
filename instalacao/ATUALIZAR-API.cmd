@echo off
rem ============================================================================
rem  Agenda Financeira - atualizar a API ja instalada
rem
rem  DOIS CLIQUES NESTE ARQUIVO.
rem
rem  Serve para depois de mexer no codigo do servidor: para o servico, republica
rem  e sobe de novo. O Windows vai pedir permissao de administrador - e para
rem  parar e subir o servico. Clique em Sim.
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0atualizar-api.ps1"

echo.
pause
