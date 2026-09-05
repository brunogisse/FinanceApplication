# =============================================================================
#  Atualizar a API ja instalada com o codigo atual
#  Nao rode este arquivo direto. De dois cliques em ATUALIZAR-API.cmd.
# =============================================================================
#
# Parar -> republicar -> subir -> conferir.
#
# Publicar sem parar o servico NAO funciona: o Windows mantem o executavel travado
# enquanto ele roda, e o "dotnet publish" falha no meio, deixando a pasta pela metade.
#
# A configuracao da instalacao (appsettings.Production.json, com o caminho do banco e a
# chave que assina as sessoes) e preservada pelo 1-publicar-api.ps1.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$NOME_SERVICO = 'AgendaFinanceiraApi'
$PORTA = 5199

function Titulo($texto) {
    Write-Host ''
    Write-Host ('=' * 60) -ForegroundColor Cyan
    Write-Host " $texto" -ForegroundColor Cyan
    Write-Host ('=' * 60) -ForegroundColor Cyan
    Write-Host ''
}

Titulo 'Atualizando a API instalada'

$servico = Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
if (-not $servico) {
    throw "O servico $NOME_SERVICO nao existe. Rode INSTALAR.cmd primeiro."
}

$executavel = Join-Path $PSScriptRoot 'publicado\AgendaFinanceira.Api.exe'

# =============================================================================
#  TUDO QUE PODE RECUSAR VEM ANTES DE PARAR O SERVICO
# =============================================================================
#
# Em 23/08/2026 este script parou o servico e SO ENTAO descobriu que nao tinha como
# publicar: fora rodado de uma copia solta da pasta 'instalacao', sem o codigo-fonte ao
# lado. Resultado: API fora do ar e um erro vermelho, por um motivo que daria para saber
# antes de encostar em nada.
#
# Regra: nada de derrubar o que funciona antes de provar que o substituto existe.

# 1. O codigo-fonte tem de estar ao lado. E o mesmo caminho que o 1-publicar-api.ps1 usa.
$projeto = Join-Path (Split-Path $PSScriptRoot -Parent) 'src\AgendaFinanceira.Api\AgendaFinanceira.Api.csproj'
if (-not (Test-Path $projeto)) {
    Write-Host ''
    Write-Host 'Este arquivo esta na pasta errada.' -ForegroundColor Red
    Write-Host ''
    Write-Host "  Rodando de:  $PSScriptRoot" -ForegroundColor Yellow
    Write-Host "  Procurei o projeto em:  $projeto" -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Ele so funciona na pasta "instalacao" que fica DENTRO do repositorio, ao lado' -ForegroundColor Yellow
    Write-Host 'da pasta "src" - normalmente:' -ForegroundColor Yellow
    Write-Host '    C:\PROGRAMAS\V OFICIAL\instalacao\ATUALIZAR-API.cmd' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Nada foi alterado: o servico continua no ar.' -ForegroundColor Green
    throw 'Rodado fora do repositorio. Nada foi alterado.'
}

# 2. A pasta que eu vou republicar tem de ser a que o SERVICO usa de verdade.
#
# Publicar numa copia "funciona" e nao muda nada: o servico segue com o binario velho e
# ninguem percebe ate um campo novo sumir em silencio. Foi assim que o parcelamento com
# valores ajustados gravou parcelas iguais durante horas.
$caminhoDoServico = (Get-CimInstance Win32_Service -Filter "Name='$NOME_SERVICO'").PathName.Trim('"')
if ($caminhoDoServico -and $executavel -and
    ($caminhoDoServico.TrimEnd('"') -ne $executavel)) {
    Write-Host ''
    Write-Host 'Esta pasta NAO e a que o servico usa.' -ForegroundColor Red
    Write-Host ''
    Write-Host "  O servico roda:  $caminhoDoServico" -ForegroundColor Yellow
    Write-Host "  Eu publicaria em: $executavel" -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Republicar aqui nao mudaria nada para o servico. Rode o ATUALIZAR-API.cmd que' -ForegroundColor Yellow
    Write-Host 'esta ao lado da pasta acima.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Nada foi alterado: o servico continua no ar.' -ForegroundColor Green
    throw 'Pasta diferente da que o servico usa. Nada foi alterado.'
}

# 3. O codigo compila? Um erro de compilacao com o servico ja parado deixa a API fora do ar
#    por um problema que nao tem nada a ver com a instalacao.
Write-Host 'Conferindo se o codigo compila antes de mexer no servico...' -ForegroundColor Cyan
dotnet build $projeto --configuration Release --nologo --verbosity quiet | Out-Host
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'O codigo NAO compila. Corrija os erros acima.' -ForegroundColor Red
    Write-Host 'Nada foi alterado: o servico continua no ar.' -ForegroundColor Green
    throw 'Compilacao falhou. Nada foi alterado.'
}
Write-Host '  compila.' -ForegroundColor Green

