# =============================================================================
#  Conferir o estado da instalacao no notebook
#  Rode NO NOTEBOOK. Nao precisa de Administrador para a maior parte.
# =============================================================================
#
# Nao altera nada. Serve para responder "esta funcionando?" sem adivinhar.
#
# Cada verificacao e feita por DUAS vias quando possivel: um cmdlet sem elevacao
# pode devolver vazio por falta de permissao, e concluir a partir dele leva a
# diagnostico errado.

$NOME_SERVICO = 'AgendaFinanceiraApi'
$PORTA = 5199

Write-Host ''
Write-Host '=== Agenda Financeira - estado da instalacao ===' -ForegroundColor Cyan
Write-Host ''

# ---------------------------------------------------------------- servico
Write-Host '[servico]' -ForegroundColor Cyan
$servico = Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
if ($servico) {
    Write-Host ("  {0}: {1}" -f $servico.DisplayName, $servico.Status)
} else {
    Write-Host '  Get-Service nao encontrou. Conferindo por segunda via (sc.exe)...' -ForegroundColor Yellow
    sc.exe query $NOME_SERVICO | Out-Host
}

# ------------------------------------------------------------------- API
Write-Host ''
Write-Host '[API]' -ForegroundColor Cyan
$noAr = $false
try {
    $saude = Invoke-RestMethod -Uri "http://localhost:$PORTA/saude" -TimeoutSec 3
    Write-Host ("  responde em http://localhost:{0}" -f $PORTA) -ForegroundColor Green
    Write-Host ("  banco em uso: {0}" -f $saude.banco)
    $noAr = $true
} catch {
    Write-Host ("  NAO responde em http://localhost:{0}" -f $PORTA) -ForegroundColor Red
    Write-Host ("  {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
}

# O servico pode estar "Running" com a API morta dentro. Uma chamada que passa pelo
# banco prova mais que /saude.
Write-Host ''
Write-Host '[banco, por uma chamada que le de verdade]' -ForegroundColor Cyan

# Sem a API no ar nao ha o que sondar: insistir so faz esperar o tempo limite de novo,
# depois de a linha acima ja ter dito que ela nao responde.
if (-not $noAr) {
    Write-Host '  pulado: a API nao respondeu acima.' -ForegroundColor DarkGray
} else {
    try {
        # Nome CURTO de proposito: LOGIN.NOME e VARCHAR(20), e um parametro maior faz o
        # Firebird recusar a comparacao com "string right truncation". A sonda antiga tinha
        # 22 caracteres e devolvia 500 - parecia que a API nao alcancava o banco, quando o
        # errado era a sonda.
        $corpo = @{ usuario = 'sonda-nao-existe'; senha = 'x' } | ConvertTo-Json
        Invoke-RestMethod -Uri "http://localhost:$PORTA/sessao" -Method Post `
            -ContentType 'application/json' -Body $corpo -TimeoutSec 5 | Out-Null
        Write-Host '  resposta inesperada: um usuario inexistente foi aceito' -ForegroundColor Red
    } catch {
        $codigo = $_.Exception.Response.StatusCode.value__
        if ($codigo -eq 401) {
            Write-Host '  o banco respondeu (recusou um usuario inexistente, como deve)' -ForegroundColor Green
        } else {
            Write-Host ("  falhou com HTTP {0} - a API subiu mas nao alcanca o banco" -f $codigo) -ForegroundColor Red
        }
    }
}

# --------------------------------------------------------------- cliente
Write-Host ''
Write-Host '[cliente]' -ForegroundColor Cyan
$atalho = Join-Path $env:LOCALAPPDATA 'Programs\agenda-desktop\Agenda Financeira.exe'
if (Test-Path $atalho) {
    $item = Get-Item $atalho
    Write-Host ("  instalado: {0} ({1:N1} MB)" -f $item.FullName, ($item.Length / 1MB)) -ForegroundColor Green
} else {
    Write-Host '  nao encontrei o executavel no caminho padrao do instalador por usuario.' -ForegroundColor Yellow
    Write-Host '  Procure por "Agenda Financeira" no menu Iniciar.' -ForegroundColor DarkGray
}

# --------------------------------------------------------------- firebird
Write-Host ''
Write-Host '[firebird]' -ForegroundColor Cyan
$fbServico = Get-Service -Name 'FirebirdServerDefaultInstance' -ErrorAction SilentlyContinue
if ($fbServico) {
    Write-Host ("  {0}: {1}" -f $fbServico.Name, $fbServico.Status)
} else {
    Write-Host '  servico do Firebird nao encontrado por Get-Service; conferindo por sc.exe...' -ForegroundColor Yellow
    sc.exe query type= service state= all | Select-String -Pattern 'Firebird' | Out-Host
}

Write-Host ''
