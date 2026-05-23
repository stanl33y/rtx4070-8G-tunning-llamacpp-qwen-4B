$version = "b9284"
$zip = "llama-$version-bin-win-cuda-12.4-x64.zip"
$url = "https://github.com/ggerganov/llama.cpp/releases/download/$version/$zip"
$runtimeZip = "cudart-llama-bin-win-cuda-12.4-x64.zip"
$runtimeUrl = "https://github.com/ggerganov/llama.cpp/releases/download/$version/$runtimeZip"
$destination = "$PSScriptRoot\bin\cuda"

$modelDir = "$env:USERPROFILE\models"
$modelFile = "$modelDir\Qwen3.5-4B-Q4_K_M.gguf"
$modelUrl = "https://huggingface.co/unsloth/Qwen3.5-4B-MTP-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf"

$ProgressPreference = "SilentlyContinue"

if (-not (Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination | Out-Null
}

# Download llama.cpp binaries
Write-Host "Downloading llama.cpp $version (CUDA 12.4)..."
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -ErrorAction Stop

Write-Host "Extracting to $destination ..."
Expand-Archive -Path $zip -DestinationPath $destination -Force
Remove-Item $zip

Write-Host "Downloading CUDA runtime DLLs..."
Invoke-WebRequest -Uri $runtimeUrl -OutFile $runtimeZip -UseBasicParsing -ErrorAction Stop

Write-Host "Extracting CUDA runtime DLLs to $destination ..."
Expand-Archive -Path $runtimeZip -DestinationPath $destination -Force
Remove-Item $runtimeZip

# Download model
if (Test-Path $modelFile) {
    Write-Host "Model already exists at $modelFile, skipping."
} else {
    if (-not (Test-Path $modelDir)) { New-Item -ItemType Directory -Path $modelDir | Out-Null }
    Write-Host "Downloading Qwen3.5-4B-Q4_K_M (~2.6 GB)..."
    Invoke-WebRequest -Uri $modelUrl -OutFile $modelFile -UseBasicParsing -ErrorAction Stop
    Write-Host "Model saved to $modelFile"
}

Write-Host "Done. Run: .\start-server.ps1"
