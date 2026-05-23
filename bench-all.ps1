param(
    [int]$PromptTokens = 512,
    [int]$GenTokens = 128,
    [int]$Repetitions = 3,
    [int]$ReasoningRequests = 5,
    [string]$VulkanDevice = ""
)

$root       = $PSScriptRoot
$resultsDir = Join-Path $root "benchmark-results"
if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir | Out-Null
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "========================================="
Write-Host " bench-all — full benchmark suite"
Write-Host " $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "========================================="
Write-Host ""

# 1. RTX tokens/s
Write-Host "--- [1/4] RTX/CUDA tokens/s ---"
$rtxOut = Join-Path $resultsDir "bench-rtx-$ts.md"
& "$root\scripts\Bench-Llama.ps1" -Device rtx -PromptTokens $PromptTokens -GenTokens $GenTokens -Repetitions $Repetitions -Output $rtxOut
Write-Host ""

# 2. iGPU tokens/s
Write-Host "--- [2/4] iGPU/Vulkan tokens/s ---"
$igpuOut = Join-Path $resultsDir "bench-igpu-$ts.md"
& "$root\scripts\Bench-Llama.ps1" -Device igpu -PromptTokens $PromptTokens -GenTokens $GenTokens -Repetitions $Repetitions -VulkanDevice $VulkanDevice -Output $igpuOut
Write-Host ""

# 3. Quantization comparison (RTX only — needs server binaries)
Write-Host "--- [3/4] Q4_K_M vs Q8_0 ---"
$quantOut = Join-Path $resultsDir "bench-quant-$ts.md"
& "$root\scripts\Bench-Quant.ps1" -PromptTokens $PromptTokens -GenTokens $GenTokens -Repetitions $Repetitions -Output $quantOut
Write-Host ""

# 4. Reasoning on vs off (requires server running on :8080)
Write-Host "--- [4/4] Reasoning ON vs OFF ---"
$reasonOut = Join-Path $resultsDir "bench-reasoning-$ts.md"
& "$root\scripts\Bench-Reasoning.ps1" -Requests $ReasoningRequests -Output $reasonOut
Write-Host ""

Write-Host "========================================="
Write-Host " All benchmarks complete."
Write-Host " Results saved to: $resultsDir"
Write-Host "========================================="
