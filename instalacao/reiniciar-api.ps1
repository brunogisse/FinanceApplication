# =============================================================================
#  Reiniciar o servico da API e PROVAR qual banco ele passou a usar
#  Nao rode este arquivo direto. De dois cliques em REINICIAR-API.cmd.
# =============================================================================
#
# Serve para depois de trocar o appsettings.Production.json - por exemplo ao
# apontar a API para outra base preparada pelo preparar-base.ps1.
#
# POR QUE NAO BASTA REINICIAR
#
# O servico fica "Running" com a API morta dentro, e a API responde igualzinho
# apontando para o banco errado. Por isso a conferencia nao pergunta se o servico
# subiu: ela pergunta ao /saude QUAL ARQUIVO esta em uso e compara com o que o
# arquivo de configuracao manda usar.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$NOME_SERVICO = 'AgendaFinanceiraApi'
$PORTA        = 5199

function Titulo($t) {
    Write-Host ''
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host " $t" -ForegroundColor Cyan
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host ''
}

function Parar($m) {
    Write-Host ''
    Write-Host $m -ForegroundColor Red
    Write-Host ''
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

Titulo 'Reiniciar a API'

$servico = Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
if (-not $servico) { Parar "O servico $NOME_SERVICO nao existe nesta maquina." }

$caminhoExe = (Get-CimInstance Win32_Service -Filter "Name='$NOME_SERVICO'").PathName.Trim('"')
$pasta      = Split-Path $caminhoExe -Parent
$config     = Join-Path $pasta 'appsettings.Production.json'

if (-not (Test-Path $config)) { Parar "Nao achei a configuracao em $config" }

$j = Get-Content $config -Raw | ConvertFrom-Json
$bancoPedido = $j.Banco.Caminho
$arquivoPedido = Split-Path $bancoPedido.Replace('/', '\') -Leaf

Write-Host ("Servico:  {0}" -f $pasta)
Write-Host ("Config pede o banco:  {0}" -f $bancoPedido) -ForegroundColor Cyan

$noDisco = $bancoPedido.Replace('/', '\')
if (-not (Test-Path $noDisco)) {
    Parar @"
O banco que a configuracao pede NAO existe:

  $noDisco

Subir assim deixaria a API no ar sem alcancar banco nenhum. Corrija o caminho
ou prepare a base com preparar-base.ps1.
"@
}
Write-Host ("                      {0:N2} MB, no disco" -f ((Get-Item $noDisco).Length / 1MB)) -ForegroundColor Green

# ------------------------------------------------------------------ reiniciar
Write-Host ''
Write-Host 'Reiniciando...' -ForegroundColor Cyan
if ($servico.Status -ne 'Stopped') {
    Stop-Service -Name $NOME_SERVICO -Force
    $servico.WaitForStatus('Stopped', '00:00:30')
}

# O Windows diz "parado" antes de o processo largar os arquivos.
$n = 0
while ((Get-Process -Name 'AgendaFinanceira.Api' -ErrorAction SilentlyContinue) -and $n -lt 20) {
    Start-Sleep -Milliseconds 500
    $n++
}

Start-Service -Name $NOME_SERVICO
(Get-Service -Name $NOME_SERVICO).WaitForStatus('Running', '00:00:30')
Write-Host '  no ar.' -ForegroundColor Green

# ------------------------------------------------------------------ conferir
Titulo 'Conferindo'

$saude = $null
for ($i = 1; $i -le 12; $i++) {
    try { $saude = Invoke-RestMethod -Uri "http://localhost:$PORTA/saude" -TimeoutSec 3; break }
    catch { Start-Sleep -Seconds 2 }
}

if (-not $saude) { Parar "A API nao respondeu em http://localhost:$PORTA depois de subir." }

Write-Host ("  a API diz estar usando:  {0}" -f $saude.banco) -ForegroundColor Cyan
Write-Host ("  a configuracao pede:     {0}" -f $arquivoPedido) -ForegroundColor Cyan

if ($saude.banco -ne $arquivoPedido) {
    Parar @"
A API subiu apontando para OUTRO banco.

  usando:  $($saude.banco)
  pedido:  $arquivoPedido

Quase sempre isto quer dizer que o servico nao esta lendo o appsettings.Production.json
- confira se a variavel ASPNETCORE_ENVIRONMENT=Production continua no registro do
servico, em HKLM:\SYSTEM\CurrentControlSet\Services\$NOME_SERVICO
"@
}

Write-Host ''
Write-Host 'Confere: a API esta usando a base pedida.' -ForegroundColor Green
Write-Host ''
Write-Host 'Se voce trocou de base, saia e entre de novo no aplicativo.' -ForegroundColor Yellow
Write-Host 'A sessao antiga foi assinada com a mesma chave e continua valendo, mas o' -ForegroundColor Yellow
Write-Host 'numero do usuario dentro dela e o da base ANTERIOR - noutra base ele pode' -ForegroundColor Yellow
Write-Host 'ser outra pessoa.' -ForegroundColor Yellow
Write-Host ''
Read-Host 'Pressione Enter para fechar'
