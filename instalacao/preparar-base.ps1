# =============================================================================
#  Preparar uma base de trabalho a partir de uma base quente
# =============================================================================
#
# Recebe um .FDB vindo da producao e entrega, na pasta de trabalho, uma copia
# pronta para a API usar: reorganizada por gbak e com a coluna SENHA_HASH.
#
# Serve para os dois setores. Hoje:
#
#   .\preparar-base.ps1 -Origem 'C:\...\FINANCES.FDB'             -Nome FINANCES
#   .\preparar-base.ps1 -Origem 'C:\...\FINANCESFATURAMENTO.FDB'  -Nome FINANCESFATURAMENTO
#
# O QUE ELE NUNCA FAZ
#
# Nao conecta na ORIGEM. Nem para ler. Conectar pelo servidor avanca os contadores
# de transacao no cabecalho e muda a data do arquivo, e a origem pode ser a base
# que alguem esta usando. O primeiro passo e uma copia do ARQUIVO; tudo depois
# acontece sobre a copia.
#
# POR QUE gbak E NAO COPIAR O ARQUIVO
#
# Copiar entrega os mesmos bytes, inclusive o lixo de paginas e qualquer estrago
# que ja estivesse la. O backup + restore reescreve o banco pagina por pagina, e
# um erro no meio do caminho aparece AQUI e nao na semana que vem.

param(
    [Parameter(Mandatory = $true)][string]$Origem,
    [Parameter(Mandatory = $true)][string]$Nome,
    [string]$PastaDeTrabalho = 'C:\AgendaFinanceira'
)

$ErrorActionPreference = 'Stop'

$fb = 'C:\Program Files\Firebird\Firebird_2_5\bin'

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
    Write-Host 'Nada foi alterado.' -ForegroundColor Green
    exit 1
}

# O isql grava com -o em modo ACRESCENTAR, nao sobrescrever. Rodar duas consultas
# seguidas deixa os dois resultados no mesmo arquivo, um embaixo do outro, e a
# leitura parece uma listagem so. Em 23/08/2026 isso quase levou a apagar registros
# que ja tinham sido excluidos na rodada anterior. Por isso: apagar sempre antes.
function Consultar($banco, $sql) {
    $arqSql   = Join-Path $env:TEMP ('preparar-' + [Guid]::NewGuid().ToString('N').Substring(0,8) + '.sql')
    $arqSaida = [System.IO.Path]::ChangeExtension($arqSql, '.txt')

    [System.IO.File]::WriteAllText($arqSql, $sql, (New-Object System.Text.UTF8Encoding $false))
    if (Test-Path $arqSaida) { Remove-Item $arqSaida -Force }

    # -b (bail): sem ele o isql SEGUE executando as instrucoes seguintes depois de um
    # erro e termina anunciando sucesso. Nao e -v ON_ERROR_STOP, que e do psql.
    & "$fb\isql.exe" -b -user SYSDBA -password masterkey -i $arqSql -o $arqSaida "localhost:$banco" 2>&1 | Out-Null
    $codigo = $LASTEXITCODE

    $texto = if (Test-Path $arqSaida) { Get-Content $arqSaida -Raw } else { '' }
    Remove-Item $arqSql -Force -ErrorAction SilentlyContinue
    Remove-Item $arqSaida -Force -ErrorAction SilentlyContinue

    if ($codigo -ne 0) { throw "isql falhou com codigo $codigo. Saida:`n$texto" }
    return $texto
}

function Numero($texto, $rotulo) {
    foreach ($linha in ($texto -split "`r?`n")) {
        if ($linha -match ("^\s*" + $rotulo + "\s+(-?[\d\.]+)")) { return $matches[1] }
    }
    return $null
}

Titulo "Preparar a base $Nome"

# =============================================================================
#  Recusar antes de comecar
# =============================================================================

if (-not (Test-Path $fb)) { Parar "Nao achei o Firebird 2.5 em $fb" }

$servicoFb = Get-Service -Name 'FirebirdServerDefaultInstance' -ErrorAction SilentlyContinue
if (-not $servicoFb -or $servicoFb.Status -ne 'Running') {
    Parar 'O servico do Firebird nao esta no ar. O gbak e o isql precisam dele.'
}

