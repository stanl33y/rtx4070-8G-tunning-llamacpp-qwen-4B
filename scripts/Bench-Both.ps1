param(
    [int]$PromptTokens = 512,
    [int]$GenTokens = 128,
    [int]$Repetitions = 3,
    [string]$VulkanDevice = ""
)

$root = Resolve-Path "$PSScriptRoot\.."
$resultsDir = Join-Path $root "benchmark-results"

if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir | Out-Null
}

$rtxOutput = Join-Path $resultsDir "bench-rtx-parallel.md"
$igpuOutput = Join-Path $resultsDir "bench-igpu-parallel.md"

$rtxJob = Start-Job -ScriptBlock {
    param($root, $promptTokens, $genTokens, $repetitions, $output)
    & (Join-Path $root "scripts\Bench-Llama.ps1") -Device rtx -PromptTokens $promptTokens -GenTokens $genTokens -Repetitions $repetitions -Output $output
} -ArgumentList $root, $PromptTokens, $GenTokens, $Repetitions, $rtxOutput

$igpuJob = Start-Job -ScriptBlock {
    param($root, $promptTokens, $genTokens, $repetitions, $vulkanDevice, $output)
    & (Join-Path $root "scripts\Bench-Llama.ps1") -Device igpu -PromptTokens $promptTokens -GenTokens $genTokens -Repetitions $repetitions -VulkanDevice $vulkanDevice -Output $output
} -ArgumentList $root, $PromptTokens, $GenTokens, $Repetitions, $VulkanDevice, $igpuOutput

Wait-Job $rtxJob, $igpuJob | Out-Null

Write-Host "== RTX parallel benchmark =="
Receive-Job $rtxJob
Write-Host ""
Write-Host "== iGPU parallel benchmark =="
Receive-Job $igpuJob

Remove-Job $rtxJob, $igpuJob

Write-Host ""
Write-Host "Saved results:"
Write-Host "  $rtxOutput"
Write-Host "  $igpuOutput"
