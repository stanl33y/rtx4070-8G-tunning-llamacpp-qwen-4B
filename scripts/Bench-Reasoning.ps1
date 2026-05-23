param(
    [string]$BaseUrl = "http://localhost:8080",
    [int]$Requests = 5,
    [string]$Prompt = "Explain how transformers work in neural networks.",
    [int]$MaxTokens = 256,
    [string]$Output = ""
)

function Invoke-ChatRequest {
    param([string]$Url, [string]$SystemPrompt, [string]$UserPrompt, [int]$MaxTok)

    $body = @{
        model    = "qwen3.5-4b"
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user";   content = $UserPrompt }
        )
        max_tokens  = $MaxTok
        temperature = 0.0
        stream      = $false
    } | ConvertTo-Json -Depth 5

    $start = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $resp = Invoke-RestMethod -Uri "$Url/v1/chat/completions" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 120
    } catch {
        Write-Warning "Request failed: $_"
        return $null
    }
    $start.Stop()

    $usage    = $resp.usage
    $elapsed  = $start.Elapsed.TotalSeconds
    $genTok   = $usage.completion_tokens
    $tps      = [math]::Round($genTok / $elapsed, 1)
    $ttft     = $elapsed  # llama.cpp doesn't expose TTFT via REST without streaming

    return [PSCustomObject]@{
        ElapsedSec     = [math]::Round($elapsed, 2)
        CompletionToks = $genTok
        TotalToks      = $usage.total_tokens
        TokensPerSec   = $tps
    }
}

# Check server reachable
try {
    Invoke-RestMethod -Uri "$BaseUrl/v1/models" -TimeoutSec 5 | Out-Null
} catch {
    Write-Error "Server not reachable at $BaseUrl. Run .\start-server.ps1 first."
    exit 1
}

Write-Host "Reasoning benchmark — $Requests requests per mode"
Write-Host "Prompt: `"$Prompt`""
Write-Host ""

$noThinkResults = @()
$thinkResults   = @()

# no_think
Write-Host "Mode: /no_think (reasoning OFF)"
for ($i = 1; $i -le $Requests; $i++) {
    $r = Invoke-ChatRequest -Url $BaseUrl -SystemPrompt "/no_think" -UserPrompt $Prompt -MaxTok $MaxTokens
    if ($r) {
        $noThinkResults += $r
        Write-Host "  [$i/$Requests] $($r.ElapsedSec)s | $($r.CompletionToks) tokens | $($r.TokensPerSec) t/s"
    }
}

Write-Host ""
Write-Host "Mode: /think (reasoning ON)"
for ($i = 1; $i -le $Requests; $i++) {
    $r = Invoke-ChatRequest -Url $BaseUrl -SystemPrompt "/think" -UserPrompt $Prompt -MaxTok $MaxTokens
    if ($r) {
        $thinkResults += $r
        Write-Host "  [$i/$Requests] $($r.ElapsedSec)s | $($r.CompletionToks) tokens | $($r.TokensPerSec) t/s"
    }
}

function Get-Stats {
    param($results)
    $tps  = $results | ForEach-Object { $_.TokensPerSec }
    $avg  = [math]::Round(($tps | Measure-Object -Average).Average, 1)
    $min  = [math]::Round(($tps | Measure-Object -Minimum).Minimum, 1)
    $max  = [math]::Round(($tps | Measure-Object -Maximum).Maximum, 1)
    $avgT = [math]::Round(($results | ForEach-Object { $_.CompletionToks } | Measure-Object -Average).Average, 0)
    return [PSCustomObject]@{ AvgTps = $avg; MinTps = $min; MaxTps = $max; AvgTokens = $avgT }
}

$ntStats = Get-Stats $noThinkResults
$tStats  = Get-Stats $thinkResults

$lines = @(
    "",
    "## Results",
    "",
    "| Mode | Avg t/s | Min t/s | Max t/s | Avg completion tokens |",
    "|------|---------|---------|---------|----------------------|",
    "| /no_think (reasoning OFF) | $($ntStats.AvgTps) | $($ntStats.MinTps) | $($ntStats.MaxTps) | $($ntStats.AvgTokens) |",
    "| /think    (reasoning ON)  | $($tStats.AvgTps) | $($tStats.MinTps) | $($tStats.MaxTps) | $($tStats.AvgTokens) |",
    ""
)

$speedup = if ($tStats.AvgTps -gt 0) {
    [math]::Round($ntStats.AvgTps / $tStats.AvgTps, 2)
} else { "N/A" }

$lines += "no_think is **${speedup}x faster** than think (fewer tokens generated)."
$lines += ""

$lines | ForEach-Object { Write-Host $_ }

if ($Output -ne "") {
    $outputDir = Split-Path $Output
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    $header = @(
        "# Reasoning Benchmark — Qwen3.5-4B",
        "Server: $BaseUrl | requests=$Requests | max_tokens=$MaxTokens",
        "Prompt: `"$Prompt`"",
        ""
    )
    ($header + $lines) | Set-Content -Path $Output
    Write-Host "Saved: $Output"
}
