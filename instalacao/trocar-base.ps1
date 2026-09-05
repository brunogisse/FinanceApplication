# =============================================================================
#  Trocar a base que a API usa, numa maquina JA INSTALADA
#  Nao rode este arquivo direto. De dois cliques em TROCAR-BASE.cmd.
# =============================================================================
#
# Prepara a base que veio no pacote e aponta a API para ela.
#
# A base que estava em uso NAO e apagada. Ela continua no disco com o nome de
# antes, e voltar atras e apontar a configuracao de volta.
#
# ORDEM DAS COISAS
#
# A base nova e preparada e conferida ANTES de o servico ser tocado. Se a
# preparacao falhar, a API segue no ar com a base de antes. Nada de derrubar o
# que funciona antes de provar que o substituto existe.

#Requires -RunAsAdministrator

param(
    [string]$Origem = '',
    [string]$PastaDeTrabalho = 'C:\AgendaFinanceira'
)

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
    Write-Host 'A API continua com a base de antes.' -ForegroundColor Green
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

Titulo 'Trocar a base da Agenda Financeira'

# =============================================================================
#  Recusar antes de comecar
# =============================================================================

if ($PSScriptRoot.StartsWith('\\')) {
    Parar "Esta pasta esta na REDE ($PSScriptRoot). Copie o pacote para o disco local e rode dali."
}

$servico = Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
if (-not $servico) {
    Parar @"
Esta maquina ainda NAO tem a Agenda Financeira instalada.

Para instalar pela primeira vez use instalacao\INSTALAR.cmd - ele ja instala com a
base que veio no pacote, e este arquivo nao e necessario.
"@
}

$caminhoExe = (Get-CimInstance Win32_Service -Filter "Name='$NOME_SERVICO'").PathName.Trim('"')
$config     = Join-Path (Split-Path $caminhoExe -Parent) 'appsettings.Production.json'
if (-not (Test-Path $config)) { Parar "Nao achei a configuracao da instalacao em $config" }

$j = Get-Content $config -Raw | ConvertFrom-Json
$bancoDeAntes = $j.Banco.Caminho
Write-Host ("Base em uso hoje:  {0}" -f $bancoDeAntes) -ForegroundColor Gray

# ------------------------------------------------------------------- origem
#
# O .FDB vem na pasta de cima, ao lado do LEIA-ME. Um so: com mais de um nao da
# para adivinhar qual e, e adivinhar aqui seria trocar a base errada.
if (-not $Origem) {
    $achados = @(Get-ChildItem (Join-Path $PSScriptRoot '..') -Filter '*.FDB' -File -ErrorAction SilentlyContinue)

    if ($achados.Count -eq 0) {
        Parar 'Nao achei nenhum arquivo .FDB no pacote. Ele deveria estar ao lado do LEIA-ME.'
    }
    if ($achados.Count -gt 1) {
        Write-Host ''
        Write-Host 'Achei mais de uma base no pacote:' -ForegroundColor Yellow
        for ($i = 0; $i -lt $achados.Count; $i++) {
            Write-Host ("  [{0}] {1}  ({2:N2} MB, {3})" -f ($i + 1), $achados[$i].Name,
                        ($achados[$i].Length / 1MB), $achados[$i].LastWriteTime)
        }
        $n = Read-Host 'Numero da que voce quer usar'
        if ($n -notmatch '^\d+$' -or [int]$n -lt 1 -or [int]$n -gt $achados.Count) { Parar 'Escolha invalida.' }
        $Origem = $achados[[int]$n - 1].FullName
    } else {
        $Origem = $achados[0].FullName
    }
}

if (-not (Test-Path $Origem)) { Parar "Nao achei a base de origem: $Origem" }

$nome    = [System.IO.Path]::GetFileNameWithoutExtension($Origem)
$destino = Join-Path $PastaDeTrabalho "$nome.FDB"

Write-Host ("Base que sera instalada:  {0}" -f (Split-Path $Origem -Leaf)) -ForegroundColor Cyan
Write-Host ("Ficara em:                {0}" -f $destino) -ForegroundColor Cyan
Write-Host ''

if ($bancoDeAntes.Replace('/', '\') -eq $destino) {
    Write-Host 'A API JA usa uma base com este nome, e ela sera REGERADA a partir da origem.' -ForegroundColor Yellow
    Write-Host 'O que tiver sido lancado nela se perde.' -ForegroundColor Yellow
    Write-Host ''
}

# =============================================================================
#  Preparar a base ANTES de tocar no servico
# =============================================================================

$preparar = Join-Path $PSScriptRoot 'preparar-base.ps1'
if (-not (Test-Path $preparar)) { Parar "Nao achei $preparar" }

& $preparar -Origem $Origem -Nome $nome -PastaDeTrabalho $PastaDeTrabalho
if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) { Parar 'A preparacao da base nao terminou. Nada foi trocado.' }
if (-not (Test-Path $destino)) { Parar "A preparacao terminou, mas $destino nao existe. Nada foi trocado." }

