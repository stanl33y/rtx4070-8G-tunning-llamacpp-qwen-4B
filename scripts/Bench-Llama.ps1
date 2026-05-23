param(
    [ValidateSet("rtx", "igpu")]
    [string]$Device = "rtx",

    [int]$PromptTokens = 512,
    [int]$GenTokens = 128,
    [int]$Repetitions = 3,
    [string]$VulkanDevice = "",
    [string]$Output = ""
)

. "$PSScriptRoot\..\config\server.ps1"

if (-not (Test-Path $ModelPath)) {
    Write-Error "Model not found: $ModelPath. Run .\setup.ps1 first."
    exit 1
}

if ($Device -eq "rtx") {
    $benchPath = Join-Path (Split-Path $CudaServerPath) "llama-bench.exe"
    $benchArgs = @(
        "-m", $ModelPath,
        "-ngl", "99",
        "-p", "$PromptTokens",
        "-n", "$GenTokens",
        "-r", "$Repetitions",
        "-fa", "1",
        "-ctk", "q8_0",
        "-ctv", "q8_0",
        "-o", "md"
    )
} else {
    $benchPath = Join-Path (Split-Path $VulkanServerPath) "llama-bench.exe"
    if ($VulkanDevice -eq "") {
        $VulkanDevice = $DefaultIgpuVulkanDevice
    }
    $env:GGML_VK_VISIBLE_DEVICES = $VulkanDevice
    $benchArgs = @(
        "-m", $ModelPath,
        "-ngl", "99",
        "-p", "$PromptTokens",
        "-n", "$GenTokens",
        "-r", "$Repetitions",
        "-ctk", "f16",
        "-ctv", "f16",
        "-o", "md"
    )
}

if (-not (Test-Path $benchPath)) {
    Write-Error "llama-bench.exe not found: $benchPath"
    exit 1
}

Push-Location (Split-Path $benchPath)
try {
    $result = & $benchPath @benchArgs
} finally {
    Pop-Location
    if ($Device -eq "igpu") {
        Remove-Item Env:\GGML_VK_VISIBLE_DEVICES -ErrorAction SilentlyContinue
    }
}

if ($Output -ne "") {
    $outputDir = Split-Path $Output
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    $result | Set-Content -Path $Output
}

$result
