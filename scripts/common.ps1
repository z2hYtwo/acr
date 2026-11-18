$ErrorActionPreference = 'Stop'
$script:Root = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $script:Root
function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    $saved=$ErrorActionPreference
    try { $ErrorActionPreference='Continue'; & $Command @Arguments } finally { $ErrorActionPreference=$saved }
    if ($LASTEXITCODE -ne 0) { throw "$Command failed (exit $LASTEXITCODE)" }
}
function Import-LocalEnvironment {
    $file = Join-Path $script:Root '.env'
    if (!(Test-Path -LiteralPath $file)) { throw 'Missing .env: copy .env.example and set random local credentials.' }
    foreach ($line in [IO.File]::ReadAllLines($file)) {
        if ($line -match '^([A-Z][A-Z0-9_]*)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        } elseif ($line.Trim() -and !$line.Trim().StartsWith('#')) { throw 'Invalid .env line (use plain KEY=value).' }
    }
    foreach ($name in 'POSTGRES_DB','POSTGRES_USER','POSTGRES_PASSWORD','AI_ENGINE_TOKEN') {
        $value = [Environment]::GetEnvironmentVariable($name)
        if ([string]::IsNullOrWhiteSpace($value) -or $value.StartsWith('replace-with-')) { throw "Configure $name in local .env" }
    }
    if (!$env:DB_PORT) { $env:DB_PORT='5432' }
    if (!$env:BACKEND_PORT) { $env:BACKEND_PORT='8080' }
    if (!$env:AI_ENGINE_PORT) { $env:AI_ENGINE_PORT='8000' }
    if (!$env:FRONTEND_PORT) { $env:FRONTEND_PORT='5173' }
}
function Set-ToolEnvironment {
    $savedPreference=$ErrorActionPreference; $ErrorActionPreference='Continue'
    if ($env:ACS_JAVA_HOME) { $env:JAVA_HOME=$env:ACS_JAVA_HOME }
    $java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin/java.exe' } else { '' }
    $version = if (Test-Path -LiteralPath $java) { (& $java -version 2>&1 | Out-String) } else { '' }
    if ($version -notmatch 'version "17\.') {
        $pathJava = (Get-Command java.exe -ErrorAction SilentlyContinue).Source
        if ($pathJava) {
            $pathVersion = & $pathJava -version 2>&1 | Out-String
            if ($pathVersion -match 'version "17\.') { $env:JAVA_HOME=Split-Path (Split-Path $pathJava -Parent) -Parent }
        }
    }
    if (!$env:JAVA_HOME) { throw 'Set ACS_JAVA_HOME to an installed JDK 17.' }
    $env:Path = "$(Join-Path $env:JAVA_HOME 'bin');$env:Path"
    $localDocker = Join-Path $script:Root '.tools/docker'
    if (Test-Path -LiteralPath (Join-Path $localDocker 'cli-plugins/docker-compose.exe')) { $env:DOCKER_CONFIG=$localDocker }
    $script:Python = Join-Path $script:Root 'ai-engine/.venv/Scripts/python.exe'
    $ErrorActionPreference=$savedPreference
}
function Wait-Http {
    param([string]$Url, [hashtable]$Headers=@{}, [int]$Timeout=90)
    $deadline=(Get-Date).AddSeconds($Timeout)
    while ((Get-Date) -lt $deadline) {
        try {
            $r=Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $Headers -TimeoutSec 3
            if ($r.StatusCode -eq 200) { return }
        } catch { }
        Start-Sleep -Milliseconds 500
    }
    throw "Service readiness timeout: $Url"
}
