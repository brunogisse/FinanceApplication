# =============================================================================
#  PASSO 2 - Instalar a API no notebook, como servico do Windows
#  Rode NO NOTEBOOK, no PowerShell como Administrador.
# =============================================================================
#
# O que ele faz:
#   1. Confere que o Firebird 2.5 esta instalado
#   2. Faz uma COPIA do banco indicado e trabalha so sobre ela
#   3. Acrescenta a coluna SENHA_HASH na copia (o Delphi ignora essa coluna)
#   4. Gera a chave que assina as sessoes, reaproveitando a existente
#   5. Registra a API como servico, iniciando junto com a maquina
#   6. Sobe o servico e confere que ele responde de verdade
#
# NADA aqui escreve no banco de origem. A copia e feita pelo arquivo, sem
# conectar na origem: conectar pelo servidor avanca os contadores de transacao
# no cabeçalho e altera a data do arquivo.
#
# Uso:
#   .\2-instalar-no-notebook.ps1 -BancoDeOrigem "C:\caminho\DADOS.FDB"

#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory = $true)]
    [string]$BancoDeOrigem,

    [string]$PastaDeTrabalho = 'C:\AgendaFinanceira',
    [int]$Porta = 5199
)

$ErrorActionPreference = 'Stop'

$NOME_SERVICO   = 'AgendaFinanceiraApi'
$ROTULO_SERVICO = 'Agenda Financeira - API'

$publicado  = Join-Path $PSScriptRoot 'publicado'
$executavel = Join-Path $publicado 'AgendaFinanceira.Api.exe'
$copia      = Join-Path $PastaDeTrabalho 'AGENDA_TESTE.FDB'

Write-Host ''
Write-Host '===============================================' -ForegroundColor Cyan
Write-Host ' Agenda Financeira - instalacao no notebook'    -ForegroundColor Cyan
Write-Host '===============================================' -ForegroundColor Cyan
Write-Host ''

# ------------------------------------------------------------- verificacoes
if (-not (Test-Path $executavel)) {
    throw "Nao encontrei $executavel. Rode antes o 1-publicar-api.ps1 na maquina de desenvolvimento e copie a pasta 'instalacao' inteira."
}
if (-not (Test-Path $BancoDeOrigem)) {
    throw "Nao encontrei o banco de origem em $BancoDeOrigem"
}

# O Firebird pode estar em mais de um lugar; nao supor o caminho.
$candidatos = @(
    'C:\Program Files\Firebird\Firebird_2_5\bin',
    'C:\Program Files (x86)\Firebird\Firebird_2_5\bin'
) | Where-Object { Test-Path (Join-Path $_ 'gbak.exe') }

if ($candidatos.Count -eq 0) {
    throw 'Firebird 2.5 nao encontrado. O sistema antigo usa esta mesma instalacao; se ele roda neste notebook, ela existe - confira o caminho e ajuste o script.'
}
$fb = $candidatos[0]
Write-Host "Firebird encontrado em: $fb" -ForegroundColor DarkGray

$origem = Get-Item $BancoDeOrigem
Write-Host ''
Write-Host 'Banco de origem:' -ForegroundColor Cyan
Write-Host ("  {0}" -f $origem.FullName)
Write-Host ("  {0:N1} MB, modificado em {1}" -f ($origem.Length / 1MB), $origem.LastWriteTime)
Write-Host ''
Write-Host 'Este script NAO escreve nele. A copia e feita pelo arquivo.' -ForegroundColor Green
Write-Host ''

# ------------------------------------------------------- copia de trabalho
New-Item -ItemType Directory -Force -Path $PastaDeTrabalho | Out-Null

if (Test-Path $copia) {
    # Destrutivo: mostrar o que existe hoje ANTES de perguntar. O nome parece certo
    # mesmo quando aponta para o lugar errado; a contagem e o que faz reconhecer.
    Write-Host 'Ja existe uma copia de trabalho:' -ForegroundColor Yellow
    $atual = Get-Item $copia
    Write-Host ("  {0} - {1:N1} MB, modificado em {2}" -f $atual.FullName, ($atual.Length / 1MB), $atual.LastWriteTime)

    $sql = Join-Path $env:TEMP 'agenda-contagem.sql'
    @'
SET LIST ON;
SELECT COUNT(*) AS LANCAMENTOS FROM REGISTRO_DE_GASTOS;
SELECT COUNT(*) AS USUARIOS FROM LOGIN;
'@ | Set-Content -Path $sql -Encoding utf8

    $saida = Join-Path $env:TEMP 'agenda-contagem.txt'
    & "$fb\isql.exe" -b -user SYSDBA -password masterkey -i $sql -o $saida "localhost:$copia" 2>&1 | Out-Host
    if (Test-Path $saida) { Get-Content $saida | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "  $_" } }

    Write-Host ''
    $resposta = Read-Host 'Apagar esta copia e gerar uma nova a partir da origem? (digite SIM para confirmar)'
    if ($resposta -ne 'SIM') { Write-Host 'Cancelado. Nada foi alterado.' -ForegroundColor Yellow; exit 1 }
    Remove-Item $copia -Force
}

