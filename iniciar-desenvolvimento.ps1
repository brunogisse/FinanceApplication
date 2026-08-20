# Sobe tudo o que o sistema novo precisa para rodar em desenvolvimento:
# a API, o servidor do Angular e a janela do Electron.
#
# Uso:   .\iniciar-desenvolvimento.ps1
# Parar: feche a janela do aplicativo e depois as duas janelas de terminal que abrirem,
#        ou rode .\parar-desenvolvimento.ps1

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot

$portaApi = 5199
$portaWeb = 4200

function Escrever($texto, $cor = 'White') { Write-Host $texto -ForegroundColor $cor }

Escrever "`n=== Agenda Financeira - ambiente de desenvolvimento ===`n" Cyan

# --- Verificações antes de subir qualquer coisa ---

$banco = "C:\PROGRAMAS\AgendaFinanceira-paridade\DESENVOLVIMENTO.FDB"
if (-not (Test-Path $banco)) {
    Escrever "ERRO: banco de desenvolvimento nao encontrado em:" Red
    Escrever "  $banco" Red
    Escrever "`nRecrie-o a partir do backup de paridade:" Yellow
    Escrever '  $fb = "C:\Program Files\Firebird\Firebird_2_5\bin"' Yellow
    Escrever '  $P  = "C:\PROGRAMAS\AgendaFinanceira-paridade"' Yellow
    Escrever '  & "$fb\gbak.exe" -c -user SYSDBA -password masterkey `' Yellow
    Escrever '      "$P\base-paridade-2026-08-19.fbk" "localhost:$P\DESENVOLVIMENTO.FDB"' Yellow
    exit 1
}
Escrever "[ok] banco de desenvolvimento encontrado" Green

$servico = Get-Service -Name 'FirebirdServerDefaultInstance' -ErrorAction SilentlyContinue
if ($servico -and $servico.Status -ne 'Running') {
    Escrever "AVISO: o servico do Firebird nao esta rodando. Inicie-o antes de continuar." Yellow
}
elseif ($servico) { Escrever "[ok] servico do Firebird rodando" Green }

Push-Location (Join-Path $raiz 'src\AgendaFinanceira.Api')
$temChave = (dotnet user-secrets list 2>&1 | Select-String 'Jwt:Chave') -ne $null
Pop-Location

if (-not $temChave) {
    Escrever "`nERRO: a chave de assinatura dos tokens nao esta configurada." Red
    Escrever "A API nao sobe sem ela. Configure uma vez com:" Yellow
    Escrever '  cd "src\AgendaFinanceira.Api"' Yellow
    Escrever '  dotnet user-secrets set "Jwt:Chave" "<48 bytes aleatorios em base64>"' Yellow
    exit 1
}
Escrever "[ok] chave de assinatura configurada" Green

# --- Encerra instâncias antigas, para nao brigar por porta ---

foreach ($nome in @('AgendaFinanceira.Api', 'electron')) {
    Get-CimInstance Win32_Process -Filter "Name='$nome.exe'" -ErrorAction SilentlyContinue |
        ForEach-Object { try { Invoke-CimMethod -InputObject $_ -MethodName Terminate | Out-Null } catch {} }
}

# --- Sobe a API ---

Escrever "`nSubindo a API na porta $portaApi..." Cyan
Start-Process powershell -ArgumentList @(
    '-NoExit', '-Command',
    "Set-Location '$raiz\src\AgendaFinanceira.Api'; " +
    "Write-Host 'API - Agenda Financeira' -ForegroundColor Cyan; " +
    "dotnet run --urls http://localhost:$portaApi"
)

$pronta = $false
foreach ($tentativa in 1..40) {
    Start-Sleep -Seconds 2
    try {
        $r = Invoke-RestMethod "http://localhost:$portaApi/saude" -TimeoutSec 3
        Escrever "[ok] API no ar, usando o banco: $($r.banco)" Green
        $pronta = $true
        break
    } catch { }
}

if (-not $pronta) {
    Escrever "ERRO: a API nao respondeu. Veja a janela da API para o motivo." Red
    exit 1
}

# --- Sobe o Angular ---

Escrever "`nSubindo o cliente na porta $portaWeb (a primeira vez demora)..." Cyan
Start-Process powershell -ArgumentList @(
    '-NoExit', '-Command',
    "Set-Location '$raiz\cliente\agenda-web'; " +
    "Write-Host 'Cliente Angular' -ForegroundColor Cyan; " +
    "npx ng serve --port $portaWeb"
)

$pronto = $false
foreach ($tentativa in 1..60) {
    Start-Sleep -Seconds 2
    try {
        Invoke-WebRequest "http://localhost:$portaWeb" -TimeoutSec 3 -UseBasicParsing | Out-Null
        Escrever "[ok] cliente no ar" Green
        $pronto = $true
        break
    } catch { }
}

if (-not $pronto) {
    Escrever "ERRO: o cliente nao respondeu. Veja a janela do Angular." Red
    exit 1
}

# --- Abre a janela do aplicativo ---
# ELECTRON_RUN_AS_NODE herdado do editor faz o Electron rodar como Node e sair sem abrir
# janela. Por isso a variavel e limpa aqui, no mesmo processo que inicia o app.

Escrever "`nAbrindo o aplicativo..." Cyan
$env:ELECTRON_RUN_AS_NODE = $null
Start-Process powershell -ArgumentList @(
    '-NoExit', '-Command',
    "`$env:ELECTRON_RUN_AS_NODE = `$null; " +
    "Set-Location '$raiz\cliente\agenda-desktop'; " +
    "Write-Host 'Aplicativo (Electron)' -ForegroundColor Cyan; " +
    "npx electron . --dev"
)

Escrever "`n=== Tudo no ar ===" Green
Escrever "  Aplicativo : janela do Electron que acabou de abrir"
Escrever "  Cliente    : http://localhost:$portaWeb"
Escrever "  API        : http://localhost:$portaApi  (documentacao em /swagger)"
Escrever "`nUsuarios de teste no banco de desenvolvimento:" Cyan
Escrever "  DEMO       / demo123   nivel 3 - faz tudo"
Escrever "  OUTROOP    / op123     nivel 2 - opera, nao administra"
Escrever "  SOCONSULTA / ver123    nivel 1 - so consulta"
Escrever "`nO banco usado e uma COPIA. A base de producao nao e tocada.`n" Yellow
