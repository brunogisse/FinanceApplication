# =============================================================================
#  Unificar a base do FINANCEIRO com a do FATURAMENTO
#  Nao rode este arquivo direto. De dois cliques em UNIFICAR.cmd.
# =============================================================================
#
# Gera uma base unica onde cada lancamento e cada cadastro carrega o SETOR a que
# pertence, e cada operaria continua vendo exatamente o que ve hoje.
#
# A REGRA, dada pelo Bruno em 08/09/2026:
#
#   "coloque o que era de cada base na base unificada mas separados por setor.
#    nao podemos assumir perda de dados visualizados por cada operaria."
#
# NADA e fundido por semelhanca. Nem lancamento, nem cadastro. Os 9.251
# lancamentos que existem identicos nas duas bases passam a existir DUAS vezes,
# uma por setor - de proposito, porque as duas os enxergam hoje.
#
# Ver docs/unificacao-das-bases.md para o levantamento completo.
#
# ESTE SCRIPT NAO ENCOSTA NAS BASES DE ORIGEM. Elas so sao lidas.

#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory = $true)][string]$Financeiro,
    [Parameter(Mandatory = $true)][string]$Faturamento,
    [Parameter(Mandatory = $true)][string]$Destino,
    [string]$PastaDeBackup = ''
)

$ErrorActionPreference = 'Stop'

$FB = 'C:\Program Files\Firebird\Firebird_2_5\bin'

# Deslocamento dos IDs vindos do faturamento.
#
# Nao e enfeite: 15.437 dos 15.664 lancamentos colidem com IDs do financeiro,
# entao preservar o numero original e impossivel. De quebra, qualquer linha com
# ID acima disto se identifica como vinda do faturamento so pelo numero.
$DESLOCAMENTO = 100000

function Titulo($t) {
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host " $t" -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host ''
}

function Parar($m) {
    Write-Host ''
    Write-Host $m -ForegroundColor Red
    Write-Host ''
    Write-Host 'As bases de origem NAO foram tocadas.' -ForegroundColor Green
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

<#
  Roda um programa externo SEM deixar o stderr virar excecao.

  Com $ErrorActionPreference = 'Stop', cada linha que o gbak ou o isql escrevem
  em stderr vira EXCECAO TERMINANTE, e o script morre antes das conferencias
  logo abaixo da chamada. Medido em 05/09/2026 nos scripts de implantacao.

  O ToString() linha a linha existe porque o que volta de 2>&1 sao ErrorRecord:
  jogados num Out-String, o PowerShell despeja CategoryInfo e o trecho do codigo,
  uma parede vermelha que parece quebra e nao e.
#>
function RodarPrograma {
    param([Parameter(Mandatory)][string]$Programa,
          [Parameter(Mandatory)][string[]]$Argumentos,
          [switch]$Silencioso)
    $anterior = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $saida = & $Programa @Argumentos 2>&1
        $linhas = @($saida | ForEach-Object { $_.ToString() })
        $codigo = $LASTEXITCODE
        if (-not $Silencioso -and $linhas.Count) {
            $linhas | ForEach-Object { Write-Host ("  " + $_) -ForegroundColor DarkGray }
        }
        return [pscustomobject]@{ Codigo = $codigo; Texto = ($linhas -join [Environment]::NewLine) }
    }
    finally { $ErrorActionPreference = $anterior }
}

# O isql -o ACRESCENTA ao arquivo em vez de sobrescrever. Apagar antes, sempre:
# senao a leitura traz o resultado da rodada anterior achando que e o de agora.
function Consultar {
    param([string]$Banco, [string]$Sql, [switch]$Mostrar)
    $id  = [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $arq = Join-Path $env:TEMP "unif-$id.sql"
    $out = Join-Path $env:TEMP "unif-$id.txt"
    [System.IO.File]::WriteAllText($arq, $Sql, (New-Object System.Text.UTF8Encoding $false))
    if (Test-Path $out) { Remove-Item -LiteralPath $out -Force }

    # -b (bail): sem ele o isql segue executando depois de um erro e termina
    # anunciando sucesso.
    $r = RodarPrograma "$FB\isql.exe" `
            @('-b', '-user', 'SYSDBA', '-password', 'masterkey', '-i', $arq, '-o', $out, "localhost:$Banco") `
            -Silencioso

    $texto = if (Test-Path $out) { Get-Content $out -Raw } else { '' }
    if (Test-Path $arq) { Remove-Item -LiteralPath $arq -Force }
    if (Test-Path $out) { Remove-Item -LiteralPath $out -Force }
    if ($Mostrar -and $texto) { ($texto -split "`r?`n") | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "  $_" } }
    return [pscustomobject]@{ Codigo = $r.Codigo; Texto = $texto; Erro = $r.Texto }
}

