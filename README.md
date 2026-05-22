# llama.cpp local server

Local inference server using [llama.cpp](https://github.com/ggerganov/llama.cpp).

## Requirements

- Windows 10/11 x64
- NVIDIA GPU with CUDA 12.4
- PowerShell 5+
- Model: `%USERPROFILE%\models\Qwen3.5-4B-Q4_K_M.gguf`

## Setup

```powershell
.\setup.ps1
```

Downloads and extracts release `b9284` (CUDA 12.4) from the official repository.

## Usage

```powershell
.\start-server.ps1
```

Server starts at `http://localhost:8080`.

| Parameter | Value |
|-----------|-------|
| Model | Qwen3.5-4B Q4_K_M |
| Context | 131K tokens |
| GPU layers | 99 (all on GPU) |
| KV cache | q8_0 |
| MTP | draft-mtp, 3 tokens |
| Flash attention | on |

## OpenCode Integration

Add the `llama-local` provider to `opencode.json` (`~/.config/opencode/opencode.json`):

```json
{
  "provider": {
    "llama-local": {
      "name": "LLaMA Local",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://localhost:8080/v1",
        "apiKey": "none"
      },
      "models": {
        "qwen3.5-4b": {
          "name": "Qwen3.5-4B (local)",
          "limit": {
            "context": 131072,
            "output": 8192
          }
        }
      }
    }
  }
}
```

Optional — dedicated agent that only uses local tools (no internet):

```json
{
  "agent": {
    "llama": {
      "description": "Local file agent — reads and edits files without internet",
      "model": "llama-local/qwen3.5-4b",
      "mode": "all",
      "prompt": "/no_think You are a local file editing agent. You ONLY use read, write, edit, and glob tools. Never use web search, fetch, or any external tools.",
      "permission": {
        "webfetch": "deny",
        "websearch": "deny",
        "google_search": "deny"
      }
    }
  }
}
```

Model appears in the selector as **LLaMA Local → Qwen3.5-4B (local)**. Requires server running (`.\start-server.ps1`).
