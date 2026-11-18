param([switch]$StopDatabase)
. "$PSScriptRoot/common.ps1"
Set-ToolEnvironment
$stateFile=Join-Path $script:Root '.run/processes.json'
if (Test-Path -LiteralPath $stateFile) {
    $entries=Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
    foreach ($entry in $entries) {
        $p=Get-Process -Id $entry.id -ErrorAction SilentlyContinue
        if ($p -and ([datetime]$p.StartTime).ToUniversalTime().Ticks -eq ([datetime]::Parse($entry.started)).ToUniversalTime().Ticks) {
            $children=Get-CimInstance Win32_Process -Filter "ParentProcessId=$($p.Id)"
            foreach ($child in $children) { Stop-Process -Id $child.ProcessId -Force -ErrorAction SilentlyContinue }
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        }
    }
    Remove-Item -LiteralPath $stateFile
}
if ($StopDatabase) { Import-LocalEnvironment; Invoke-Checked 'docker.exe' @('compose','stop','postgres') }
Write-Output 'Owned application processes stopped; database volume preserved.'