function Numero($texto, $rotulo) {
    foreach ($l in ($texto -split "`r?`n")) {
        if ($l -match ("^\s*" + [regex]::Escape($rotulo) + "\s+(-?[\d\.]+)")) { return $matches[1] }
    }
    return $null
}

# Contagem E somas. Contar linha nao detecta um valor trocado, e valor trocado
# e o que ninguem percebe.
function Medir($banco) {
    $r = Consultar -Banco $banco -Sql @'
SET LIST ON;
SELECT COUNT(*) AS LANCAMENTOS, SUM(VALOR_PAGO) AS SOMA_PAGA,
       SUM(VALOR_PREVISTO) AS SOMA_PREVISTA FROM REGISTRO_DE_GASTOS;
SELECT COUNT(*) AS CATEGORIAS FROM CATEGORIA;
SELECT COUNT(*) AS SUBCATEGORIAS FROM SUBCATEGORIA;
SELECT COUNT(*) AS CONTAS FROM CONTAS;
SELECT COUNT(*) AS FORMAS FROM FORMA_DE_PAGAMENTO;
SELECT SUM(OCTET_LENGTH(DESCRICAO)) AS BYTES_DESCRICAO FROM REGISTRO_DE_GASTOS;
SELECT SUM(OCTET_LENGTH(OBS)) AS BYTES_OBS FROM REGISTRO_DE_GASTOS;
'@
    if ($r.Codigo -ne 0) { Parar "Nao consegui ler $banco.`n$($r.Erro)" }
    return [pscustomobject]@{
        Lancamentos   = Numero $r.Texto 'LANCAMENTOS'
        SomaPaga      = Numero $r.Texto 'SOMA_PAGA'
        SomaPrevista  = Numero $r.Texto 'SOMA_PREVISTA'
        Categorias    = Numero $r.Texto 'CATEGORIAS'
        Subcategorias = Numero $r.Texto 'SUBCATEGORIAS'
        Contas        = Numero $r.Texto 'CONTAS'
        Formas        = Numero $r.Texto 'FORMAS'
        BytesDesc     = Numero $r.Texto 'BYTES_DESCRICAO'
        BytesObs      = Numero $r.Texto 'BYTES_OBS'
    }
}

# =============================================================================
#  Recusar antes de comecar
# =============================================================================

Titulo 'Unificacao das bases'

if ($PSScriptRoot.StartsWith('\\')) {
    Parar "Esta pasta esta na REDE ($PSScriptRoot). Copie para o disco local e rode dali."
}
if (-not (Test-Path $FB)) { Parar "Nao achei o Firebird 2.5 em $FB." }
$svc = Get-Service -Name 'FirebirdServerDefaultInstance' -ErrorAction SilentlyContinue
if (-not $svc -or $svc.Status -ne 'Running') { Parar 'O servico do Firebird nao esta no ar.' }

foreach ($p in @($Financeiro, $Faturamento)) {
    if (-not (Test-Path $p)) { Parar "Nao achei a base: $p" }
}

$Financeiro  = (Get-Item $Financeiro).FullName
$Faturamento = (Get-Item $Faturamento).FullName

if ($Financeiro -eq $Faturamento) { Parar 'As duas bases informadas sao o mesmo arquivo.' }
if ((Test-Path $Destino) -and ((Get-Item $Destino).FullName -in @($Financeiro, $Faturamento))) {
    Parar 'O destino nao pode ser uma das bases de origem.'
}

Write-Host ("  financeiro   {0}" -f $Financeiro)
Write-Host ("  faturamento  {0}" -f $Faturamento)
Write-Host ("  destino      {0}" -f $Destino)

# =============================================================================
#  1. Medir as origens
# =============================================================================

Titulo '1. Medindo as bases de origem'

$mFin = Medir $Financeiro
$mFat = Medir $Faturamento

