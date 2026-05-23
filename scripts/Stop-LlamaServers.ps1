$root = Resolve-Path "$PSScriptRoot\.."
$runDir = Join-Path $root "run"
. "$PSScriptRoot\..\config\server.ps1"

function Get-ChildProcessIds {
    param([int]$ParentProcessId)

    $children = Get-CimInstance Win32_Process -Filter "ParentProcessId = $ParentProcessId" -ErrorAction SilentlyContinue
    foreach ($child in $children) {
        Get-ChildProcessIds -ParentProcessId $child.ProcessId
        $child.ProcessId
    }
}

foreach ($name in @("server-rtx.pid", "server-igpu.pid")) {
    $pidFile = Join-Path $runDir $name
    if (-not (Test-Path $pidFile)) {
        continue
    }

    $processId = Get-Content -Path $pidFile -ErrorAction SilentlyContinue
    if ($processId) {
        $childProcessIds = @(Get-ChildProcessIds -ParentProcessId ([int]$processId))
        foreach ($childProcessId in $childProcessIds) {
            $childProcess = Get-Process -Id $childProcessId -ErrorAction SilentlyContinue
            if ($childProcess) {
                Stop-Process -Id $childProcessId -Force -ErrorAction SilentlyContinue
                Write-Host "Stopped child PID $childProcessId"
            }
        }

        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
            Write-Host "Stopped $name PID $processId"
        }
    }

    Remove-Item -LiteralPath $pidFile -ErrorAction SilentlyContinue
}

$backendServerPaths = @(
    [System.IO.Path]::GetFullPath($CudaServerPath),
    [System.IO.Path]::GetFullPath($VulkanServerPath)
)

Get-Process -Name "llama-server" -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Path -and ($backendServerPaths -contains [System.IO.Path]::GetFullPath($_.Path))) {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped backend server PID $($_.Id)"
    }
}
