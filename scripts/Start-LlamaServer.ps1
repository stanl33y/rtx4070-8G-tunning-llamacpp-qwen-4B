param(
    [ValidateSet("rtx", "igpu")]
    [string]$Device = "rtx",

    [int]$Port = 0,

    [string]$VulkanDevice = ""
)

. "$PSScriptRoot\..\config\server.ps1"

if ($Port -eq 0) {
    $Port = $DefaultPort
}

if (-not (Test-Path $ModelPath)) {
    Write-Error "Model not found: $ModelPath. Run .\setup.ps1 first."
    exit 1
}

$commonArgs = @(
    "-m", $ModelPath,
    "--parallel", "1",
    "--no-mmap",
    "--jinja",
    "--reasoning", "off",
    "--host", $HostAddress,
    "--port", "$Port"
)

if ($Device -eq "rtx") {
    if (-not (Test-Path $CudaServerPath)) {
        Write-Error "CUDA llama-server.exe not found: $CudaServerPath. Run .\setup.ps1 first."
        exit 1
    }

    Write-Host "Starting Qwen3.5-4B on RTX/CUDA at http://localhost:$Port ..."
    Write-Host "Context: $RtxContext | GPU layers: 99 | MTP: on | KV: q8_0 | Reasoning: off"
    Write-Host "Press Ctrl+C to stop."

    Push-Location (Split-Path $CudaServerPath)
    try {
        & $CudaServerPath @commonArgs `
            -ngl 99 `
            -c $RtxContext `
            -fa on `
            --spec-type draft-mtp `
            --spec-draft-n-max 3 `
            -ctk q8_0 `
            -ctv q8_0
    } finally {
        Pop-Location
    }

    exit $LASTEXITCODE
}

if (-not (Test-Path $VulkanServerPath)) {
    Write-Error "Vulkan llama-server.exe not found: $VulkanServerPath. Run .\setup-igpu-vulkan.ps1 first."
    exit 1
}

if ($VulkanDevice -eq "") {
    $VulkanDevice = $DefaultIgpuVulkanDevice
}

if ($VulkanDevice -ne "") {
    $env:GGML_VK_VISIBLE_DEVICES = $VulkanDevice
}

Write-Host "Starting Qwen3.5-4B on iGPU/Vulkan at http://localhost:$Port ..."
Write-Host "Context: $IgpuContext | GPU layers: 99 | Vulkan device: $VulkanDevice | MTP: off | KV: f16 | Reasoning: off"
Write-Host "Press Ctrl+C to stop."

Push-Location (Split-Path $VulkanServerPath)
try {
    & $VulkanServerPath @commonArgs `
        -ngl 99 `
        -c $IgpuContext `
        -ctk f16 `
        -ctv f16
} finally {
    Pop-Location
}

exit $LASTEXITCODE