Write-Host 'Copiando o arquivo do banco...' -ForegroundColor Cyan
$bruta = Join-Path $PastaDeTrabalho 'origem-copiada.FDB'
Copy-Item $origem.FullName $bruta -Force

# Backup e restore sobre a COPIA, nunca sobre a origem. Isto reorganiza as paginas e
# entrega um arquivo limpo, alem de provar que o banco esta integro.
Write-Host 'Gerando a copia de trabalho por gbak (backup + restore)...' -ForegroundColor Cyan
$fbk = Join-Path $PastaDeTrabalho 'agenda.fbk'

& "$fb\gbak.exe" -b -user SYSDBA -password masterkey "localhost:$bruta" $fbk 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "gbak (backup) falhou com codigo $LASTEXITCODE." }

& "$fb\gbak.exe" -c -user SYSDBA -password masterkey $fbk "localhost:$copia" 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "gbak (restore) falhou com codigo $LASTEXITCODE." }

if (-not (Test-Path $copia)) { throw "O gbak terminou sem erro, mas $copia nao existe." }
Remove-Item $bruta -Force

# --------------------------------------------------- coluna de convivencia
# O Delphi ignora colunas que nao conhece - ver ADR 0010. Sem ela a autenticacao
# da API nao roda.
Write-Host ''
Write-Host 'Acrescentando a coluna SENHA_HASH na copia...' -ForegroundColor Cyan

$sqlColuna = Join-Path $env:TEMP 'agenda-coluna.sql'
@'
ALTER TABLE LOGIN ADD SENHA_HASH VARCHAR(200);
COMMIT;
'@ | Set-Content -Path $sqlColuna -Encoding utf8

$saidaColuna = Join-Path $env:TEMP 'agenda-coluna.txt'
# -b (bail): sem ele o isql segue executando depois de um erro. Nao e -v ON_ERROR_STOP,
# que e do psql e o isql nao conhece.
& "$fb\isql.exe" -b -user SYSDBA -password masterkey -i $sqlColuna -o $saidaColuna "localhost:$copia" 2>&1 | Out-Host

# Conferir o EFEITO, nao so o codigo de saida: a coluna pode ja existir de uma
# instalacao anterior, e nesse caso o erro e esperado.
$sqlConfere = Join-Path $env:TEMP 'agenda-confere.sql'
@'
SET LIST ON;
SELECT COUNT(*) AS TEM_A_COLUNA FROM RDB$RELATION_FIELDS
 WHERE TRIM(RDB$RELATION_NAME) = 'LOGIN' AND TRIM(RDB$FIELD_NAME) = 'SENHA_HASH';
'@ | Set-Content -Path $sqlConfere -Encoding utf8

$saidaConfere = Join-Path $env:TEMP 'agenda-confere.txt'
& "$fb\isql.exe" -b -user SYSDBA -password masterkey -i $sqlConfere -o $saidaConfere "localhost:$copia" 2>&1 | Out-Null

$temColuna = (Get-Content $saidaConfere -Raw) -match 'TEM_A_COLUNA\s+1'
if (-not $temColuna) {
    throw "A coluna SENHA_HASH nao existe na copia depois do ALTER TABLE. Veja $saidaColuna"
}
Write-Host 'Coluna SENHA_HASH confirmada na copia.' -ForegroundColor Green

# ------------------------------------------------------------------ chave
# A API se recusa a subir sem ela. Numa reinstalacao a chave existente e
# reaproveitada: gerar outra invalidaria as sessoes de todo mundo.
$configuracao = Join-Path $publicado 'appsettings.Production.json'
$chave = $null

if (Test-Path $configuracao) {
    try {
        $anterior = Get-Content $configuracao -Raw | ConvertFrom-Json
        if ($anterior.Jwt.Chave -and $anterior.Jwt.Chave.Length -ge 32) {
            $chave = $anterior.Jwt.Chave
            Write-Host 'Reaproveitando a chave de assinatura ja existente.' -ForegroundColor DarkGray
        }
    } catch {
        Write-Host 'Configuracao anterior ilegivel; gerando chave nova.' -ForegroundColor Yellow
    }
}

