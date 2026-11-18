param([switch]$SkipBuild)
. "$PSScriptRoot/common.ps1"
Import-LocalEnvironment
& "$PSScriptRoot/check-env.ps1"
Set-ToolEnvironment
$stateFile=Join-Path $script:Root '.run/processes.json'
if (Test-Path -LiteralPath $stateFile) { throw 'Existing process state: run scripts/stop-dev.ps1 first.' }
foreach ($port in @($env:BACKEND_PORT,$env:AI_ENGINE_PORT,$env:FRONTEND_PORT)) {
    if (Get-NetTCPConnection -State Listen -LocalPort ([int]$port) -ErrorAction SilentlyContinue) { throw "Port $port is occupied." }
}
New-Item -ItemType Directory -Force (Join-Path $script:Root '.run') | Out-Null
$script:owned=@()
function Start-Owned {
    param([string]$Name,[string]$Exe,[string[]]$Arguments,[string]$Directory)
    $p=Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $Directory -WindowStyle Hidden -PassThru -RedirectStandardOutput "$script:Root/.run/$Name.log" -RedirectStandardError "$script:Root/.run/$Name.err.log"
    $script:owned += @{name=$Name; id=$p.Id; started=$p.StartTime.ToUniversalTime().ToString('o')}
    ConvertTo-Json -InputObject @($script:owned) | Set-Content -LiteralPath $stateFile -Encoding UTF8
}
try {
    Invoke-Checked 'docker.exe' @('compose','up','-d','--wait','--wait-timeout','150')
    if (!$SkipBuild) {
        Invoke-Checked 'mvn.cmd' @('-f','backend/pom.xml','verify','-B')
        Push-Location frontend
        try { Invoke-Checked 'npm.cmd' @('ci','--no-audit','--no-fund'); Invoke-Checked 'npm.cmd' @('run','build') } finally { Pop-Location }
    }
    $jar=Join-Path $script:Root 'backend/comic-boot/target/comic-boot-0.1.0-SNAPSHOT.jar'
    if (!(Test-Path -LiteralPath $jar)) { throw 'Build backend first.' }
    Start-Owned 'backend' (Join-Path $env:JAVA_HOME 'bin/java.exe') @('-jar',"`"$jar`"") $script:Root
    Wait-Http "http://127.0.0.1:$env:BACKEND_PORT/api/v1/health" -Timeout 120
    Start-Owned 'ai-engine' $script:Python @('-m','uvicorn','main:create_app','--factory','--host','127.0.0.1','--port',$env:AI_ENGINE_PORT) "$script:Root/ai-engine"
    Wait-Http "http://127.0.0.1:$env:AI_ENGINE_PORT/internal/v1/health" @{Authorization="Bearer $env:AI_ENGINE_TOKEN"}
    $node=(Get-Command node.exe).Source
    Start-Owned 'frontend' $node @('node_modules/vite/bin/vite.js') "$script:Root/frontend"
    Wait-Http "http://127.0.0.1:$env:FRONTEND_PORT/"
    Wait-Http "http://127.0.0.1:$env:FRONTEND_PORT/api/v1/health"
    Write-Output "P0 ready: http://127.0.0.1:$env:FRONTEND_PORT/ (logs: .run/)"
} catch {
    & "$PSScriptRoot/stop-dev.ps1"
    throw
}
