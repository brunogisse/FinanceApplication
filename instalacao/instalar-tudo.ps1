# =============================================================================
#  Instalacao completa: API como servico + cliente
#  Nao rode este arquivo direto. De dois cliques em INSTALAR.cmd.
# =============================================================================
#
# Faz os dois passos de uma vez:
#   1. Descobre onde esta o banco do sistema antigo (ou pergunta)
#   2. Instala a API como servico, sobre uma COPIA daquele banco
#   3. Instala o cliente
#   4. Confere que ficou funcionando de verdade
#
# NADA aqui escreve no banco do sistema antigo.

#Requires -RunAsAdministrator
param([string]$BancoDeOrigem)

$ErrorActionPreference = 'Stop'

function Titulo($texto) {
    Write-Host ''
    Write-Host ('=' * 60) -ForegroundColor Cyan
    Write-Host " $texto" -ForegroundColor Cyan
    Write-Host ('=' * 60) -ForegroundColor Cyan
    Write-Host ''
}

Titulo 'Agenda Financeira - instalacao'

# =============================================================================
#  RODAR DA REDE NAO FUNCIONA. Recusar ANTES de fazer qualquer coisa.
# =============================================================================
#
# O compartilhamento e somente leitura, e a instalacao precisa gravar o
# appsettings.Production.json dentro de 'publicado'. Rodando de la, ela copiava o banco,
# criava a coluna, gerava a chave -- e SO ENTAO morria, na primeira escrita.
#
# Aconteceu em 23/08/2026. A regra e a mesma do ATUALIZAR-API.cmd: nada de comecar antes de
# provar que da para terminar.
# `StartsWith` e nao `-like`: no curinga do PowerShell a barra invertida NAO e escape (o
# escape e a crase), entao '\\\\*' procura QUATRO barras e nunca casa. Medido em 23/08/2026 -
# a trava escrita assim passava batido.
if ($PSScriptRoot.StartsWith('\\')) {
    Write-Host ''
    Write-Host 'Esta pasta esta na REDE, e a instalacao nao roda de la.' -ForegroundColor Red
    Write-Host ''
    Write-Host "  Rodando de:  $PSScriptRoot" -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Copie a pasta INTEIRA para o disco deste computador - por exemplo' -ForegroundColor Yellow
    Write-Host 'C:\InstalarAgenda - e rode o INSTALAR.cmd de la.' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Nada foi alterado.' -ForegroundColor Green
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

# Mesmo num disco local a pasta pode ser somente leitura. Prova escrevendo de verdade,
# em vez de supor pelo caminho.
$publicado = Join-Path $PSScriptRoot 'publicado'
if (Test-Path $publicado) {
    $sonda = Join-Path $publicado ('sonda-' + [Guid]::NewGuid().ToString('N').Substring(0, 6) + '.tmp')
    try {
        [System.IO.File]::WriteAllText($sonda, 'x')
        Remove-Item $sonda -Force
    }
    catch {
        Write-Host ''
        Write-Host 'Nao consigo gravar nesta pasta.' -ForegroundColor Red
        Write-Host ''
        Write-Host "  Pasta:  $publicado" -ForegroundColor Yellow
        Write-Host "  Erro:   $($_.Exception.Message)" -ForegroundColor DarkGray
        Write-Host ''
        Write-Host 'A instalacao precisa gravar a configuracao ai dentro. Copie a pasta para' -ForegroundColor Yellow
        Write-Host 'um lugar onde voce possa escrever - C:\InstalarAgenda, por exemplo.' -ForegroundColor Cyan
        Write-Host ''
        Write-Host 'Nada foi alterado.' -ForegroundColor Green
        Read-Host 'Pressione Enter para fechar'
        exit 1
    }
}

# ---------------------------------------------------- onde esta o banco antigo
#
# O caminho do banco esta no config.ini que fica ao lado do executavel do sistema
# antigo, na linha "Database=". Procurar por ele evita perguntar algo que a
# pessoa que instala provavelmente nao sabe responder.
#
# Primeiro: um .FDB entregue junto com o pacote.
#
# Numa maquina que NUNCA teve o sistema antigo - o notebook, por exemplo - nao existe
# config.ini nenhum para consultar, e a varredura terminaria no seletor de arquivos.
# Levando o banco dentro do pacote, a instalacao continua sendo dois cliques.
if (-not $BancoDeOrigem) {
    $doPacote = @(Get-ChildItem (Join-Path $PSScriptRoot '..') -Filter '*.FDB' -File -ErrorAction SilentlyContinue)

    if ($doPacote.Count -eq 1) {
        $BancoDeOrigem = $doPacote[0].FullName
        Write-Host ("Banco que veio no pacote: {0} ({1:N1} MB)" -f
                    $doPacote[0].Name, ($doPacote[0].Length / 1MB)) -ForegroundColor Green
    }
    elseif ($doPacote.Count -gt 1) {
        Write-Host 'O pacote traz mais de um .FDB. Escolha:' -ForegroundColor Yellow
        for ($i = 0; $i -lt $doPacote.Count; $i++) {
            Write-Host ("   [{0}] {1}  ({2:N1} MB, {3:dd/MM/yyyy HH:mm})" -f
                        ($i + 1), $doPacote[$i].Name, ($doPacote[$i].Length / 1MB), $doPacote[$i].LastWriteTime)
        }
        $e = Read-Host 'Numero'
        $n = 0
        if (-not [int]::TryParse($e, [ref]$n) -or $n -lt 1 -or $n -gt $doPacote.Count) {
            throw 'Escolha invalida. Rode de novo.'
        }
        $BancoDeOrigem = $doPacote[$n - 1].FullName
    }
}

if (-not $BancoDeOrigem) {
    Write-Host 'Procurando o banco do sistema antigo...' -ForegroundColor Cyan

    $ondeProcurar = @(
        (Join-Path $PSScriptRoot '..'),
        'C:\',
        'D:\',
        $env:USERPROFILE
    ) | Where-Object { Test-Path $_ }

    Write-Host '  (pode levar um minuto na primeira vez)' -ForegroundColor DarkGray

    $encontrados = @()
    foreach ($raiz in $ondeProcurar) {
        # -Depth limita a varredura: sem isso, um C:\ inteiro leva minutos.
        #
        # SEIS, e nao quatro. Medido em 23/08/2026 nesta maquina: com 4, a varredura de C:\
        # devolve 8 config.ini em 21s e NAO acha o legado, que fica em
        # C:\PROGRAMAS\<pasta>\AGENDA FINANCEIRA ITAPUA\Win32\Debug - nivel 5. Com 6, acha os
        # tres em 40s. Vinte segundos a mais valem nao cair no seletor de arquivos.
        $inis = @(Get-ChildItem $raiz -Filter 'config.ini' -Recurse -Depth 6 -File -ErrorAction SilentlyContinue)
        foreach ($ini in $inis) {
            $linha = Select-String -Path $ini.FullName -Pattern '^\s*Database\s*=\s*(.+)$' -ErrorAction SilentlyContinue |
                     Select-Object -First 1
            if ($linha) {
                $caminho = $linha.Matches[0].Groups[1].Value.Trim()
                if (Test-Path $caminho) { $encontrados += $caminho }
            }
        }
        if ($encontrados.Count -gt 0) { break }
    }

    $encontrados = @($encontrados | Select-Object -Unique)

    if ($encontrados.Count -eq 1) {
        $BancoDeOrigem = $encontrados[0]
        Write-Host "  encontrado: $BancoDeOrigem" -ForegroundColor Green
    }
    elseif ($encontrados.Count -gt 1) {
        # A DATA e o que separa a base viva de um backup antigo. Nesta maquina a varredura
        # trouxe junto uma pasta "Agenda Financeira - backup 04 10 2022": pelo tamanho as
        # duas parecem iguais, e escolher a errada instalaria sobre dados de anos atras.
        Write-Host '  achei mais de um. Escolha - repare na DATA:' -ForegroundColor Yellow
        for ($i = 0; $i -lt $encontrados.Count; $i++) {
            $arquivo = Get-Item $encontrados[$i]
            Write-Host ("   [{0}] {1}" -f ($i + 1), $encontrados[$i])
            Write-Host ("       {0:N1} MB, modificado em {1:dd/MM/yyyy HH:mm}" -f
                        ($arquivo.Length / 1MB), $arquivo.LastWriteTime) -ForegroundColor DarkGray
        }
        $escolha = Read-Host 'Numero'
        $indice = 0
        if (-not [int]::TryParse($escolha, [ref]$indice) -or $indice -lt 1 -or $indice -gt $encontrados.Count) {
            throw 'Escolha invalida. Rode de novo.'
        }
        $BancoDeOrigem = $encontrados[$indice - 1]
    }
    else {
        # Nao achou: abre o seletor de arquivos, que e mais facil do que digitar
        # um caminho comprido sem errar.
        Write-Host '  nao achei sozinho. Vou abrir uma janela para voce escolher o arquivo .FDB.' -ForegroundColor Yellow
        Add-Type -AssemblyName System.Windows.Forms
        $caixa = New-Object System.Windows.Forms.OpenFileDialog
        $caixa.Title = 'Escolha o banco do sistema antigo (.FDB)'
        $caixa.Filter = 'Banco Firebird (*.FDB)|*.FDB|Todos os arquivos (*.*)|*.*'
        if ($caixa.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            throw 'Nenhum arquivo escolhido. Instalacao cancelada.'
        }
        $BancoDeOrigem = $caixa.FileName
    }
}

if (-not (Test-Path $BancoDeOrigem)) { throw "Nao encontrei o banco em $BancoDeOrigem" }

# ------------------------------------------------------------------ a API
Titulo 'Passo 1 de 2 - servico da API'

& (Join-Path $PSScriptRoot '2-instalar-no-notebook.ps1') -BancoDeOrigem $BancoDeOrigem

# --------------------------------------------------------------- o cliente
Titulo 'Passo 2 de 2 - aplicativo'

# O instalador do cliente e POR USUARIO: ele grava em %LOCALAPPDATA%.
#
# Como este script esta elevado, o %LOCALAPPDATA% aqui e o da conta que respondeu ao UAC.
# Quando a pessoa que usa o computador ja e administradora - o caso comum - elevar mantem a
# mesma conta, e o aplicativo vai para o lugar certo. Se alguem digitou credenciais de OUTRA
# conta no UAC, o aplicativo iria para o perfil dessa outra, e a operadora nao o veria.
#
# Por isso a conferencia abaixo compara com o perfil de quem esta na maquina, nao com o
# desta sessao.
$contaInterativa = (Get-CimInstance Win32_ComputerSystem).UserName   # DOMINIO\nome
$nomeInterativo = ($contaInterativa -split '\\')[-1]
$perfilInterativo = Join-Path (Split-Path $env:USERPROFILE -Parent) $nomeInterativo
$exeEsperado = Join-Path $perfilInterativo 'AppData\Local\Programs\agenda-desktop\Agenda Financeira.exe'

$instalador = @(Get-ChildItem (Join-Path $PSScriptRoot '..') -Filter 'AgendaFinanceira-Instalador-*.exe' -Recurse -File -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending) | Select-Object -First 1

if (-not $instalador) {
    Write-Host 'Nao achei o instalador do aplicativo (AgendaFinanceira-Instalador-*.exe).' -ForegroundColor Yellow
    Write-Host 'Instale-o com dois cliques depois que esta janela fechar.' -ForegroundColor Yellow
}
else {
    Write-Host ("Instalando {0}..." -f $instalador.Name) -ForegroundColor Cyan
    $processo = Start-Process -FilePath $instalador.FullName -PassThru -Wait

    # Conferir o EFEITO, e nao o codigo de saida: instalador que relanca um
    # subprocesso retorna zero antes de terminar o trabalho.
    if (Test-Path $exeEsperado) {
        Write-Host "  instalado em $exeEsperado" -ForegroundColor Green
    }
    elseif (Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\agenda-desktop\Agenda Financeira.exe')) {
        # Instalou, mas no perfil errado: o UAC foi respondido com outra conta.
        Write-Host '' -ForegroundColor Yellow
        Write-Host "  ATENCAO: o aplicativo foi instalado no perfil de $env:USERNAME," -ForegroundColor Yellow
        Write-Host "  e nao no de $nomeInterativo, que e quem usa este computador." -ForegroundColor Yellow
        Write-Host '' -ForegroundColor Yellow
        Write-Host "  Peca para $nomeInterativo dar dois cliques em:" -ForegroundColor Yellow
        Write-Host ("    {0}" -f $instalador.FullName) -ForegroundColor Yellow
        Write-Host '  Isso nao pede senha nenhuma.' -ForegroundColor Yellow
    }
    else {
        Write-Host ("  o instalador retornou {0}, mas o executavel nao apareceu em {1}" -f $processo.ExitCode, $exeEsperado) -ForegroundColor Red
        Write-Host '  Procure "Agenda Financeira" no menu Iniciar; se nao estiver la, rode o instalador com dois cliques.' -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------- conferencia
Titulo 'Conferindo'

& (Join-Path $PSScriptRoot 'conferir-estado.ps1')

Write-Host ''
Write-Host 'Pronto. Abra "Agenda Financeira" pelo menu Iniciar.' -ForegroundColor Green
Write-Host ''
Write-Host 'Esta instalacao roda sobre uma COPIA do banco: o que for lancado aqui' -ForegroundColor Yellow
Write-Host 'NAO aparece no sistema antigo.' -ForegroundColor Yellow
Write-Host ''
