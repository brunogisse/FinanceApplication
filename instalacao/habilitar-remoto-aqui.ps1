# =============================================================================
#  Habilitar ESTA maquina a conectar no notebook
#  Nao rode este arquivo direto. De dois cliques em HABILITAR-REMOTO-AQUI.cmd.
# =============================================================================
#
# Este e o lado do CLIENTE - a maquina que INICIA a conexao. Rode aqui, na
# maquina do Bruno, depois de ter rodado o HABILITAR-REMOTO.cmd no notebook.
#
# O TrustedHosts mora aqui e nao la. Fora de dominio nao ha Kerberos, entao o
# Windows so aceita mandar credencial para maquinas que estejam nesta lista.
#
# ESTE SCRIPT NAO ABRE ESTA MAQUINA PARA NINGUEM.
# TrustedHosts diz em quem EU confio para CONECTAR. Ele nao cria ouvinte, nao
# abre porta e nao deixa ninguem entrar aqui. Quem quiser entrar nesta maquina
# continua tendo de passar pelo firewall, que nao e tocado.

#Requires -RunAsAdministrator

param([string]$Notebook = '')

$ErrorActionPreference = 'Stop'

function Titulo($t) {
    Write-Host ''
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host " $t" -ForegroundColor Cyan
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host ''
}

Titulo 'Habilitar esta maquina a conectar no notebook'

Write-Host ("Esta maquina: {0}" -f $env:COMPUTERNAME)

if (-not $Notebook) {
    Write-Host ''
    Write-Host 'Informe o nome OU o IP do notebook - o que o script de la imprimiu.'
    Write-Host 'Prefira o NOME: o IP muda quando ele reconecta na rede.' -ForegroundColor Yellow
    Write-Host ''
    $Notebook = (Read-Host 'Nome ou IP do notebook').Trim()
}
if (-not $Notebook) { Write-Host 'Nada informado. Saindo.' -ForegroundColor Yellow; exit 1 }

# ------------------------------------------------------------ 1. servico WinRM
Titulo 'Passo 1 - ligar o WinRM desta maquina'

# O cliente tambem precisa do servico no ar: e por ele que o provedor WSMan e o
# Invoke-Command funcionam.
$svc = Get-Service WinRM
if ($svc.Status -ne 'Running') {
    Set-Service WinRM -StartupType Automatic
    Start-Service WinRM
    (Get-Service WinRM).WaitForStatus('Running', '00:00:30')
}
Write-Host ("  WinRM: {0}" -f (Get-Service WinRM).Status) -ForegroundColor Green

# --------------------------------------------------------- 2. TrustedHosts
Titulo 'Passo 2 - dizer em quem confiar'

$caminho = 'WSMan:\localhost\Client\TrustedHosts'
$atual = (Get-Item $caminho).Value

Write-Host ("  TrustedHosts hoje: {0}" -f $(if ($atual) { $atual } else { '(vazio)' }))

# Acrescentar, nunca substituir: sobrescrever apagaria uma confianca que ja
# existisse para outra maquina, sem avisar.
$lista = @()
if ($atual) { $lista = @($atual -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }

if ($lista -contains $Notebook) {
    Write-Host ("  '{0}' ja estava na lista." -f $Notebook) -ForegroundColor DarkGray
} else {
    $lista += $Notebook
    Set-Item $caminho -Value ($lista -join ',') -Force
}

$depois = (Get-Item $caminho).Value
Write-Host ("  TrustedHosts agora: {0}" -f $depois) -ForegroundColor Green
if ($depois -notlike "*$Notebook*") { throw "Nao consegui gravar '$Notebook' no TrustedHosts." }

# ------------------------------------------------------------- 3. conferir
Titulo 'Passo 3 - conferindo se o notebook responde'

Write-Host 'Testando alcance...' -ForegroundColor Cyan
$porta = Test-NetConnection -ComputerName $Notebook -Port 5985 -InformationLevel Quiet -WarningAction SilentlyContinue

if (-not $porta) {
    Write-Host ''
    Write-Host ("  {0} nao respondeu na porta 5985." -f $Notebook) -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Causas, da mais comum para a menos:' -ForegroundColor Yellow
    Write-Host '    - o notebook esta desligado, dormindo, ou fora desta rede'
    Write-Host '    - o HABILITAR-REMOTO.cmd ainda nao foi rodado la'
    Write-Host '    - o IP mudou (por isso e melhor usar o NOME)'
    Write-Host '    - o Wi-Fi de la voltou para o perfil Publico'
    Write-Host ''
    Write-Host '  O TrustedHosts JA foi gravado. Quando o notebook estiver na rede,' -ForegroundColor Green
    Write-Host '  basta rodar este script de novo para conferir.' -ForegroundColor Green
    Write-Host ''
    Read-Host 'Pressione Enter para fechar'
    exit 0
}

Write-Host '  a porta 5985 responde.' -ForegroundColor Green

try {
    Test-WSMan -ComputerName $Notebook -ErrorAction Stop | Out-Null
    Write-Host '  o WinRM de la responde.' -ForegroundColor Green
} catch {
    Write-Host ("  a porta abre, mas o WinRM recusou: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Titulo 'Pronto'

Write-Host 'Para provar de ponta a ponta, com a senha da conta de la:' -ForegroundColor Cyan
Write-Host ''
Write-Host ("    `$c = Get-Credential            # usuario do notebook") -ForegroundColor White
Write-Host ("    Invoke-Command -ComputerName {0} -Credential `$c ``" -f $Notebook) -ForegroundColor White
Write-Host ("        -ScriptBlock { `$env:COMPUTERNAME; (Get-Service AgendaFinanceiraApi).Status }") -ForegroundColor White
Write-Host ''
Write-Host 'Se isso devolver o nome do notebook e o estado do servico, esta funcionando.' -ForegroundColor Green
Write-Host ''
Read-Host 'Pressione Enter para fechar'
