$version = "b9284"
$zip = "llama-$version-bin-win-cuda-12.4-x64.zip"
$url = "https://github.com/ggerganov/llama.cpp/releases/download/$version/$zip"

Write-Host "Baixando llama.cpp $version (CUDA 12.4)..."
Invoke-WebRequest -Uri $url -OutFile $zip -ShowProgress:$false

Write-Host "Extraindo..."
Expand-Archive -Path $zip -DestinationPath . -Force
Remove-Item $zip

Write-Host "Pronto. Execute: .\start-server.ps1"
