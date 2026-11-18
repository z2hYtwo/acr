param([switch]$SkipTests)
. "$PSScriptRoot/common.ps1"
Import-LocalEnvironment
& "$PSScriptRoot/check-env.ps1"
Set-ToolEnvironment
Invoke-Checked 'docker.exe' @('compose','config','--quiet')
Invoke-Checked 'docker.exe' @('compose','up','-d','--wait','--wait-timeout','150')
if (!$SkipTests) {
    & "$PSScriptRoot/stop-dev.ps1"
    Invoke-Checked 'mvn.cmd' @('-f','backend/pom.xml','verify','-B')
    Push-Location frontend
    try {
        Invoke-Checked 'npm.cmd' @('ci','--no-audit','--no-fund')
        foreach ($step in 'typecheck','lint','build') { Invoke-Checked 'npm.cmd' @('run',$step) }
        Invoke-Checked 'npm.cmd' @('run','test','--','--run')
    } finally { Pop-Location }
    Push-Location ai-engine
    try { Invoke-Checked $script:Python @('-m','pytest','-q') } finally { Pop-Location }
}
if (!$SkipTests) { & "$PSScriptRoot/start-dev.ps1" -SkipBuild }
$script:checks=@()
function Check-Http {
    param([string]$Url,[int]$Expected,[hashtable]$Headers=@{})
    $status=0
    try { $r=Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $Headers -TimeoutSec 10; $status=[int]$r.StatusCode } catch {
        if ($_.Exception.Response) { $status=[int]$_.Exception.Response.StatusCode } else { throw }
    }
    if ($status -ne $Expected) { throw "Unexpected HTTP $status (expected $Expected) for $Url" }
    $script:checks += @{url=$Url;status=$status;expected=$Expected}
}
Check-Http "http://127.0.0.1:$env:BACKEND_PORT/api/v1/health" 200
Check-Http "http://127.0.0.1:$env:FRONTEND_PORT/" 200
Check-Http "http://127.0.0.1:$env:FRONTEND_PORT/api/v1/health" 200
foreach ($port in @($env:BACKEND_PORT,$env:AI_ENGINE_PORT)) {
    $url="http://127.0.0.1:$port/internal/v1/health"
    Check-Http $url 200 @{Authorization="Bearer $env:AI_ENGINE_TOKEN"}
    Check-Http $url 401
    Check-Http $url 401 @{Authorization='Bearer wrong-token'}
}
ConvertTo-Json -InputObject @($checks) | Set-Content -LiteralPath '.run/http-checks.json' -Encoding UTF8
Write-Output 'P0 HTTP checks passed; evidence: .run/http-checks.json'