if (-not (Test-Path $Origem)) { Parar "Nao achei a origem: $Origem" }

$arqOrigem = Get-Item $Origem
Write-Host ("Origem: {0}" -f $arqOrigem.FullName)
Write-Host ("        {0:N2} MB, modificado em {1}" -f ($arqOrigem.Length / 1MB), $arqOrigem.LastWriteTime)

# gstat -h le o ARQUIVO, sem servidor e sem escrever nada. Prova que e um Firebird
# de verdade e mostra o formato antes de qualquer coisa.
$cabecalho = & "$fb\gstat.exe" -h $arqOrigem.FullName 2>&1
$ods = ($cabecalho | Select-String -Pattern 'ODS version\s+(.+)').Matches.Groups[1].Value.Trim()
$dialeto = ($cabecalho | Select-String -Pattern 'Database dialect\s+(.+)').Matches.Groups[1].Value.Trim()
Write-Host ("        ODS {0}, dialect {1}" -f $ods, $dialeto)

if ($ods -notlike '11.*') { Parar "ODS $ods nao e do Firebird 2.5. Este banco nao abre aqui." }

New-Item -ItemType Directory -Force -Path $PastaDeTrabalho | Out-Null
$destino = Join-Path $PastaDeTrabalho "$Nome.FDB"

