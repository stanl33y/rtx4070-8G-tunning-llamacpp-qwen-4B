$version = "b9284"
$zip = "llama-$version-bin-win-vulkan-x64.zip"
$url = "https://github.com/ggerganov/llama.cpp/releases/download/$version/$zip"
$destination = "$PSScriptRoot\bin\igpu"

$ProgressPreference = "SilentlyContinue"

if (-not (Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination | Out-Null
}

Write-Host "Downloading llama.cpp $version (Vulkan/iGPU)..."
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -ErrorAction Stop

Write-Host "Extracting to $destination ..."
Expand-Archive -Path $zip -DestinationPath $destination -Force
Remove-Item $zip

Write-Host "Done. Run: .\start-server-igpu.ps1"
