$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$loader = Join-Path $root 'variable_tools.rb'
$extension = Join-Path $root 'variable_tools'
$main = Join-Path $extension 'main.rb'
$dist = Join-Path $root 'dist'
$output = Join-Path $dist 'variable_tools.rbz'
$tempZip = Join-Path $dist ("variable_tools-{0}.zip" -f [guid]::NewGuid())
try {
    if (-not (Test-Path -LiteralPath $loader -PathType Leaf) -or -not (Test-Path -LiteralPath $main -PathType Leaf)) {
        throw 'Missing variable_tools.rb or variable_tools/main.rb.'
    }
    New-Item -ItemType Directory -Force -Path $dist | Out-Null
    Compress-Archive -LiteralPath $loader, $extension -DestinationPath $tempZip -CompressionLevel Optimal
    Move-Item -LiteralPath $tempZip -Destination $output -Force
    Write-Host "Built $output"
} catch {
    Write-Error $_
    exit 1
} finally {
    if (Test-Path -LiteralPath $tempZip) { Remove-Item -LiteralPath $tempZip -Force }
}