# A data do binario antes e depois e a prova mais simples de que a republicacao aconteceu.
$dataAntes = if (Test-Path $executavel) { (Get-Item $executavel).LastWriteTime } else { $null }
if ($dataAntes) {
    Write-Host ("Binario atual: {0:dd/MM/yyyy HH:mm:ss}" -f $dataAntes) -ForegroundColor DarkGray
}

# ------------------------------------------------------------------- parar
Write-Host "Parando $($servico.DisplayName)..." -ForegroundColor Cyan
Stop-Service -Name $NOME_SERVICO -Force
$servico.WaitForStatus('Stopped', '00:00:30')

# Conferir o EFEITO: WaitForStatus devolve quando o Windows diz "parado", mas o processo
# pode levar mais um instante para largar o arquivo.
$tentativas = 0
while ((Get-Process -Name 'AgendaFinanceira.Api' -ErrorAction SilentlyContinue) -and $tentativas -lt 10) {
    Start-Sleep -Milliseconds 500
    $tentativas++
}
Write-Host '  parado.' -ForegroundColor Green

# -------------------------------------------------------------- republicar
#
# A publicacao comeca apagando a pasta. Se ela falhar no meio, o servico fica parado sobre
# uma pasta incompleta - e subir assim seria pior do que continuar parado. Por isso o aviso
# diz o que fazer em vez de tentar levantar de qualquer jeito.
Write-Host ''
try {
    & (Join-Path $PSScriptRoot '1-publicar-api.ps1')
}
catch {
    Write-Host ''
    Write-Host 'A PUBLICACAO FALHOU. O servico esta PARADO.' -ForegroundColor Red
    Write-Host ("  {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ''
    Write-Host 'Corrija o erro acima e rode este arquivo de novo.' -ForegroundColor Yellow
    Write-Host 'A pasta publicado esta incompleta: subir o servico agora nao adianta.' -ForegroundColor Yellow
    throw
}

# -------------------------------------------------------------------- subir
Write-Host ''
Write-Host 'Subindo o servico...' -ForegroundColor Cyan
Start-Service -Name $NOME_SERVICO
(Get-Service -Name $NOME_SERVICO).WaitForStatus('Running', '00:00:30')
Write-Host '  no ar.' -ForegroundColor Green

# ---------------------------------------------------------------- conferir
#
# Conferir o EFEITO e nao o estado do servico: ele fica "Running" com a API morta dentro.
# Uma chamada que passa pelo banco prova mais.
Titulo 'Conferindo'

$ok = $false
for ($i = 1; $i -le 10; $i++) {
    try {
        $saude = Invoke-RestMethod -Uri "http://localhost:$PORTA/saude" -TimeoutSec 3
        Write-Host ("  responde: banco {0}" -f $saude.banco) -ForegroundColor Green
        $ok = $true
        break
    } catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $ok) {
    throw "A API nao respondeu em http://localhost:$PORTA depois de subir. Veja o Visualizador de Eventos."
}

# ---------------------------------------------------------- provar a troca
#
# Responder nao prova que o codigo e o novo: a API velha responde igualzinho. Duas provas:
# a data do binario mudou, e o contrato que ela publica traz o campo novo.
$dataDepois = (Get-Item $executavel).LastWriteTime
Write-Host ("  binario: {0:dd/MM/yyyy HH:mm:ss}" -f $dataDepois) -ForegroundColor Gray

if ($dataAntes -and $dataDepois -le $dataAntes) {
    throw ("O executavel NAO foi trocado: continua de {0:dd/MM/yyyy HH:mm:ss}. " -f $dataAntes) +
          'A publicacao nao substituiu os arquivos. Rode de novo e leia a saida do dotnet publish.'
}

try {
    $contrato = Invoke-RestMethod -Uri "http://localhost:$PORTA/swagger/v1/swagger.json" -TimeoutSec 10
    $parcelar = $contrato.components.schemas.ParcelarDto
    if ($parcelar.properties.PSObject.Properties.Name -contains 'valores') {
        Write-Host '  contrato: aceita parcelas com valores ajustados' -ForegroundColor Green
    } else {
        throw 'A API subiu, mas ainda publica o contrato ANTIGO de parcelamento (sem "valores"). ' +
              'Parcelar com valores diferentes gravaria parcelas iguais. Rode este arquivo de novo.'
    }
} catch [System.Net.WebException] {
    Write-Host '  contrato: nao consegui ler o swagger; conferindo so pela data.' -ForegroundColor Yellow
}

& (Join-Path $PSScriptRoot 'conferir-estado.ps1')

Write-Host ''
Write-Host 'API atualizada. Pode abrir o aplicativo.' -ForegroundColor Green
Write-Host ''
