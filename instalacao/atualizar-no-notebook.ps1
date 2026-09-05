# =============================================================================
#  Atualizar uma instalacao que JA EXISTE, sem encostar nos dados
#  Nao rode este arquivo direto. De dois cliques em ATUALIZAR.cmd.
# =============================================================================
#
# Para que serve: a maquina ja tem a Agenda instalada e funcionando, e chegou uma
# versao nova. Aqui a API passa a rodar o codigo novo e o banco de trabalho fica
# exatamente como estava.
#
# POR QUE ISTO PRECISOU EXISTIR
#
# Ate 25/08/2026 nao havia caminho de atualizacao numa maquina sem o codigo-fonte:
#
#   - INSTALAR.cmd serve para a PRIMEIRA vez. Rodado de novo, ele encontra a copia
#     de trabalho e pergunta se pode apaga-la. Digitando SIM, os lancamentos feitos
#     desde a instalacao vao embora; digitando qualquer outra coisa ele SAI, e a API
#     tambem nao e atualizada. Nenhuma das duas saidas serve.
#
#   - ATUALIZAR-API.cmd republica a partir do codigo-fonte, e so funciona dentro do
#     repositorio. No notebook nao existe pasta 'src'.
#
# COMO ESTE FUNCIONA
#
# O servico deixa de apontar para a pasta antiga e passa a apontar para a pasta NOVA,
# que veio neste pacote. Nada e sobrescrito: por isso nao ha risco de o arquivo estar
# travado pelo servico em execucao, que e o jeito classico de uma atualizacao morrer
# no meio e deixar a pasta pela metade.
#
# A configuracao da instalacao - o caminho do banco e a chave que assina as sessoes -
# e lida da pasta antiga e levada para a nova. Gerar chave nova derrubaria a sessao de
# todo mundo sem necessidade, e um caminho de banco errado faria a API subir apontando
# para o lugar errado.
#
# ESTE ARQUIVO NAO ENCOSTA NO BANCO. Nem na copia de trabalho, nem na origem.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$NOME_SERVICO   = 'AgendaFinanceiraApi'
$ROTULO_SERVICO = 'Agenda Financeira - API'
$PORTA          = 5199

function Titulo($texto) {
    Write-Host ''
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host " $texto" -ForegroundColor Cyan
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host ''
}