if (-not $chave) {
    # Aleatoria de verdade: Get-Random nao serve para segredo - quem adivinhasse a
    # chave forjaria um acesso de administrador.
    $bytes = New-Object byte[] 48
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $chave = [Convert]::ToBase64String($bytes)
    Write-Host 'Chave de assinatura gerada.' -ForegroundColor DarkGray
}

$config = [ordered]@{
    Banco = [ordered]@{ Caminho = $copia.Replace('\', '/') }
    Cors  = [ordered]@{ Origens = @('http://localhost:4200', 'null') }
    Jwt   = [ordered]@{ Chave = $chave }
    Urls  = "http://localhost:$Porta"
}

# WriteAllText com UTF8 sem BOM: Set-Content grava na codificacao ANSI do sistema.
[System.IO.File]::WriteAllText(
    $configuracao,
    ($config | ConvertTo-Json -Depth 6),
    (New-Object System.Text.UTF8Encoding $false))

Write-Host "Configuracao gravada em $configuracao" -ForegroundColor DarkGray

# ---------------------------------------------------------------- servico
Write-Host ''
Write-Host 'Registrando o servico do Windows...' -ForegroundColor Cyan

$existente = Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
if ($existente) {
    Write-Host 'Servico ja existe; parando e removendo para recriar.' -ForegroundColor DarkGray
    if ($existente.Status -ne 'Stopped') { Stop-Service -Name $NOME_SERVICO -Force }
    sc.exe delete $NOME_SERVICO | Out-Host
    Start-Sleep -Seconds 2
}

sc.exe create $NOME_SERVICO binPath= "`"$executavel`"" DisplayName= "`"$ROTULO_SERVICO`"" start= auto | Out-Host
if ($LASTEXITCODE -ne 0) { throw "sc.exe create falhou com codigo $LASTEXITCODE." }

sc.exe description $NOME_SERVICO 'API do sistema de contas a pagar do grupo Juliatti de Carvalho.' | Out-Host

# Se cair, tenta subir de novo em vez de ficar fora do ar ate alguem perceber.
sc.exe failure $NOME_SERVICO reset= 86400 actions= restart/60000/restart/60000/restart/120000 | Out-Host

# O servico precisa saber que e Production para ler o appsettings.Production.json.
$chaveRegistro = "HKLM:\SYSTEM\CurrentControlSet\Services\$NOME_SERVICO"
Set-ItemProperty -Path $chaveRegistro -Name 'Environment' `
    -Value @("ASPNETCORE_ENVIRONMENT=Production") -Type MultiString

Write-Host 'Iniciando o servico...' -ForegroundColor Cyan
Start-Service -Name $NOME_SERVICO

# ------------------------------------------------------------- conferencia
# Conferir o EFEITO, nao o codigo: um servico pode ficar "Running" e a API dentro
# dele ter falhado ao subir.
Write-Host 'Conferindo se a API responde...' -ForegroundColor Cyan
$respondeu = $false
for ($i = 1; $i -le 30; $i++) {
    Start-Sleep -Seconds 1
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:$Porta/saude" -TimeoutSec 2
        Write-Host ''
        Write-Host "  API no ar. Banco em uso: $($r.banco)" -ForegroundColor Green
        $respondeu = $true
        break
    } catch { }
}

if (-not $respondeu) {
    Write-Host ''
    Write-Host 'A API NAO respondeu em 30 segundos.' -ForegroundColor Red
    Write-Host 'Veja o Visualizador de Eventos > Logs do Windows > Aplicativo.' -ForegroundColor Yellow
    Write-Host "Ou rode a API na mao para ver a mensagem: `"$executavel`"" -ForegroundColor Yellow
    throw 'Instalacao incompleta: o servico subiu mas a API nao respondeu.'
}

Write-Host ''
Write-Host '===============================================' -ForegroundColor Green
Write-Host ' Pronto.' -ForegroundColor Green
Write-Host '===============================================' -ForegroundColor Green
Write-Host ''
Write-Host "  Servico:  $ROTULO_SERVICO (inicia junto com a maquina)"
Write-Host "  Endereco: http://localhost:$Porta"
Write-Host "  Banco:    $copia"
Write-Host ''
Write-Host 'Agora instale o cliente:' -ForegroundColor Cyan
Write-Host '  AgendaFinanceira-Instalador-1.0.0.exe  (duplo clique, sem elevacao)'
Write-Host ''
Write-Host 'Esta e uma COPIA. O que for lancado aqui NAO aparece no sistema antigo.' -ForegroundColor Yellow
Write-Host ''