# ------------------------------------------------------------ ja existe la?
#
# Destrutivo: mostrar o que existe hoje ANTES de perguntar. O nome parece certo
# mesmo quando aponta para o lugar errado; a contagem e o que faz reconhecer.
if (Test-Path $destino) {
    $atual = Get-Item $destino
    Write-Host ''
    Write-Host 'JA EXISTE uma base de trabalho com este nome:' -ForegroundColor Yellow
    Write-Host ("  {0}" -f $atual.FullName)
    Write-Host ("  {0:N2} MB, modificado em {1}" -f ($atual.Length / 1MB), $atual.LastWriteTime)

    try {
        $conta = Consultar $atual.FullName @'
SET LIST ON;
SELECT COUNT(*) AS LANCAMENTOS FROM REGISTRO_DE_GASTOS;
SELECT COUNT(*) AS USUARIOS FROM LOGIN;
'@
        foreach ($l in ($conta -split "`r?`n")) { if ($l.Trim()) { Write-Host "  $l" } }
    } catch {
        Write-Host ("  nao consegui contar o conteudo: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }

    Write-Host ''
    $r = Read-Host 'Apagar esta base e gerar outra a partir da origem? (digite SIM para confirmar)'
    if ($r -ne 'SIM') { Write-Host 'Cancelado. Nada foi alterado.' -ForegroundColor Yellow; exit 1 }
    Remove-Item $destino -Force
}

# =============================================================================
#  Copia do arquivo primeiro. A origem nao recebe conexao nenhuma.
# =============================================================================

Titulo 'Copiando'

$copiaBruta = Join-Path $PastaDeTrabalho ("origem-de-$Nome.FDB")
Write-Host 'Copiando o arquivo (sem conectar na origem)...' -ForegroundColor Cyan
Copy-Item $arqOrigem.FullName $copiaBruta -Force
Write-Host '  copiado.' -ForegroundColor Green

$fbk = Join-Path $PastaDeTrabalho ("$Nome.fbk")
if (Test-Path $fbk) { Remove-Item $fbk -Force }

Write-Host 'Backup logico (gbak -b) sobre a copia...' -ForegroundColor Cyan
& "$fb\gbak.exe" -b -user SYSDBA -password masterkey "localhost:$copiaBruta" $fbk 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { Parar "gbak (backup) falhou com codigo $LASTEXITCODE." }

Write-Host 'Restaurando (gbak -c) para a base de trabalho...' -ForegroundColor Cyan
& "$fb\gbak.exe" -c -user SYSDBA -password masterkey $fbk "localhost:$destino" 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { Parar "gbak (restore) falhou com codigo $LASTEXITCODE." }

# Conferir o EFEITO, nao o codigo de saida.
if (-not (Test-Path $destino)) { Parar "O gbak terminou sem erro, mas $destino nao existe." }
Write-Host '  restaurado.' -ForegroundColor Green

# =============================================================================
#  Coluna de convivencia
# =============================================================================
#
# O Delphi ignora colunas que nao conhece (ADR 0010). Sem SENHA_HASH a autenticacao
# da API nao roda. Quem ainda nao tem hash entra pela senha em texto plano do legado
# e tem o hash gravado naquele momento, entao a base migra sozinha conforme as
# pessoas entram - ninguem precisa trocar senha.

Titulo 'Coluna SENHA_HASH'

$existe = Consultar $destino @'
SET LIST ON;
SELECT COUNT(*) AS TEM FROM RDB$RELATION_FIELDS
 WHERE TRIM(RDB$RELATION_NAME) = 'LOGIN' AND TRIM(RDB$FIELD_NAME) = 'SENHA_HASH';
'@

if ((Numero $existe 'TEM') -eq '0') {
    Write-Host 'Acrescentando...' -ForegroundColor Cyan
    Consultar $destino "ALTER TABLE LOGIN ADD SENHA_HASH VARCHAR(200);`nCOMMIT;`n" | Out-Null
} else {
    Write-Host 'Ja existia.' -ForegroundColor DarkGray
}

# Conferir o EFEITO. O ALTER pode "passar" e a coluna nao estar la.
$conferida = Consultar $destino @'
SET LIST ON;
SELECT COUNT(*) AS TEM FROM RDB$RELATION_FIELDS
 WHERE TRIM(RDB$RELATION_NAME) = 'LOGIN' AND TRIM(RDB$FIELD_NAME) = 'SENHA_HASH';
'@
if ((Numero $conferida 'TEM') -ne '1') { Parar 'A coluna SENHA_HASH nao esta na base depois do ALTER TABLE.' }
Write-Host 'Coluna confirmada.' -ForegroundColor Green

# =============================================================================
#  Separacao por setor
# =============================================================================
#
# A API NAO SOBE sem a coluna SETOR_ID: ela recusa mostrar tudo para todo mundo.
# Ver docs/unificacao-das-bases.md.
#
# Aqui a base recebe UM setor, o 1, porque este script prepara UMA base. A base
# com os dois setores dentro sai de instalacao\unificacao\UNIFICAR.cmd, que ja
# entrega tudo pronto e nem passa por aqui.
#
# Junto vai a trigger que deduz o setor pelo autor. Sem ela, tudo que o Delphi
# gravar durante a convivencia nasce sem setor e nao aparece para ninguem na
# API - inclusive para quem acabou de digitar.

Titulo 'Separacao por setor'

$temSetor = Consultar $destino @'
SET LIST ON;
SELECT COUNT(*) AS TEM FROM RDB$RELATION_FIELDS
 WHERE TRIM(RDB$RELATION_NAME) = 'REGISTRO_DE_GASTOS' AND TRIM(RDB$FIELD_NAME) = 'SETOR_ID';
'@

if ((Numero $temSetor 'TEM') -eq '0') {
    $scriptSetor = Join-Path $PSScriptRoot 'unificacao\setor-unico.sql'
    if (-not (Test-Path $scriptSetor)) { Parar "Nao achei $scriptSetor" }

    Write-Host 'Marcando esta base como setor unico (FINANCEIRO)...' -ForegroundColor Cyan
    Consultar $destino (Get-Content $scriptSetor -Raw) | Out-Null
} else {
    Write-Host 'A base ja tem separacao por setor.' -ForegroundColor DarkGray
}

# Conferir o EFEITO, e nao o codigo de saida: coluna presente, nenhum registro
# sem setor e a trigger no lugar.
$setorOk = Consultar $destino @'
SET LIST ON;
SELECT COUNT(*) AS COLUNA FROM RDB$RELATION_FIELDS
 WHERE TRIM(RDB$RELATION_NAME) = 'REGISTRO_DE_GASTOS' AND TRIM(RDB$FIELD_NAME) = 'SETOR_ID';
SELECT COUNT(*) AS SEM_SETOR FROM REGISTRO_DE_GASTOS WHERE SETOR_ID IS NULL;
SELECT COUNT(*) AS USUARIO_SEM_SETOR FROM LOGIN WHERE SETOR_ID IS NULL;
SELECT COUNT(*) AS TRIGGER_SETOR FROM RDB$TRIGGERS
 WHERE TRIM(RDB$TRIGGER_NAME) = 'REGISTRO_DE_GASTOS_BI_SETOR';
'@

if ((Numero $setorOk 'COLUNA') -ne '1') { Parar 'A coluna SETOR_ID nao esta na base. A API nao vai subir.' }
if ((Numero $setorOk 'SEM_SETOR') -ne '0') { Parar 'Ficaram lancamentos sem setor. Eles nao apareceriam para ninguem.' }
if ((Numero $setorOk 'USUARIO_SEM_SETOR') -ne '0') { Parar 'Ficaram usuarios sem setor. Eles nao conseguiriam entrar.' }
if ((Numero $setorOk 'TRIGGER_SETOR') -ne '1') { Parar 'A trigger REGISTRO_DE_GASTOS_BI_SETOR nao foi criada.' }
Write-Host 'Setor confirmado em todos os registros, e a trigger esta no lugar.' -ForegroundColor Green

# =============================================================================
#  Conferir que a copia bate com a origem
# =============================================================================
#
# Contar linhas nao detecta um valor trocado. Por isso vao junto as SOMAS.
#
# A soma sai em ponto flutuante porque VALOR_PAGO e VALOR_PREVISTO sao FLOAT no
# legado - o defeito central do sistema. Aqui isso nao atrapalha: as duas pontas
# fazem a MESMA conta sobre os MESMOS bytes, entao qualquer diferenca e diferenca
# de dados, nao de arredondamento.

Titulo 'Conferindo'

$consulta = @'
SET LIST ON;
SELECT COUNT(*) AS LANCAMENTOS, SUM(VALOR_PAGO) AS SOMA_PAGO,
       SUM(VALOR_PREVISTO) AS SOMA_PREVISTO FROM REGISTRO_DE_GASTOS;
SELECT COUNT(*) AS USUARIOS FROM LOGIN;
SELECT COUNT(*) AS CONTAS FROM CONTAS;
SELECT COUNT(*) AS CATEGORIAS FROM CATEGORIA;
SELECT COUNT(*) AS SUBCATEGORIAS FROM SUBCATEGORIA;
'@

$naOrigem = Consultar $copiaBruta $consulta
$noDestino = Consultar $destino $consulta

$tudoIgual = $true
foreach ($r in @('LANCAMENTOS','SOMA_PAGO','SOMA_PREVISTO','USUARIOS','CONTAS','CATEGORIAS','SUBCATEGORIAS')) {
    $a = Numero $naOrigem $r
    $b = Numero $noDestino $r
    $ok = ($a -eq $b) -and ($null -ne $a)
    if (-not $ok) { $tudoIgual = $false }
    $cor = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("  {0,-15} origem: {1,-20} copia: {2,-20} {3}" -f $r, $a, $b, $(if ($ok) { 'ok' } else { 'DIFERENTE' })) -ForegroundColor $cor
}

if (-not $tudoIgual) { Parar 'A copia NAO bate com a origem. Nao use esta base.' }

# Limpeza: a copia bruta e o .fbk ja cumpriram o papel.
Remove-Item $copiaBruta -Force
Remove-Item $fbk -Force

Titulo 'Pronta'

Write-Host ("Base de trabalho:  {0}" -f $destino) -ForegroundColor Green
Write-Host ("                   {0:N2} MB" -f ((Get-Item $destino).Length / 1MB))
Write-Host ''
Write-Host 'Para a API passar a usar esta base, aponte o appsettings.Production.json'
Write-Host 'e reinicie o servico. O caminho vai com barras normais:'
Write-Host ("    `"Banco`": {{ `"Caminho`": `"{0}`" }}" -f $destino.Replace('\','/')) -ForegroundColor Cyan
Write-Host ''