Write-Host ("  FINANCEIRO   {0,7} lancamentos   pago {1,22}   previsto {2,22}" -f $mFin.Lancamentos, $mFin.SomaPaga, $mFin.SomaPrevista)
Write-Host ("  FATURAMENTO  {0,7} lancamentos   pago {1,22}   previsto {2,22}" -f $mFat.Lancamentos, $mFat.SomaPaga, $mFat.SomaPrevista)
Write-Host ''
Write-Host ("  cadastros    financeiro {0}/{1}/{2}/{3}   faturamento {4}/{5}/{6}/{7}   (categ/subcateg/contas/formas)" -f
            $mFin.Categorias, $mFin.Subcategorias, $mFin.Contas, $mFin.Formas,
            $mFat.Categorias, $mFat.Subcategorias, $mFat.Contas, $mFat.Formas)

# =============================================================================
#  2. Backup e destino
# =============================================================================

Titulo '2. Gerando o destino a partir do financeiro'

if (-not $PastaDeBackup) { $PastaDeBackup = Split-Path $Destino -Parent }
New-Item -ItemType Directory -Force -Path $PastaDeBackup | Out-Null
$fbk = Join-Path $PastaDeBackup ('financeiro-' + (Get-Date -Format 'yyyy-MM-dd_HHmm') + '.fbk')

# gbak, e nao copia de arquivo: copiar leva junto o lixo de paginas e qualquer
# estrago que ja estivesse la, e o restore reescreve pagina por pagina.
Write-Host 'Backup do financeiro...' -ForegroundColor Cyan
$r = RodarPrograma "$FB\gbak.exe" @('-b', '-user', 'SYSDBA', '-password', 'masterkey', "localhost:$Financeiro", $fbk)
if ($r.Codigo -ne 0) { Parar "gbak (backup) devolveu $($r.Codigo).`n$($r.Texto)" }
if (-not (Test-Path $fbk)) { Parar "O gbak terminou sem erro, mas $fbk nao existe." }
Write-Host ("  {0}  ({1:N1} MB)" -f $fbk, ((Get-Item $fbk).Length / 1MB)) -ForegroundColor Green

if (Test-Path $Destino) {
    Write-Host ''
    Write-Host ("JA EXISTE um arquivo no destino: {0}" -f $Destino) -ForegroundColor Yellow
    Write-Host ("  {0:N1} MB, modificado em {1}" -f ((Get-Item $Destino).Length / 1MB), (Get-Item $Destino).LastWriteTime)
    Write-Host ''
    $resp = Read-Host 'Apagar e gerar de novo? (digite SIM)'
    if ($resp -ne 'SIM') { Parar 'Cancelado.' }
    Remove-Item -LiteralPath $Destino -Force
}

Write-Host 'Restaurando como destino...' -ForegroundColor Cyan
$r = RodarPrograma "$FB\gbak.exe" @('-c', '-user', 'SYSDBA', '-password', 'masterkey', $fbk, "localhost:$Destino")
if ($r.Codigo -ne 0) { Parar "gbak (restore) devolveu $($r.Codigo).`n$($r.Texto)" }
if (-not (Test-Path $Destino)) { Parar 'O gbak terminou sem erro, mas o destino nao existe.' }
Write-Host ("  {0:N1} MB" -f ((Get-Item $Destino).Length / 1MB)) -ForegroundColor Green

# =============================================================================
#  3. Estrutura
# =============================================================================

Titulo '3. Criando SETOR e as colunas de setor'

$estrutura = Join-Path $PSScriptRoot '1-estrutura.sql'
if (-not (Test-Path $estrutura)) { Parar "Nao achei $estrutura" }
$r = Consultar -Banco $Destino -Sql (Get-Content $estrutura -Raw)
if ($r.Codigo -ne 0) { Parar "A etapa de estrutura falhou.`n$($r.Erro)`n$($r.Texto)" }
Write-Host '  estrutura criada e o que ja estava na base marcado como FINANCEIRO' -ForegroundColor Green

# =============================================================================
#  4. Copia
# =============================================================================

Titulo '4. Copiando o faturamento'

# A copia acontece DENTRO do servidor, por EXECUTE STATEMENT ON EXTERNAL.
#
# Medido em 08/09/2026: pelo cliente .NET, a linha 6.655 morria com "string
# right truncation" - o campo OBS tem 200 caracteres com acentos, e o cliente
# codificava o parametro com mais de um byte por acentuado. Aqui os bytes vao de
# um banco para o outro sem passar por codificacao nenhuma, e o FLOAT de
# VALOR_PAGO tambem nao vira texto no caminho.
$modelo = Join-Path $PSScriptRoot '2-copia.sql.modelo'
if (-not (Test-Path $modelo)) { Parar "Nao achei $modelo" }

