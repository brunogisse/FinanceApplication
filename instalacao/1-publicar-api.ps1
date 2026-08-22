# =============================================================================
#  PASSO 1 - Publicar a API
#  Rode este script NESTA MAQUINA (a de desenvolvimento).
# =============================================================================
#
# Gera a pasta "publicado" com a API pronta para rodar. E self-contained: leva o
# proprio runtime .NET dentro, entao o notebook da operadora NAO precisa ter
# .NET instalado.
#
# O acesso ao Firebird e pelo provedor gerenciado (FirebirdSql.Data.FirebirdClient),
# entao tambem nao e preciso fbclient.dll ao lado do executavel.
#
# Depois de rodar, copie para o notebook a pasta "instalacao" inteira, junto com
# o instalador do cliente (cliente/agenda-desktop/instalador/*.exe).

$ErrorActionPreference = 'Stop'

$raiz      = Split-Path $PSScriptRoot -Parent
$projeto   = Join-Path $raiz 'src\AgendaFinanceira.Api\AgendaFinanceira.Api.csproj'
$publicado = Join-Path $PSScriptRoot 'publicado'

Write-Host ''
Write-Host '=== Publicando a API (self-contained, win-x64) ===' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $projeto)) { throw "Nao encontrei o projeto em $projeto" }

# Comeca do zero: sobras de uma publicacao anterior iriam junto para o notebook.
if (Test-Path $publicado) {
    Write-Host "Limpando $publicado" -ForegroundColor DarkGray
    Remove-Item $publicado -Recurse -Force
}

dotnet publish $projeto `
    --configuration Release `
    --runtime win-x64 `
    --self-contained true `
    --output $publicado `
    /p:DebugType=None `
    /p:GenerateDocumentationFile=false | Out-Host

if ($LASTEXITCODE -ne 0) { throw "dotnet publish falhou com codigo $LASTEXITCODE." }

$executavel = Join-Path $publicado 'AgendaFinanceira.Api.exe'
if (-not (Test-Path $executavel)) {
    throw "A publicacao terminou sem erro, mas $executavel nao existe. Confira a saida acima."
}

# O appsettings.json publicado aponta para a base de DESENVOLVIMENTO desta maquina.
# Quem corrige isso e o passo 2, no notebook. Deixar assim e proposital: se algo der
# errado la, a API nao sobe em vez de escrever no lugar errado.
$tamanho = [Math]::Round((Get-ChildItem $publicado -Recurse | Measure-Object Length -Sum).Sum / 1MB, 1)

Write-Host ''
Write-Host "OK. API publicada em $publicado ($tamanho MB)" -ForegroundColor Green
Write-Host ''
Write-Host 'Proximos passos:' -ForegroundColor Cyan
Write-Host '  1. Copie a pasta "instalacao" inteira para o notebook'
Write-Host '  2. Copie tambem o instalador do cliente:'
Write-Host '     cliente\agenda-desktop\instalador\AgendaFinanceira-Instalador-*.exe'
Write-Host '  3. No notebook, rode 2-instalar-no-notebook.ps1 como Administrador'
Write-Host ''
