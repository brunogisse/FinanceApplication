# =============================================================================
#  Habilitar acesso remoto NESTE computador (o notebook)
#  Nao rode este arquivo direto. De dois cliques em HABILITAR-REMOTO.cmd.
# =============================================================================
#
# Depois disto, a maquina do Bruno (DESKTOP-FTFNMEL, 192.168.1.15) consegue
# copiar arquivos e rodar os scripts de atualizacao aqui, sem ninguem precisar
# clicar nesta maquina.
#
# RODAR UMA VEZ SO. Nas proximas atualizacoes nao e mais preciso.
#
# POR QUE NAO BASTA "Enable-PSRemoting -Force"
#
#   1. Perfil de rede. Se QUALQUER adaptador estiver como Publico - e o Wi-Fi de
#      notebook quase sempre esta -, o Enable-PSRemoting recusa criar a regra de
#      firewall. Ele avisa, mas num texto facil de nao ler, e o resultado e uma
#      maquina que parece habilitada e nao aceita conexao.
#
#   2. Token filtrado. Fora de dominio, uma conta local de administrador conecta
#      remotamente com privilegio REDUZIDO. Os scripts de instalacao pedem
#      administrador de verdade e falhariam. Quem resolve e a chave
#      LocalAccountTokenFilterPolicy.
#
#   3. O TrustedHosts NAO e aqui. Ele vai na maquina que INICIA a conexao, que e
#      a do Bruno. Este script imprime no fim o que ele tem de rodar la.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$CLIENTE_NOME = 'DESKTOP-FTFNMEL'
$CLIENTE_IP   = '192.168.1.15'

function Titulo($t) {
    Write-Host ''
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host " $t" -ForegroundColor Cyan
    Write-Host ('=' * 64) -ForegroundColor Cyan
    Write-Host ''
}

Titulo 'Habilitar acesso remoto neste computador'

Write-Host ("Computador: {0}" -f $env:COMPUTERNAME)
$cs = Get-CimInstance Win32_ComputerSystem
Write-Host ("Rede:       {0} (dominio: {1})" -f $cs.Domain, $cs.PartOfDomain)

# ------------------------------------------------------------- 1. perfil de rede
Titulo 'Passo 1 - perfil das redes'

$perfis = Get-NetConnectionProfile
foreach ($p in $perfis) {
    $cor = if ($p.NetworkCategory -eq 'Public') { 'Yellow' } else { 'Green' }
    Write-Host ("  {0,-28} {1}" -f $p.InterfaceAlias, $p.NetworkCategory) -ForegroundColor $cor
}

$publicos = @($perfis | Where-Object { $_.NetworkCategory -eq 'Public' })
if ($publicos.Count -gt 0) {
    Write-Host ''
    Write-Host 'Ha rede marcada como Publica. Nela o Windows bloqueia o acesso remoto.' -ForegroundColor Yellow
    Write-Host 'Vou marcar como Particular APENAS a(s) rede(s) acima, que sao as desta casa.' -ForegroundColor Yellow
    Write-Host ''
    $r = Read-Host 'Pode marcar como Particular? (digite SIM para confirmar)'
    if ($r -ne 'SIM') {
        Write-Host ''
        Write-Host 'Sem isso o acesso remoto nao funciona. Nada foi alterado.' -ForegroundColor Red
        Read-Host 'Pressione Enter para fechar'
        exit 1
    }
    foreach ($p in $publicos) {
        Set-NetConnectionProfile -InterfaceIndex $p.InterfaceIndex -NetworkCategory Private
        Write-Host ("  {0}: agora Particular" -f $p.InterfaceAlias) -ForegroundColor Green
    }
} else {
    Write-Host ''
    Write-Host '  nenhuma rede Publica. Segue.' -ForegroundColor Green
}

# ------------------------------------------------------------------ 2. PSRemoting
Titulo 'Passo 2 - ligar o servico de acesso remoto'

Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Host

# Conferir o EFEITO, nao o codigo de saida.
$servico = Get-Service WinRM
if ($servico.Status -ne 'Running') { throw 'O servico WinRM nao esta rodando depois do Enable-PSRemoting.' }
Write-Host ("  servico WinRM: {0}" -f $servico.Status) -ForegroundColor Green

$ouvintes = @(Get-ChildItem WSMan:\localhost\Listener -ErrorAction SilentlyContinue)
if ($ouvintes.Count -eq 0) { throw 'Nenhum ouvinte WinRM foi criado.' }
Write-Host ("  ouvintes: {0}" -f $ouvintes.Count) -ForegroundColor Green