$sqlCopia = (Get-Content $modelo -Raw).
                Replace('@@ORIGEM@@', "localhost:$Faturamento").
                Replace('@@DESLOCAMENTO@@', "$DESLOCAMENTO")

$cronometro = [Diagnostics.Stopwatch]::StartNew()
$r = Consultar -Banco $Destino -Sql $sqlCopia
$cronometro.Stop()
if ($r.Codigo -ne 0) { Parar "A copia falhou.`n$($r.Erro)`n$($r.Texto)" }
Write-Host ("  copiado em {0:N0}s" -f $cronometro.Elapsed.TotalSeconds) -ForegroundColor Green

# ----------------------------------------------------------------- generators
#
# Do MAX real, e nao de um numero calculado a partir do deslocamento: valor fixo
# funciona hoje e mente amanha, e o efeito de um generator abaixo do maior ID e
# a proxima inclusao violar a chave primaria - em silencio, ate alguem lancar.
Write-Host ''
Write-Host 'Ajustando os generators...' -ForegroundColor Cyan
$geradores = @(
    @{ Gerador = 'GEN_REGISTRO_DE_GASTOS_ID'; Tabela = 'REGISTRO_DE_GASTOS'; Coluna = 'GASTOS_ID' },
    @{ Gerador = 'GEN_CATEGORIA_ID';          Tabela = 'CATEGORIA';          Coluna = 'CATEGORIA_ID' },
    @{ Gerador = 'GEN_SUBCATEGORIA_ID';       Tabela = 'SUBCATEGORIA';       Coluna = 'SUBCATEGORIA_ID' },
    @{ Gerador = 'GEN_CONTAS_ID';             Tabela = 'CONTAS';             Coluna = 'CONTA_ID' },
    @{ Gerador = 'GEN_FORMA_DE_PAGAMENTO_ID'; Tabela = 'FORMA_DE_PAGAMENTO'; Coluna = 'FORMA_DE_PAGAMENTO_ID' },
    @{ Gerador = 'GEN_LOGIN_ID';              Tabela = 'LOGIN';              Coluna = 'LOGIN_ID' }
)
foreach ($g in $geradores) {
    $lido = Consultar -Banco $Destino -Sql "SET LIST ON;`nSELECT COALESCE(MAX($($g.Coluna)), 0) AS MAIOR FROM $($g.Tabela);`n"
    if ($lido.Codigo -ne 0) { Parar "Nao consegui ler o maior $($g.Coluna).`n$($lido.Erro)" }
    $maior = [int](Numero $lido.Texto 'MAIOR')

    $posto = Consultar -Banco $Destino -Sql "SET GENERATOR $($g.Gerador) TO $maior;`nCOMMIT;`n"
    if ($posto.Codigo -ne 0) { Parar "Nao consegui ajustar $($g.Gerador).`n$($posto.Erro)" }

    # Conferir o EFEITO: o SET GENERATOR pode passar e o valor nao mudar.
    $agora = Consultar -Banco $Destino -Sql "SET LIST ON;`nSELECT GEN_ID($($g.Gerador), 0) AS VALOR FROM RDB`$DATABASE;`n"
    $valor = [int](Numero $agora.Texto 'VALOR')
    if ($valor -ne $maior) { Parar "$($g.Gerador) ficou em $valor, esperado $maior." }
    Write-Host ("  {0,-28} -> {1,8}" -f $g.Gerador, $maior) -ForegroundColor Green
}

# =============================================================================
#  5. Conferir - o produto
# =============================================================================

Titulo '5. Conferindo'

$conf = Consultar -Banco $Destino -Sql @'
SET LIST ON;
SELECT COUNT(*) AS F_LANCAMENTOS, SUM(VALOR_PAGO) AS F_PAGA, SUM(VALOR_PREVISTO) AS F_PREVISTA,
       SUM(OCTET_LENGTH(DESCRICAO)) AS F_BYTES_DESC, SUM(OCTET_LENGTH(OBS)) AS F_BYTES_OBS
  FROM REGISTRO_DE_GASTOS WHERE SETOR_ID = 1;
SELECT COUNT(*) AS T_LANCAMENTOS, SUM(VALOR_PAGO) AS T_PAGA, SUM(VALOR_PREVISTO) AS T_PREVISTA,
       SUM(OCTET_LENGTH(DESCRICAO)) AS T_BYTES_DESC, SUM(OCTET_LENGTH(OBS)) AS T_BYTES_OBS
  FROM REGISTRO_DE_GASTOS WHERE SETOR_ID = 2;
