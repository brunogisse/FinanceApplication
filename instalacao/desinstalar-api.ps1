# =============================================================================
#  Remover a API do notebook
#  Rode NO NOTEBOOK, no PowerShell como Administrador.
# =============================================================================
#
# Remove o servico. NAO apaga a copia do banco nem o cliente: apagar dado sem
# pedir e o tipo de coisa que so se descobre depois.
#
# O cliente se desinstala pelo Painel de Controle > Aplicativos, como qualquer
# programa.

#Requires -RunAsAdministrator
param([switch]$ApagarTambemOBanco)

$ErrorActionPreference = 'Stop'

$NOME_SERVICO = 'AgendaFinanceiraApi'
$PastaDeTrabalho = 'C:\AgendaFinanceira'

Write-Host ''
Write-Host '=== Removendo a API da Agenda Financeira ===' -ForegroundColor Cyan
Write-Host ''

$servico = Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
if ($servico) {
    if ($servico.Status -ne 'Stopped') {
        Write-Host 'Parando o servico...' -ForegroundColor DarkGray
        Stop-Service -Name $NOME_SERVICO -Force
    }
    sc.exe delete $NOME_SERVICO | Out-Host
    Write-Host 'Servico removido.' -ForegroundColor Green
} else {
    Write-Host 'O servico nao estava registrado.' -ForegroundColor Yellow
}

if ($ApagarTambemOBanco) {
    if (-not (Test-Path $PastaDeTrabalho)) {
        Write-Host "Nada a apagar: $PastaDeTrabalho nao existe." -ForegroundColor Yellow
        return
    }

    # Destrutivo: mostrar o que vai destruir ANTES de perguntar.
    Write-Host ''
    Write-Host 'Isto vai apagar:' -ForegroundColor Yellow
    Get-ChildItem $PastaDeTrabalho -Recurse -File |
        ForEach-Object { Write-Host ("  {0} ({1:N1} MB)" -f $_.FullName, ($_.Length / 1MB)) }

    Write-Host ''
    Write-Host 'Esta e a copia de trabalho. O banco de ORIGEM nao e tocado.' -ForegroundColor DarkGray
    $resposta = Read-Host 'Apagar? (digite SIM para confirmar)'

    if ($resposta -eq 'SIM') {
        Remove-Item $PastaDeTrabalho -Recurse -Force
        Write-Host 'Copia de trabalho apagada.' -ForegroundColor Green
    } else {
        Write-Host 'Cancelado. Nada foi apagado.' -ForegroundColor Yellow
    }
} else {
    Write-Host ''
    Write-Host "A copia do banco continua em $PastaDeTrabalho." -ForegroundColor DarkGray
    Write-Host 'Para apagar tambem: .\desinstalar-api.ps1 -ApagarTambemOBanco' -ForegroundColor DarkGray
}

Write-Host ''
Write-Host 'O cliente se desinstala pelo Painel de Controle > Aplicativos.' -ForegroundColor Cyan
Write-Host ''