function Parar($mensagem) {
    Write-Host ''
    Write-Host $mensagem -ForegroundColor Red
    Write-Host ''
    Write-Host 'Nada foi alterado.' -ForegroundColor Green
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

Titulo 'Atualizar a Agenda Financeira'

# =============================================================================
#  TUDO QUE PODE RECUSAR VEM ANTES DE PARAR O SERVICO
# =============================================================================
#
# A regra e a mesma do ATUALIZAR-API.cmd, e ela nasceu de um estrago real em
# 23/08/2026: o script parou o servico e SO ENTAO descobriu que nao tinha como
# terminar. Ficou a API fora do ar por um motivo que dava para saber antes de
# encostar em nada.

# ---------------------------------------------------------- 1. da rede, nao
#
# `StartsWith` e nao `-like`: no curinga do PowerShell a barra invertida NAO e
# escape (o escape e a crase), entao '\\\\*' procura QUATRO barras e nunca casa.
if ($PSScriptRoot.StartsWith('\\')) {
    Parar @"
Esta pasta esta na REDE, e a atualizacao nao pode rodar de la.

  Rodando de:  $PSScriptRoot

O servico passaria a apontar para um caminho de rede. Bastaria o outro computador
desligar para a API parar de subir, sem dizer por que.

Copie a pasta INTEIRA para o disco local - por exemplo C:\AgendaNova - e rode dali.
"@
}

# --------------------------------------------------- 2. a versao nova existe
$novaPasta = Join-Path $PSScriptRoot 'publicado'
$novoExe   = Join-Path $novaPasta 'AgendaFinanceira.Api.exe'

if (-not (Test-Path $novoExe)) {
    Parar @"
Nao achei a versao nova da API.

  Procurei em:  $novoExe

Este arquivo tem de ficar dentro da pasta 'instalacao' do pacote, ao lado da pasta
'publicado'. Se voce copiou so este arquivo, copie o pacote inteiro.
"@
}

# -------------------------------------------- 3. ja existe instalacao aqui?
$servico = Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
if (-not $servico) {
    Parar @"
Esta maquina ainda NAO tem a Agenda Financeira instalada.

Este arquivo serve para atualizar uma instalacao que ja existe. Para instalar pela
primeira vez, use:

    instalacao\INSTALAR.cmd

Ele instala tudo do zero, inclusive o banco.
"@
}

Write-Host ("Servico encontrado: {0} ({1})" -f $servico.DisplayName, $servico.Status) -ForegroundColor Green

# ------------------------------------------- 4. onde esta a versao instalada
$caminhoAtual = (Get-CimInstance Win32_Service -Filter "Name='$NOME_SERVICO'").PathName.Trim('"')
$pastaAtual   = Split-Path $caminhoAtual -Parent

Write-Host ("Versao instalada hoje:  {0}" -f $pastaAtual) -ForegroundColor Gray
Write-Host ("Versao nova:            {0}" -f $novaPasta) -ForegroundColor Gray

if ($pastaAtual -eq $novaPasta) {
    Parar @"
A versao nova esta na MESMA pasta que o servico ja usa.

  $novaPasta

Isso quer dizer que o pacote foi copiado por cima da instalacao que esta rodando -
e o Windows nao deixa substituir o executavel de um servico no ar, entao a copia
provavelmente ficou pela metade.

Copie o pacote novo para uma pasta NOVA (por exemplo C:\AgendaNova) e rode dali.
A pasta antiga continua intacta ate voce apagar.
"@
}

# ----------------------------------------- 5. a configuracao da instalacao
#
# Ela guarda o caminho do banco e a chave que assina as sessoes. Sem ela a API se
# recusa a subir - o que e proposital, mas aqui seria uma parada evitavel.
$configAtual = Join-Path $pastaAtual 'appsettings.Production.json'

if (-not (Test-Path $configAtual)) {
    Parar @"
A instalacao atual esta sem o arquivo de configuracao.

  Procurei em:  $configAtual

Sem ele eu nao sei qual banco a API usa nem qual e a chave que assina as sessoes, e
chutar qualquer um dos dois seria pior do que parar aqui.

Nesse caso o caminho e reinstalar com INSTALAR.cmd.
"@
}

try {
    $config = Get-Content $configAtual -Raw | ConvertFrom-Json
} catch {
    Parar "Nao consegui ler $configAtual. O arquivo parece corrompido: $($_.Exception.Message)"
}

if (-not $config.Jwt.Chave -or $config.Jwt.Chave.Length -lt 32) {
    Parar "A configuracao em $configAtual esta sem a chave de assinatura das sessoes."
}

$bancoEmUso = $config.Banco.Caminho
if (-not $bancoEmUso) {
    Parar "A configuracao em $configAtual nao diz qual banco a API usa."
}

# O caminho vai gravado com barras normais no JSON; no disco procura-se com as do Windows.
$bancoNoDisco = $bancoEmUso.Replace('/', '\')
if (-not (Test-Path $bancoNoDisco)) {
    Parar @"
A configuracao aponta para um banco que nao existe mais:

  $bancoNoDisco

Subir a API assim so trocaria um problema por outro. Confira se o arquivo foi movido
ou renomeado antes de continuar.
"@
}

$tamanho = [Math]::Round((Get-Item $bancoNoDisco).Length / 1MB, 1)
Write-Host ''
Write-Host 'Configuracao que sera PRESERVADA:' -ForegroundColor Cyan
Write-Host ("  banco:   {0} ({1:N1} MB)" -f $bancoNoDisco, $tamanho)
Write-Host  '  chave:   a mesma de hoje (as sessoes abertas continuam valendo)'
Write-Host ''
Write-Host 'O banco NAO sera tocado por este arquivo.' -ForegroundColor Green

# =============================================================================
#  Daqui para baixo, altera
# =============================================================================

Titulo 'Trocando a versao'

# A configuracao vai para a pasta nova ANTES de mexer no servico: se falhar aqui, o
# servico continua no ar sobre a pasta antiga.
Copy-Item $configAtual (Join-Path $novaPasta 'appsettings.Production.json') -Force
if (-not (Test-Path (Join-Path $novaPasta 'appsettings.Production.json'))) {
    Parar 'Falhei ao levar a configuracao para a pasta nova.'
}
Write-Host 'Configuracao levada para a pasta nova.' -ForegroundColor Green

# ------------------------------------------------------------------- parar
Write-Host 'Parando o servico...' -ForegroundColor Cyan
if ($servico.Status -ne 'Stopped') {
    Stop-Service -Name $NOME_SERVICO -Force
    $servico.WaitForStatus('Stopped', '00:00:30')
}

# Conferir o EFEITO: o Windows diz "parado" antes de o processo largar os arquivos.
$tentativas = 0
while ((Get-Process -Name 'AgendaFinanceira.Api' -ErrorAction SilentlyContinue) -and $tentativas -lt 20) {
    Start-Sleep -Milliseconds 500
    $tentativas++
}
Write-Host '  parado.' -ForegroundColor Green

# ------------------------------------------------------ apontar para a nova
Write-Host 'Reapontando o servico para a versao nova...' -ForegroundColor Cyan

sc.exe delete $NOME_SERVICO | Out-Host
Start-Sleep -Seconds 2

sc.exe create $NOME_SERVICO binPath= "`"$novoExe`"" DisplayName= "`"$ROTULO_SERVICO`"" start= auto | Out-Host
if ($LASTEXITCODE -ne 0) { throw "sc.exe create falhou com codigo $LASTEXITCODE." }

sc.exe description $NOME_SERVICO 'API do sistema de contas a pagar do grupo Juliatti de Carvalho.' | Out-Host
sc.exe failure $NOME_SERVICO reset= 86400 actions= restart/60000/restart/60000/restart/120000 | Out-Host

# Sem isto a API le o appsettings.json de desenvolvimento e aponta para outro banco.
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$NOME_SERVICO" `
    -Name 'Environment' -Value @("ASPNETCORE_ENVIRONMENT=Production") -Type MultiString

Write-Host 'Subindo o servico...' -ForegroundColor Cyan
Start-Service -Name $NOME_SERVICO
(Get-Service -Name $NOME_SERVICO).WaitForStatus('Running', '00:00:30')
Write-Host '  no ar.' -ForegroundColor Green

# =============================================================================
#  Conferir o EFEITO, nao o estado
# =============================================================================
#
# O servico fica "Running" com a API morta dentro. Uma chamada que passa pelo banco
# prova mais do que o estado do servico.

Titulo 'Conferindo'

$respondeu = $false
for ($i = 1; $i -le 12; $i++) {
    try {
        $saude = Invoke-RestMethod -Uri "http://localhost:$PORTA/saude" -TimeoutSec 3
        Write-Host ("  a API responde, e alcanca o banco: {0}" -f $saude.banco) -ForegroundColor Green
        $respondeu = $true
        break
    } catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $respondeu) {
    Write-Host ''
    Write-Host "A API nao respondeu em http://localhost:$PORTA depois de subir." -ForegroundColor Red
    Write-Host ''
    Write-Host 'A pasta antiga continua intacta. Para voltar ao que era, rode:' -ForegroundColor Yellow
    Write-Host ("  sc.exe delete $NOME_SERVICO") -ForegroundColor Cyan
    Write-Host ("  sc.exe create $NOME_SERVICO binPath= `"{0}`" start= auto" -f $caminhoAtual) -ForegroundColor Cyan
    Write-Host ''
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

# Responder nao prova que o codigo e o novo: a versao antiga responde igualzinho.
# O contrato publicado traz um campo que so existe na versao nova.
try {
    $contrato = Invoke-RestMethod -Uri "http://localhost:$PORTA/swagger/v1/swagger.json" -TimeoutSec 10
    $parcelar = $contrato.components.schemas.ParcelarDto
    if ($parcelar.properties.PSObject.Properties.Name -contains 'valores') {
        Write-Host '  e a versao nova mesmo: aceita parcelas com valores ajustados' -ForegroundColor Green
    } else {
        Write-Host ''
        Write-Host 'A API subiu, mas publica o contrato ANTIGO de parcelamento.' -ForegroundColor Red
        Write-Host 'Parcelar com valores diferentes gravaria parcelas iguais, em silencio.' -ForegroundColor Red
        Write-Host 'Confira se a pasta "publicado" deste pacote e mesmo a nova.' -ForegroundColor Yellow
        Read-Host 'Pressione Enter para fechar'
        exit 1
    }
} catch [System.Net.WebException] {
    Write-Host '  nao consegui ler o contrato; a API responde e alcanca o banco.' -ForegroundColor Yellow
}

# ------------------------------------------------------------------- fim
Titulo 'API atualizada'

Write-Host 'Falta o aplicativo. De dois cliques em:' -ForegroundColor Cyan
Write-Host ''
Write-Host '    AgendaFinanceira-Instalador-1.0.0.exe' -ForegroundColor White
Write-Host ''
Write-Host 'Ele fica na pasta de cima, junto do LEIA-ME. Instala por cima da versao'
Write-Host 'anterior, sem pedir nada, e o que estava configurado continua valendo.'
Write-Host ''
Write-Host ("A pasta antiga continua no disco, intacta:") -ForegroundColor Gray
Write-Host ("    {0}" -f (Split-Path $pastaAtual -Parent)) -ForegroundColor Gray
Write-Host 'Deixe ela ai por alguns dias. Se tudo estiver certo, pode apagar.' -ForegroundColor Gray
Write-Host ''
Read-Host 'Pressione Enter para fechar'
