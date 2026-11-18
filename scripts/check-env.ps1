. "$PSScriptRoot/common.ps1"
Set-ToolEnvironment
$ErrorActionPreference='Continue'
$javaVersion = & java.exe -version 2>&1 | Out-String
$ErrorActionPreference='Stop'
if ($javaVersion -notmatch 'version "17\.') { throw 'JDK 17 required.' }
if (!(Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin/javac.exe'))) { throw 'Full JDK 17 (javac) required.' }
Write-Output 'JDK 17 available (process-local JAVA_HOME)'
Invoke-Checked 'mvn.cmd' @('-version')
$nodeVersion = & node.exe --version
if ($nodeVersion -notmatch '^v(22|24)\.') { throw 'Use Node 22 LTS or 24 LTS.' }
Write-Output "Node $nodeVersion"
Invoke-Checked 'npm.cmd' @('--version')
if (!(Test-Path -LiteralPath $script:Python)) { throw 'Create ai-engine/.venv with Python 3.12 first.' }
$pyVersion = & $script:Python --version
if ($pyVersion -notmatch '^Python 3\.12\.') { throw 'Python 3.12 required.' }
Write-Output $pyVersion
Invoke-Checked 'docker.exe' @('compose','version')
Invoke-Checked 'docker.exe' @('info','--format','{{.ServerVersion}}')
if (!(Get-Command ffmpeg.exe -ErrorAction SilentlyContinue)) { throw 'FFmpeg required.' }
$ffmpeg = & ffmpeg.exe -version
Write-Output $ffmpeg[0]
Write-Output 'Compose and environment checks passed.'
