# Encerra tudo que o ambiente de desenvolvimento subiu.

$nomes = @('electron', 'AgendaFinanceira.Api')

foreach ($nome in $nomes) {
    $processos = @(Get-CimInstance Win32_Process -Filter "Name='$nome.exe'" -ErrorAction SilentlyContinue)
    foreach ($p in $processos) {
        try { Invoke-CimMethod -InputObject $p -MethodName Terminate | Out-Null } catch { }
    }
    Write-Host "$nome : $($processos.Count) encerrado(s)"
}

# O servidor do Angular roda dentro do node; encerra só os que servem este projeto.
$node = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
          Where-Object { $_.CommandLine -match 'agenda-web|ng serve' })
foreach ($p in $node) {
    try { Invoke-CimMethod -InputObject $p -MethodName Terminate | Out-Null } catch { }
}
Write-Host "servidor do cliente : $($node.Count) encerrado(s)"

Write-Host "`nAs janelas de terminal continuam abertas; pode fecha-las." -ForegroundColor Yellow
