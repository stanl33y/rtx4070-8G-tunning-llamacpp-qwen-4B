$ModelPath = "$env:USERPROFILE\models\Qwen3.5-4B-Q4_K_M.gguf"
$HostAddress = "0.0.0.0"
$DefaultPort = 8080

$CudaServerPath = Join-Path $PSScriptRoot "..\bin\cuda\llama-server.exe"
$VulkanServerPath = Join-Path $PSScriptRoot "..\bin\igpu\llama-server.exe"

$RtxContext = 131072
$IgpuContext = 32768
$DefaultIgpuVulkanDevice = "0"
