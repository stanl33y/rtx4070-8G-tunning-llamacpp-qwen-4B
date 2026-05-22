$model = "$env:USERPROFILE\models\Qwen3.5-4B-Q4_K_M.gguf"
$llama = "$PSScriptRoot\llama-server.exe"

Write-Host "Starting Qwen3.5-4B MTP on http://localhost:8080 ..."
Write-Host "Context: 131K | MTP: on | KV: q8_0 | Reasoning: off"
Write-Host "Press Ctrl+C to stop."

& $llama `
  -m $model `
  -ngl 99 `
  -c 131072 `
  --parallel 1 `
  -fa on `
  --no-mmap `
  --jinja `
  --reasoning off `
  --spec-type draft-mtp `
  --spec-draft-n-max 3 `
  -ctk q8_0 `
  -ctv q8_0 `
  --host 0.0.0.0 `
  --port 8080
