param(
    [ValidateSet("rtx", "igpu", "all")]
    [string]$Device = "all"
)

. "$PSScriptRoot\..\config\server.ps1"

function Show-Devices($Name, $ServerPath) {
    Write-Host ""
    Write-Host "== $Name =="

    if (-not (Test-Path $ServerPath)) {
        Write-Host "Not installed: $ServerPath"
        return
    }

    Push-Location (Split-Path $ServerPath)
    try {
        & $ServerPath --list-devices
    } finally {
        Pop-Location
    }
}

if ($Device -eq "rtx" -or $Device -eq "all") {
    Show-Devices "RTX/CUDA" $CudaServerPath
}

if ($Device -eq "igpu" -or $Device -eq "all") {
    Show-Devices "iGPU/Vulkan" $VulkanServerPath
}
