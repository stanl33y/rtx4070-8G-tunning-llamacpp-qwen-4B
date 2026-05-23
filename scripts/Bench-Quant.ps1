param(
    [int]$PromptTokens = 512,
    [int]$GenTokens = 128,
    [int]$Repetitions = 3,
    [string]$Output = ""
)

. "$PSScriptRoot\..\config\server.ps1"

$modelDir  = "$env:USERPROFILE\models"
$q4Model   = "$modelDir\Qwen3.5-4B-Q4_K_M.gguf"
$q8Model   = "$modelDir\Qwen3.5-4B-Q8_0.gguf"
$q8Url     = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q8_0.gguf"
$benchPath = Join-Path (Split-Path $CudaServerPath) "llama-bench.exe"

if (-not (Test-Path $benchPath)) {
    Write-Error "llama-bench.exe not found: $benchPath. Run .\setup.ps1 first."
    exit 1
}
if (-not (Test-Path $q4Model)) {
    Write-Error "Q4_K_M model not found: $q4Model. Run .\setup.ps1 first."
    exit 1
}
if (-not (Test-Path $q8Model)) {
    Write-Host "Q8_0 model not found. Downloading (~4.5 GB)..."
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $q8Url -OutFile $q8Model -UseBasicParsing -ErrorAction Stop
    Write-Host "Downloaded: $q8Model"
}

$commonArgs = @(
    "-ngl", "99",
    "-p", "$PromptTokens",
    "-n", "$GenTokens",
    "-r", "$Repetitions",
    "-fa", "1",
    "-ctk", "q8_0",
    "-ctv", "q8_0",
    "-o", "md"
)

Write-Host "Benchmarking Q4_K_M vs Q8_0 on RTX (CUDA)..."
Write-Host ""

Push-Location (Split-Path $benchPath)
try {
    $q4Args = @("-m", $q4Model) + $commonArgs
    $q8Args = @("-m", $q8Model) + $commonArgs
    $result  = & $benchPath @q4Args
    $result += ""
    $result += & $benchPath @q8Args
} finally {
    Pop-Location
}

# label the two tables
$labeled = @()
$tableCount = 0
foreach ($line in $result) {
    if ($line -match "^\| model") {
        $tableCount++
        $label = if ($tableCount -eq 1) { "### Q4_K_M" } else { "### Q8_0" }
        $labeled += $label
    }
    $labeled += $line
}

$output_lines = @(
    "# Quantization Benchmark — Qwen3.5-4B",
    "RTX/CUDA | prompt=$PromptTokens | gen=$GenTokens | rep=$Repetitions",
    ""
) + $labeled

$output_lines | ForEach-Object { Write-Host $_ }

if ($Output -ne "") {
    $outputDir = Split-Path $Output
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    $output_lines | Set-Content -Path $Output
    Write-Host ""
    Write-Host "Saved: $Output"
}
