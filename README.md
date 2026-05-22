# llama.cpp local server

Local inference server using [llama.cpp](https://github.com/ggerganov/llama.cpp) with Qwen3.5-4B on RTX 4070 8GB.

## Requirements

- Windows 10/11 x64
- NVIDIA GPU with CUDA 12.4 drivers
- PowerShell 5+
- ~3 GB disk space for model

## Setup

```powershell
.\setup.ps1
```

Downloads and extracts:
- llama.cpp release `b9284` (CUDA 12.4) from GitHub
- Model `Qwen3.5-4B-Q4_K_M.gguf` (~2.6 GB) from [unsloth/Qwen3.5-4B-GGUF](https://huggingface.co/unsloth/Qwen3.5-4B-GGUF) into `%USERPROFILE%\models\`

If model already exists, download is skipped.

## Usage

```powershell
.\start-server.ps1
```

Server starts at `http://localhost:8080` with an OpenAI-compatible API.

| Parameter | Value | Notes |
|-----------|-------|-------|
| Model | Qwen3.5-4B Q4_K_M | 4-bit quantized, ~2.6 GB |
| Context | 131K tokens | Full context window |
| GPU layers | 99 | Entire model on GPU |
| KV cache | q8_0 | 8-bit KV — saves VRAM, minimal quality loss |
| MTP | draft-mtp, 3 tokens | Multi-token prediction speculative decoding |
| Flash attention | on | Faster attention, lower VRAM |
| Parallel | 1 | Single concurrent request |

### API usage example

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5-4b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

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

## Troubleshooting

**CUDA not found / runs on CPU**
Verify CUDA 12.4 drivers are installed: `nvidia-smi` should show driver version ≥ 550.

**Out of memory (OOM)**
Reduce context: change `-c 131072` to `-c 65536` in `start-server.ps1`.

**Port already in use**
Change `--port 8080` to another port in `start-server.ps1` and update `baseURL` in OpenCode config.
