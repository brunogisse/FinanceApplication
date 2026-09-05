# =============================================================================
#  Apontar a API para QUALQUER banco, a qualquer momento
#  Nao rode este arquivo direto. De dois cliques em APONTAR-PARA-BASE.cmd.
# =============================================================================
#
#   .\apontar-para.ps1 -Banco "D:\bases\QUALQUER.FDB"
#   .\apontar-para.ps1                      -> abre uma janela para escolher
#
# Troca uma linha do appsettings.Production.json, reinicia o servico e PROVA que a
# API subiu usando o banco pedido.
#
# ISTO NAO E UMA LIBERDADE NOVA, E O ATALHO PARA UMA QUE SEMPRE EXISTIU. O
# appsettings.Production.json sempre foi o .ini ao lado do executavel: uma linha
# dizendo onde o banco esta. O que faltava era nao precisar editar JSON na mao -
# uma virgula a mais ali derruba a API na proxima vez que ela subir.
#
# DIFERENCA PARA O trocar-base.ps1
#
#   trocar-base.ps1   pega o .FDB do PACOTE, gera uma copia de trabalho por gbak
#                     e aponta para ela. E para instalar dados novos.
#   apontar-para.ps1  aponta para um banco QUE JA EXISTE, sem copiar nada.
#                     E para alternar entre bases que voce ja tem.

#Requires -RunAsAdministrator

param(
    [string]$Banco = '',
    [switch]$SemReiniciar
)

$ErrorActionPreference = 'Stop'

$NOME_SERVICO = 'AgendaFinanceiraApi'
$PORTA        = 5199
$fb           = 'C:\Program Files\Firebird\Firebird_2_5\bin'

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
    Write-Host 'Nada foi alterado. A API continua como estava.' -ForegroundColor Green
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

Titulo 'Apontar a API para outro banco'

# ------------------------------------------------------------------- servico
$servico = Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
if (-not $servico) { Parar "O servico $NOME_SERVICO nao existe nesta maquina." }

$exe    = (Get-CimInstance Win32_Service -Filter "Name='$NOME_SERVICO'").PathName.Trim('"')
$config = Join-Path (Split-Path $exe -Parent) 'appsettings.Production.json'
if (-not (Test-Path $config)) { Parar "Nao achei a configuracao em $config" }

$j = Get-Content $config -Raw | ConvertFrom-Json
$antes = $j.Banco.Caminho
Write-Host ("Banco de agora:  {0}" -f $antes) -ForegroundColor Gray

