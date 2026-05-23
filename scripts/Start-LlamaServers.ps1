param(
    [int]$RtxPort = 8080,
    [int]$IgpuPort = 8081,
    [string]$VulkanDevice = ""
)

$root = Resolve-Path "$PSScriptRoot\.."
$logsDir = Join-Path $root "logs"
$runDir = Join-Path $root "run"

foreach ($path in @($logsDir, $runDir)) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

$rtxOutLog = Join-Path $logsDir "server-rtx-$RtxPort.out.log"
$rtxErrLog = Join-Path $logsDir "server-rtx-$RtxPort.err.log"
$igpuOutLog = Join-Path $logsDir "server-igpu-$IgpuPort.out.log"
$igpuErrLog = Join-Path $logsDir "server-igpu-$IgpuPort.err.log"

$rtxArgs = @(
    "-NoLogo",
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $root "scripts\Start-LlamaServer.ps1"),
    "-Device", "rtx",
    "-Port", "$RtxPort"
)

$igpuArgs = @(
    "-NoLogo",
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $root "scripts\Start-LlamaServer.ps1"),
    "-Device", "igpu",
    "-Port", "$IgpuPort"
)

if ($VulkanDevice -ne "") {
    $igpuArgs += @("-VulkanDevice", $VulkanDevice)
}

$rtxProcess = Start-Process -FilePath "powershell.exe" -ArgumentList $rtxArgs -WorkingDirectory $root -RedirectStandardOutput $rtxOutLog -RedirectStandardError $rtxErrLog -WindowStyle Hidden -PassThru -ErrorAction Stop
$igpuProcess = Start-Process -FilePath "powershell.exe" -ArgumentList $igpuArgs -WorkingDirectory $root -RedirectStandardOutput $igpuOutLog -RedirectStandardError $igpuErrLog -WindowStyle Hidden -PassThru -ErrorAction Stop

Set-Content -Path (Join-Path $runDir "server-rtx.pid") -Value $rtxProcess.Id
Set-Content -Path (Join-Path $runDir "server-igpu.pid") -Value $igpuProcess.Id

Write-Host "RTX server starting at http://localhost:$RtxPort/v1 (PID $($rtxProcess.Id))"
Write-Host "iGPU server starting at http://localhost:$IgpuPort/v1 (PID $($igpuProcess.Id))"
Write-Host "Logs:"
Write-Host "  $rtxOutLog"
Write-Host "  $rtxErrLog"
Write-Host "  $igpuOutLog"
Write-Host "  $igpuErrLog"
Write-Host "Stop both with: .\scripts\Stop-LlamaServers.ps1"
