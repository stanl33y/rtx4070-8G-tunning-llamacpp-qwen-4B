$version = "b9284"
$zip = "llama-$version-bin-win-cuda-12.4-x64.zip"
$url = "https://github.com/ggerganov/llama.cpp/releases/download/$version/$zip"

$modelDir = "$env:USERPROFILE\models"
$modelFile = "$modelDir\Qwen3.5-4B-Q4_K_M.gguf"
$modelUrl = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf"

# Download llama.cpp binaries
Write-Host "Downloading llama.cpp $version (CUDA 12.4)..."
Invoke-WebRequest -Uri $url -OutFile $zip -ShowProgress:$false

Write-Host "Extracting..."
Expand-Archive -Path $zip -DestinationPath . -Force
Remove-Item $zip

# Download model
if (Test-Path $modelFile) {
    Write-Host "Model already exists at $modelFile, skipping."
} else {
    if (-not (Test-Path $modelDir)) { New-Item -ItemType Directory -Path $modelDir | Out-Null }
    Write-Host "Downloading Qwen3.5-4B-Q4_K_M (~2.6 GB)..."
    Invoke-WebRequest -Uri $modelUrl -OutFile $modelFile -ShowProgress:$false
    Write-Host "Model saved to $modelFile"
}

Write-Host "Done. Run: .\start-server.ps1"