SELECT COUNT(*) AS F_CATEG FROM CATEGORIA WHERE SETOR_ID = 1;
SELECT COUNT(*) AS T_CATEG FROM CATEGORIA WHERE SETOR_ID = 2;
SELECT COUNT(*) AS F_SUB FROM SUBCATEGORIA WHERE SETOR_ID = 1;
SELECT COUNT(*) AS T_SUB FROM SUBCATEGORIA WHERE SETOR_ID = 2;
SELECT COUNT(*) AS F_CONTAS FROM CONTAS WHERE SETOR_ID = 1;
SELECT COUNT(*) AS T_CONTAS FROM CONTAS WHERE SETOR_ID = 2;
SELECT COUNT(*) AS F_FORMAS FROM FORMA_DE_PAGAMENTO WHERE SETOR_ID = 1;
SELECT COUNT(*) AS T_FORMAS FROM FORMA_DE_PAGAMENTO WHERE SETOR_ID = 2;
SELECT COUNT(*) AS SEM_SETOR FROM REGISTRO_DE_GASTOS WHERE SETOR_ID IS NULL;
SELECT COUNT(*) AS LOGIN_SEM_SETOR FROM LOGIN WHERE SETOR_ID IS NULL;
SELECT COUNT(*) AS ORFA_CATEG FROM REGISTRO_DE_GASTOS g
 WHERE NOT EXISTS (SELECT 1 FROM CATEGORIA x WHERE x.CATEGORIA_ID = g.CATEGORIA_ID);
SELECT COUNT(*) AS ORFA_SUB FROM REGISTRO_DE_GASTOS g
 WHERE NOT EXISTS (SELECT 1 FROM SUBCATEGORIA x WHERE x.SUBCATEGORIA_ID = g.SUBCATEGORIA_ID);
SELECT COUNT(*) AS ORFA_CONTA FROM REGISTRO_DE_GASTOS g
 WHERE NOT EXISTS (SELECT 1 FROM CONTAS x WHERE x.CONTA_ID = g.CONTA_ID);
SELECT COUNT(*) AS ORFA_FORMA FROM REGISTRO_DE_GASTOS g
 WHERE NOT EXISTS (SELECT 1 FROM FORMA_DE_PAGAMENTO x WHERE x.FORMA_DE_PAGAMENTO_ID = g.FORMA_DE_PAGAMENTO_ID);
SELECT COUNT(*) AS ORFA_USER FROM REGISTRO_DE_GASTOS g
 WHERE NOT EXISTS (SELECT 1 FROM LOGIN x WHERE x.LOGIN_ID = g.USERID);
SELECT COUNT(*) AS MISTURA FROM REGISTRO_DE_GASTOS g
  JOIN CATEGORIA c ON c.CATEGORIA_ID = g.CATEGORIA_ID WHERE g.SETOR_ID <> c.SETOR_ID;
SELECT GEN_ID(GEN_REGISTRO_DE_GASTOS_ID, 0) AS GERADOR,
       (SELECT MAX(GASTOS_ID) FROM REGISTRO_DE_GASTOS) AS MAIOR_ID FROM RDB$DATABASE;
'@
if ($conf.Codigo -ne 0) { Parar "A conferencia nao rodou.`n$($conf.Erro)" }

$tudoBem = $true
function Confere($rotulo, $esperado, $obtido) {
    $bate = ("$esperado" -eq "$obtido")
    if (-not $bate) { $script:tudoBem = $false }
    $cor = if ($bate) { 'Green' } else { 'Red' }
    Write-Host ("  {0,-38} esperado {1,22}   obtido {2,22}   {3}" -f
                $rotulo, $esperado, $obtido, $(if ($bate) { 'ok' } else { 'DIVERGE' })) -ForegroundColor $cor
}