# =============================================================================
#  Apontar e reiniciar
# =============================================================================

Titulo 'Apontando a API para a base nova'

# A configuracao de antes fica guardada ao lado, para dar meia-volta em um passo.
$guardada = "$config.antes-de-$nome"
Copy-Item $config $guardada -Force
Write-Host ("Configuracao anterior guardada em:`n  {0}" -f $guardada) -ForegroundColor DarkGray

$j.Banco.Caminho = $destino.Replace('\', '/')
# WriteAllText com UTF8 sem BOM: Set-Content gravaria na codificacao ANSI do sistema.
[System.IO.File]::WriteAllText($config, ($j | ConvertTo-Json -Depth 10),
                               (New-Object System.Text.UTF8Encoding $false))

$conferir = Get-Content $config -Raw | ConvertFrom-Json
if ($conferir.Banco.Caminho -ne $destino.Replace('\', '/')) { Parar 'Falhei ao gravar a configuracao.' }
if (-not $conferir.Jwt.Chave -or $conferir.Jwt.Chave.Length -lt 32) {
    Copy-Item $guardada $config -Force
    Parar 'A gravacao perdeu a chave de assinatura. A configuracao anterior foi devolvida.'
}
Write-Host 'Configuracao gravada, com a chave de assinatura preservada.' -ForegroundColor Green

Write-Host ''
Write-Host 'Reiniciando o servico...' -ForegroundColor Cyan
if ((Get-Service -Name $NOME_SERVICO).Status -ne 'Stopped') {
    Stop-Service -Name $NOME_SERVICO -Force
    (Get-Service -Name $NOME_SERVICO).WaitForStatus('Stopped', '00:00:30')
}
$n = 0
while ((Get-Process -Name 'AgendaFinanceira.Api' -ErrorAction SilentlyContinue) -and $n -lt 20) {
    Start-Sleep -Milliseconds 500
    $n++
}
Start-Service -Name $NOME_SERVICO
(Get-Service -Name $NOME_SERVICO).WaitForStatus('Running', '00:00:30')
Write-Host '  no ar.' -ForegroundColor Green

# =============================================================================
#  Conferir o EFEITO
# =============================================================================
#
# O servico fica "Running" com a API morta dentro, e a API responde igualzinho
# apontando para o banco errado. O /saude diz QUAL arquivo esta em uso.

Titulo 'Conferindo'

$saude = $null
for ($i = 1; $i -le 12; $i++) {
    try { $saude = Invoke-RestMethod -Uri "http://localhost:$PORTA/saude" -TimeoutSec 3; break }
    catch { Start-Sleep -Seconds 2 }
}

if (-not $saude) {
    Write-Host ''
    Write-Host "A API nao respondeu em http://localhost:$PORTA." -ForegroundColor Red
    Write-Host 'Para voltar a base de antes:' -ForegroundColor Yellow
    Write-Host ("  copie {0}" -f $guardada) -ForegroundColor Cyan
    Write-Host ("  por cima de {0}" -f $config) -ForegroundColor Cyan
    Write-Host '  e rode REINICIAR-API.cmd' -ForegroundColor Cyan
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

Write-Host ("  a API diz estar usando:  {0}" -f $saude.banco) -ForegroundColor Cyan
if ($saude.banco -ne "$nome.FDB") {
    Parar ("A API subiu usando {0}, e nao {1}.FDB. Confira ASPNETCORE_ENVIRONMENT no registro do servico." -f $saude.banco, $nome)
}

Titulo 'Base trocada'

Write-Host ("A Agenda agora usa:  {0}" -f $destino) -ForegroundColor Green
Write-Host ''
Write-Host ("A base de antes continua no disco:`n  {0}" -f $bancoDeAntes.Replace('/', '\')) -ForegroundColor Gray
Write-Host 'Nada foi apagado.' -ForegroundColor Gray
Write-Host ''
Write-Host 'AGORA SAIA E ENTRE DE NOVO NO APLICATIVO.' -ForegroundColor Yellow
Write-Host 'A sessao aberta foi assinada com a mesma chave e continua valendo, mas o' -ForegroundColor Yellow
Write-Host 'numero do usuario dentro dela e o da base ANTERIOR - nesta base ele pode' -ForegroundColor Yellow
Write-Host 'ser outra pessoa.' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Os usuarios e as senhas sao os do sistema antigo. Ninguem precisa trocar' -ForegroundColor Gray
Write-Host 'senha: quem ainda nao tem hash entra pela senha de sempre e o hash e' -ForegroundColor Gray
Write-Host 'gravado naquele momento.' -ForegroundColor Gray
Write-Host ''
Read-Host 'Pressione Enter para fechar'