# --------------------------------------------------------------- qual banco
if (-not $Banco) {
    Add-Type -AssemblyName System.Windows.Forms
    $caixa = New-Object System.Windows.Forms.OpenFileDialog
    $caixa.Title  = 'Escolha o banco Firebird que a API deve usar'
    $caixa.Filter = 'Banco Firebird (*.FDB)|*.FDB|Todos os arquivos (*.*)|*.*'
    $inicial = Split-Path $antes.Replace('/', '\') -Parent
    if (Test-Path $inicial) { $caixa.InitialDirectory = $inicial }
    if ($caixa.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host 'Cancelado.' -ForegroundColor Yellow
        exit 0
    }
    $Banco = $caixa.FileName
}

$Banco = $Banco.Trim('"').Trim()

# Caminho de servidor remoto ("maquina:C:\caminho") nao da para conferir daqui.
# Um caminho local tem a letra do disco na posicao 2; qualquer outro ':' indica servidor.
$ehRemoto = ($Banco -match '^[^\\/]+:[\\/]' -and $Banco -notmatch '^[A-Za-z]:[\\/]')

if ($ehRemoto) {
    Write-Host ''
    Write-Host 'Caminho de SERVIDOR. Nao consigo conferir o arquivo daqui.' -ForegroundColor Yellow
    Write-Host 'A prova vai ser a API subir e alcancar o banco.' -ForegroundColor Yellow
} else {
    if (-not (Test-Path $Banco)) { Parar "Nao achei o arquivo: $Banco" }

    $arq = Get-Item $Banco
    Write-Host ''
    Write-Host ("Banco escolhido: {0}" -f $arq.FullName) -ForegroundColor Cyan
    Write-Host ("                 {0:N2} MB, modificado em {1}" -f ($arq.Length / 1MB), $arq.LastWriteTime)

    # gstat -h le o ARQUIVO, sem servidor e sem escrever nada.
    if (Test-Path $fb) {
        $cab = & "$fb\gstat.exe" -h $arq.FullName 2>&1
        $ods = ($cab | Select-String -Pattern 'ODS version\s+(.+)').Matches.Groups[1].Value.Trim()
        if (-not $ods) { Parar "Isto nao parece um banco Firebird: $($arq.FullName)" }
        Write-Host ("                 ODS {0}" -f $ods)
        if ($ods -notlike '11.*') { Parar "ODS $ods nao e do Firebird 2.5. A API nao abriria." }
    }

    if ($arq.FullName -eq $antes.Replace('/', '\')) {
        Write-Host ''
        Write-Host 'E o mesmo banco que ja esta em uso. Nada a fazer.' -ForegroundColor Yellow
        Read-Host 'Pressione Enter para fechar'
        exit 0
    }
}

# ------------------------------------------------------- coluna de convivencia
#
# Sem SENHA_HASH a autenticacao nao roda, e o erro apareceria como "usuario ou senha
# invalidos" para todo mundo - uma mensagem que manda procurar no lugar errado.
if (-not $ehRemoto -and (Test-Path $fb)) {
    $sql = Join-Path $env:TEMP 'apontar-coluna.sql'
    $out = Join-Path $env:TEMP 'apontar-coluna.txt'
    $consulta = "SET LIST ON;`nSELECT COUNT(*) AS TEM FROM RDB`$RELATION_FIELDS WHERE TRIM(RDB`$RELATION_NAME) = 'LOGIN' AND TRIM(RDB`$FIELD_NAME) = 'SENHA_HASH';`n"
    [System.IO.File]::WriteAllText($sql, $consulta, (New-Object System.Text.UTF8Encoding $false))

    # O isql -o ACRESCENTA ao arquivo. Apagar antes, sempre.
    if (Test-Path $out) { Remove-Item $out -Force }
    & "$fb\isql.exe" -b -user SYSDBA -password masterkey -i $sql -o $out "localhost:$Banco" 2>&1 | Out-Null
    $texto = if (Test-Path $out) { Get-Content $out -Raw } else { '' }
    Remove-Item $sql, $out -Force -ErrorAction SilentlyContinue

    if ($texto -match 'TEM\s+0') {
        Write-Host ''
        Write-Host 'Este banco NAO tem a coluna SENHA_HASH.' -ForegroundColor Yellow
        Write-Host 'Sem ela a autenticacao nao roda, e todo login vira "usuario ou senha invalidos".'
        Write-Host 'A coluna e aditiva: o Delphi ignora colunas que nao conhece (ADR 0010).'
        Write-Host ''
        $r = Read-Host 'Criar a coluna agora? (digite SIM para confirmar)'
        if ($r -ne 'SIM') { Parar 'Sem a coluna a API nao serve para nada neste banco.' }

        $sql2 = Join-Path $env:TEMP 'apontar-alter.sql'
        $out2 = Join-Path $env:TEMP 'apontar-alter.txt'
        [System.IO.File]::WriteAllText($sql2, "ALTER TABLE LOGIN ADD SENHA_HASH VARCHAR(200);`nCOMMIT;`n", (New-Object System.Text.UTF8Encoding $false))
        if (Test-Path $out2) { Remove-Item $out2 -Force }
        & "$fb\isql.exe" -b -user SYSDBA -password masterkey -i $sql2 -o $out2 "localhost:$Banco" 2>&1 | Out-Null
        $saida2 = if (Test-Path $out2) { Get-Content $out2 -Raw } else { '' }
        Remove-Item $sql2, $out2 -Force -ErrorAction SilentlyContinue

        # Conferir o EFEITO: o ALTER pode "passar" e a coluna nao estar la.
        if (Test-Path $out) { Remove-Item $out -Force }
        [System.IO.File]::WriteAllText($sql, $consulta, (New-Object System.Text.UTF8Encoding $false))
        & "$fb\isql.exe" -b -user SYSDBA -password masterkey -i $sql -o $out "localhost:$Banco" 2>&1 | Out-Null
        $texto2 = if (Test-Path $out) { Get-Content $out -Raw } else { '' }
        Remove-Item $sql, $out -Force -ErrorAction SilentlyContinue

        if ($texto2 -notmatch 'TEM\s+1') { Parar "O ALTER TABLE nao criou a coluna. Saida:`n$saida2" }
        Write-Host '  coluna criada e confirmada.' -ForegroundColor Green
    } else {
        Write-Host '  coluna SENHA_HASH: presente.' -ForegroundColor Green
    }
}

# ------------------------------------------------------------------- gravar
Titulo 'Gravando'

# A configuracao de antes fica guardada ao lado, com a hora no nome: assim varias
# trocas no mesmo dia nao apagam o retrato anterior.
$carimbo = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$guardada = "$config.antes-de-$carimbo"
Copy-Item $config $guardada -Force
Write-Host ("Configuracao anterior guardada em:`n  {0}" -f $guardada) -ForegroundColor DarkGray

$j.Banco.Caminho = $Banco.Replace('\', '/')
# WriteAllText com UTF8 sem BOM: Set-Content gravaria na codificacao ANSI do sistema.
[System.IO.File]::WriteAllText($config, ($j | ConvertTo-Json -Depth 10),
                               (New-Object System.Text.UTF8Encoding $false))

$v = Get-Content $config -Raw | ConvertFrom-Json
if ($v.Banco.Caminho -ne $Banco.Replace('\', '/')) { Parar 'Falhei ao gravar a configuracao.' }
if (-not $v.Jwt.Chave -or $v.Jwt.Chave.Length -lt 32) {
    Copy-Item $guardada $config -Force
    Parar 'A gravacao perdeu a chave de assinatura. A configuracao anterior foi devolvida.'
}
Write-Host 'Gravado, com a chave de assinatura preservada.' -ForegroundColor Green

if ($SemReiniciar) {
    Write-Host ''
    Write-Host 'Nao reiniciei, a pedido. A troca so vale depois de reiniciar o servico:' -ForegroundColor Yellow
    Write-Host '    REINICIAR-API.cmd' -ForegroundColor Cyan
    Read-Host 'Pressione Enter para fechar'
    exit 0
}

# ---------------------------------------------------------------- reiniciar
Write-Host ''
Write-Host 'Reiniciando o servico...' -ForegroundColor Cyan
if ((Get-Service $NOME_SERVICO).Status -ne 'Stopped') {
    Stop-Service $NOME_SERVICO -Force
    (Get-Service $NOME_SERVICO).WaitForStatus('Stopped', '00:00:30')
}
# O Windows diz "parado" antes de o processo largar os arquivos.
$n = 0
while ((Get-Process 'AgendaFinanceira.Api' -ErrorAction SilentlyContinue) -and $n -lt 20) {
    Start-Sleep -Milliseconds 500; $n++
}
Start-Service $NOME_SERVICO
(Get-Service $NOME_SERVICO).WaitForStatus('Running', '00:00:30')

# ------------------------------------------------------------------ conferir
#
# O servico fica "Running" com a API morta dentro, e a API responde igualzinho
# apontando para o banco errado. O /saude diz QUAL arquivo esta em uso.
Titulo 'Conferindo'

$saude = $null
for ($i = 1; $i -le 12; $i++) {
    try { $saude = Invoke-RestMethod "http://localhost:$PORTA/saude" -TimeoutSec 3; break }
    catch { Start-Sleep -Seconds 2 }
}

if (-not $saude) {
    Write-Host ''
    Write-Host "A API nao respondeu em http://localhost:$PORTA." -ForegroundColor Red
    Write-Host 'Para voltar ao banco de antes:' -ForegroundColor Yellow
    Write-Host ("  copie {0}" -f $guardada) -ForegroundColor Cyan
    Write-Host ("  por cima de {0}" -f $config) -ForegroundColor Cyan
    Write-Host '  e rode REINICIAR-API.cmd' -ForegroundColor Cyan
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

$esperado = Split-Path $Banco.Replace('/', '\') -Leaf
Write-Host ("  a API diz estar usando:  {0}" -f $saude.banco) -ForegroundColor Cyan
Write-Host ("  voce pediu:              {0}" -f $esperado) -ForegroundColor Cyan

if ($saude.banco -ne $esperado) {
    Parar "A API subiu usando outro banco. Confira ASPNETCORE_ENVIRONMENT no registro do servico."
}

Titulo 'Pronto'

Write-Host ("De   {0}" -f $antes) -ForegroundColor Gray
Write-Host ("Para {0}" -f $j.Banco.Caminho) -ForegroundColor Green
Write-Host ''
Write-Host 'SAIA E ENTRE DE NOVO NO APLICATIVO.' -ForegroundColor Yellow
Write-Host 'A sessao aberta guarda o numero do usuario do banco ANTERIOR, e noutro' -ForegroundColor Yellow
Write-Host 'banco aquele numero pode ser de outra pessoa.' -ForegroundColor Yellow
Write-Host ''
Read-Host 'Pressione Enter para fechar'