# ------------------------------------------------------------------ 3. firewall
Titulo 'Passo 3 - firewall'

# Get-NetFirewallRule devolve VAZIO sem elevacao, como se a regra nao existisse.
# Aqui estamos elevados, entao da para confiar - mas o netsh confirma por segunda via.
$regras = @(Get-NetFirewallRule -Name 'WINRM-HTTP-In-TCP*' -ErrorAction SilentlyContinue)
foreach ($r in $regras) {
    if (-not $r.Enabled) { Enable-NetFirewallRule -Name $r.Name }
    Write-Host ("  {0}: {1}" -f $r.Name, $(if ($r.Enabled) { 'ligada' } else { 'ligada agora' })) -ForegroundColor Green
}
if ($regras.Count -eq 0) {
    Write-Host '  Get-NetFirewallRule nao achou. Conferindo por netsh...' -ForegroundColor Yellow
    netsh advfirewall firewall show rule name="Windows Remote Management (HTTP-In)" | Out-Host
}

# --------------------------------------------------------- 4. token filtrado
Titulo 'Passo 4 - permitir administrador remoto (conta local)'

# Fora de dominio, uma conta local de administrador conecta com token REDUZIDO e os
# scripts de instalacao falhariam por falta de privilegio. Esta chave desliga esse
# filtro para conexoes de rede.
$chave = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
New-ItemProperty -Path $chave -Name 'LocalAccountTokenFilterPolicy' `
                 -Value 1 -PropertyType DWord -Force | Out-Null

$valor = (Get-ItemProperty -Path $chave -Name 'LocalAccountTokenFilterPolicy').LocalAccountTokenFilterPolicy
if ($valor -ne 1) { throw 'Nao consegui gravar LocalAccountTokenFilterPolicy.' }
Write-Host '  LocalAccountTokenFilterPolicy = 1' -ForegroundColor Green

# ------------------------------------------------------------------ 5. conferir
Titulo 'Passo 5 - conferindo aqui mesmo'

try {
    Test-WSMan -ComputerName localhost -ErrorAction Stop | Out-Null
    Write-Host '  o proprio computador responde ao WinRM.' -ForegroundColor Green
} catch {
    throw "Test-WSMan falhou localmente: $($_.Exception.Message)"
}

# =============================================================================
#  O que o Bruno precisa saber
# =============================================================================

Titulo 'ANOTE E LEVE ISTO'

$ips = @(Get-NetIPAddress -AddressFamily IPv4 |
         Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' })

Write-Host ("  Nome deste computador:  {0}" -f $env:COMPUTERNAME) -ForegroundColor White
foreach ($i in $ips) {
    Write-Host ("  IP:                     {0}   ({1})" -f $i.IPAddress, $i.InterfaceAlias) -ForegroundColor White
}

Write-Host ''
Write-Host '  Contas de administrador desta maquina (uma delas sera usada para conectar):' -ForegroundColor White
try {
    Get-LocalGroupMember -Group 'Administradores' -ErrorAction Stop |
        ForEach-Object { Write-Host ("    {0}" -f $_.Name) }
} catch {
    # Windows em ingles usa outro nome. O SID e o mesmo em qualquer idioma.
    try {
        $grupo = (Get-LocalGroup | Where-Object { $_.SID.Value -eq 'S-1-5-32-544' }).Name
        Get-LocalGroupMember -Group $grupo | ForEach-Object { Write-Host ("    {0}" -f $_.Name) }
    } catch {
        Write-Host '    (nao consegui listar; use a conta com que voce entra nesta maquina)' -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host '  NA MAQUINA DO BRUNO, rodar uma vez (como Administrador):' -ForegroundColor Cyan
Write-Host ''
Write-Host ('    instalacao\HABILITAR-REMOTO-AQUI.cmd') -ForegroundColor White
Write-Host ''
Write-Host ('  e informar o nome ou o IP acima quando ele perguntar.') -ForegroundColor Cyan
Write-Host ''
Write-Host 'IMPORTANTE: o IP pode mudar quando o notebook reconecta. Se um dia parar' -ForegroundColor Yellow
Write-Host 'de funcionar, e quase sempre isso - refaca com o IP novo, ou use o NOME.' -ForegroundColor Yellow
Write-Host ''
Read-Host 'Pressione Enter para fechar'