Confere 'FINANCEIRO: lancamentos'    $mFin.Lancamentos  (Numero $conf.Texto 'F_LANCAMENTOS')
Confere 'FINANCEIRO: soma paga'      $mFin.SomaPaga     (Numero $conf.Texto 'F_PAGA')
Confere 'FINANCEIRO: soma prevista'  $mFin.SomaPrevista (Numero $conf.Texto 'F_PREVISTA')
Confere 'FINANCEIRO: bytes de texto' $mFin.BytesDesc    (Numero $conf.Texto 'F_BYTES_DESC')
Confere 'FATURAMENTO: lancamentos'   $mFat.Lancamentos  (Numero $conf.Texto 'T_LANCAMENTOS')
Confere 'FATURAMENTO: soma paga'     $mFat.SomaPaga     (Numero $conf.Texto 'T_PAGA')
Confere 'FATURAMENTO: soma prevista' $mFat.SomaPrevista (Numero $conf.Texto 'T_PREVISTA')
Confere 'FATURAMENTO: bytes de texto' $mFat.BytesDesc   (Numero $conf.Texto 'T_BYTES_DESC')
Confere 'FATURAMENTO: bytes de OBS'  $mFat.BytesObs     (Numero $conf.Texto 'T_BYTES_OBS')

Confere 'categorias do financeiro'   $mFin.Categorias    (Numero $conf.Texto 'F_CATEG')
Confere 'categorias do faturamento'  $mFat.Categorias    (Numero $conf.Texto 'T_CATEG')
Confere 'subcategorias do financeiro' $mFin.Subcategorias (Numero $conf.Texto 'F_SUB')
Confere 'subcategorias do faturamento' $mFat.Subcategorias (Numero $conf.Texto 'T_SUB')
Confere 'contas do financeiro'       $mFin.Contas        (Numero $conf.Texto 'F_CONTAS')
Confere 'contas do faturamento'      $mFat.Contas        (Numero $conf.Texto 'T_CONTAS')
Confere 'formas do financeiro'       $mFin.Formas        (Numero $conf.Texto 'F_FORMAS')
Confere 'formas do faturamento'      $mFat.Formas        (Numero $conf.Texto 'T_FORMAS')

Confere 'lancamento sem setor'       0 (Numero $conf.Texto 'SEM_SETOR')
Confere 'usuario sem setor'          0 (Numero $conf.Texto 'LOGIN_SEM_SETOR')
Confere 'FK orfa: categoria'         0 (Numero $conf.Texto 'ORFA_CATEG')
Confere 'FK orfa: subcategoria'      0 (Numero $conf.Texto 'ORFA_SUB')
Confere 'FK orfa: conta'             0 (Numero $conf.Texto 'ORFA_CONTA')
Confere 'FK orfa: forma'             0 (Numero $conf.Texto 'ORFA_FORMA')
Confere 'FK orfa: usuario'           0 (Numero $conf.Texto 'ORFA_USER')
Confere 'lancamento com cadastro de outro setor' 0 (Numero $conf.Texto 'MISTURA')

$gerador = [int](Numero $conf.Texto 'GERADOR')
$maior   = [int](Numero $conf.Texto 'MAIOR_ID')
$okGer   = $gerador -ge $maior
if (-not $okGer) { $tudoBem = $false }
Write-Host ("  {0,-38} gerador {1,21}   maior ID {2,20}   {3}" -f
            'gerador acima do maior ID', $gerador, $maior,
            $(if ($okGer) { 'ok' } else { 'ABAIXO - a proxima inclusao violaria a PK' })) -ForegroundColor $(if ($okGer) { 'Green' } else { 'Red' })

# =============================================================================

if (-not $tudoBem) {
    Titulo 'UNIFICACAO COM DIVERGENCIA'
    Write-Host 'NAO use este arquivo. Alguma coisa nao bate com as origens.' -ForegroundColor Red
    Write-Host ("Destino gerado, para investigar: {0}" -f $Destino) -ForegroundColor Yellow
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

Titulo 'Unificacao concluida'
Write-Host ("  {0}" -f $Destino) -ForegroundColor Green
Write-Host ("  {0:N1} MB, {1} lancamentos" -f ((Get-Item $Destino).Length / 1MB),
            ([int]$mFin.Lancamentos + [int]$mFat.Lancamentos))
Write-Host ''
Write-Host 'As bases de origem nao foram tocadas.' -ForegroundColor Gray
Write-Host ("Backup do financeiro em: {0}" -f $fbk) -ForegroundColor Gray
Write-Host ''
Write-Host 'ATENCAO: a API ainda NAO filtra por setor. Ate isso existir, qualquer' -ForegroundColor Yellow
Write-Host 'pessoa que entrar ve os lancamentos dos dois setores.' -ForegroundColor Yellow
Write-Host ''
Read-Host 'Pressione Enter para fechar'
