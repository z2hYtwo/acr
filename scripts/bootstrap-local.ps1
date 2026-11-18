param([string]$PythonBootstrap='python.exe')
$ErrorActionPreference='Continue'
$root=Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $root
New-Item -ItemType Directory -Force .tools/uv,.tools/docker/cli-plugins | Out-Null
if (!(Test-Path -LiteralPath '.tools/uv/bin/uv.exe')) {
    & $PythonBootstrap -m pip install --index-url https://pypi.org/simple --target .tools/uv uv==0.9.17
    if ($LASTEXITCODE -ne 0) { throw 'uv installation failed' }
}
$env:UV_PYTHON_INSTALL_DIR=Join-Path $root '.tools/python'
& .tools/uv/bin/uv.exe python install 3.12.12
if ($LASTEXITCODE -ne 0) { throw 'Python installation failed' }
& .tools/uv/bin/uv.exe venv ai-engine/.venv --python 3.12.12
if ($LASTEXITCODE -ne 0) { throw 'Virtual environment creation failed' }
& .tools/uv/bin/uv.exe pip sync --python ai-engine/.venv/Scripts/python.exe --index-url https://pypi.org/simple ai-engine/requirements-lock.txt
if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed' }
$release='https://github.com/docker/compose/releases/download/v2.39.4'
$binary='docker-compose-windows-x86_64.exe'
Invoke-WebRequest "$release/$binary" -OutFile '.tools/docker/cli-plugins/docker-compose.exe'
Invoke-WebRequest "$release/$binary.sha256" -OutFile '.tools/docker/compose.sha256'
$expected=((Get-Content -Raw '.tools/docker/compose.sha256').Trim() -split '\s+')[0]
$actual=(Get-FileHash '.tools/docker/cli-plugins/docker-compose.exe' -Algorithm SHA256).Hash
if ($actual -ne $expected) { throw 'Compose SHA256 mismatch' }
$userDocker=Join-Path $env:USERPROFILE '.docker'
if (Test-Path -LiteralPath "$userDocker/config.json") { Copy-Item -LiteralPath "$userDocker/config.json" -Destination '.tools/docker/config.json' }
if ((Test-Path -LiteralPath "$userDocker/contexts") -and !(Test-Path -LiteralPath '.tools/docker/contexts')) { Copy-Item -LiteralPath "$userDocker/contexts" -Destination '.tools/docker/contexts' -Recurse }
if (!(Test-Path -LiteralPath '.env')) {
    $rng=[Security.Cryptography.RandomNumberGenerator]::Create()
    function Random-Hex { $bytes=New-Object byte[] 32; $rng.GetBytes($bytes); return [BitConverter]::ToString($bytes).Replace('-','').ToLowerInvariant() }
    $text=Get-Content -Raw -LiteralPath '.env.example'
    $text=$text.Replace('replace-with-random-local-password',(Random-Hex)).Replace('replace-with-random-local-token',(Random-Hex))
    [IO.File]::WriteAllText((Join-Path $root '.env'),$text,(New-Object Text.UTF8Encoding $false))
    $rng.Dispose()
}
Write-Output 'Project-local Python and Compose installed. No model credentials required.'
