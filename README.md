# llama.cpp local server — RTX 4070 8GB + Qwen3.5-4B

Local inference server using [llama.cpp](https://github.com/ggerganov/llama.cpp) tuned for RTX 4070 8GB with Qwen3.5-4B.

Exposes an OpenAI-compatible API at `http://localhost:8080/v1` — drop-in replacement for any tool that accepts a custom `baseURL`.

---

## Requirements

| Requirement | Notes |
|-------------|-------|
| Windows 10/11 x64 | |
| NVIDIA GPU — RTX 4070 8GB | Any GPU with ≥6 GB VRAM and CUDA 12.4 should work |
| CUDA 12.4 drivers | `nvidia-smi` must show driver ≥ 550 |
| PowerShell 5+ | Included in Windows 10/11 |
| ~3 GB free disk | For the model file |
| Internet connection | First run only — downloads binaries and model |

---

## Quick Start

```powershell
# 1. Clone the repo
git clone https://github.com/stanl33y/rtx4070-8G-tunning-llamacpp-qwen-4B.git
cd rtx4070-8G-tunning-llamacpp-qwen-4B

# 2. Download binaries + model (~2.6 GB, one-time)
.\setup.ps1

# 3. Start the server
.\start-server.ps1
```

Server ready at `http://localhost:8080`.

---

## setup.ps1

Downloads two things:

### 1. llama.cpp binaries
- Release: `b9284`
- Build: `win-cuda-12.4-x64`
- Source: [github.com/ggerganov/llama.cpp/releases](https://github.com/ggerganov/llama.cpp/releases)
- Extracted directly into the current directory

### 2. Model
- File: `Qwen3.5-4B-Q4_K_M.gguf`
- Size: ~2.6 GB
- Source: [unsloth/Qwen3.5-4B-GGUF](https://huggingface.co/unsloth/Qwen3.5-4B-GGUF)
- Saved to: `%USERPROFILE%\models\Qwen3.5-4B-Q4_K_M.gguf`
- Skipped if file already exists

---

## start-server.ps1 — Parameter Reference

| Flag | Value | Why |
|------|-------|-----|
| `-m` | `%USERPROFILE%\models\Qwen3.5-4B-Q4_K_M.gguf` | Model path |
| `-ngl 99` | 99 layers on GPU | Loads entire model into VRAM — eliminates CPU bottleneck |
| `-c 131072` | 131K token context | Full Qwen3.5 context window |
| `--parallel 1` | 1 concurrent request | Single user — avoids KV cache splitting overhead |
| `-fa on` | Flash Attention | Reduces VRAM for long contexts, speeds up attention |
| `--no-mmap` | Disable memory mapping | Prevents Windows page file thrashing on load |
| `--jinja` | Jinja2 template engine | Required for Qwen3.5 chat template |
| `--reasoning off` | Disable chain-of-thought | Faster responses when reasoning not needed; change to `on` for complex tasks |
| `--spec-type draft-mtp` | Multi-Token Prediction | Uses MTP heads baked into Qwen3.5 for speculative decoding |
| `--spec-draft-n-max 3` | Up to 3 draft tokens | Generates 3 tokens speculatively per step — good balance for 4B |
| `-ctk q8_0` | KV cache keys in q8_0 | 8-bit quantized keys — saves ~30% VRAM vs fp16, negligible quality loss |
| `-ctv q8_0` | KV cache values in q8_0 | Same as above for values |
| `--host 0.0.0.0` | Listen on all interfaces | Accessible from local network; change to `127.0.0.1` for localhost-only |
| `--port 8080` | Port 8080 | Standard local inference port |

### Why MTP (Multi-Token Prediction)?

Qwen3.5 models ship with MTP heads — extra output layers trained to predict 2–3 tokens ahead. llama.cpp uses these as a built-in speculative decoder: drafts N tokens, verifies in one forward pass. No separate draft model needed. On RTX 4070 8GB this yields ~20–40% throughput improvement depending on context length.

### Why q8_0 KV cache?

At 131K context, the KV cache in fp16 would use ~3–4 GB VRAM for a 4B model. q8_0 halves that, keeping enough headroom for the model weights (~2.6 GB) and activations on an 8 GB card.

---

## API Usage

The server exposes an OpenAI-compatible REST API.

### Chat completions

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5-4b",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Explain KV cache quantization."}
    ],
    "temperature": 0.7,
    "max_tokens": 512
  }'
```

### Streaming

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5-4b",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": true
  }'
```

### List models

```bash
curl http://localhost:8080/v1/models
```

---

## OpenCode Integration

Add to `opencode.json` (`~/.config/opencode/opencode.json`):

### Provider

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

Model appears in the selector as **LLaMA Local → Qwen3.5-4B (local)**.

### Optional: dedicated local agent

Agent restricted to file tools only — no internet, fast, zero API cost:

```json
{
  "agent": {
    "llama": {
      "description": "Local file agent — reads and edits files without internet",
      "model": "llama-local/qwen3.5-4b",
      "mode": "all",
      "prompt": "/no_think You are a local file editing agent. You ONLY use read, write, edit, and glob tools. Never use web search, fetch, or any external tools. When given a task, find the relevant files, read them, make the requested changes, done. Be direct and efficient.",
      "permission": {
        "webfetch": "deny",
        "websearch": "deny",
        "google_search": "deny",
        "ast_grep_search": "deny",
        "lsp_diagnostics": "deny",
        "background_output": "deny",
        "task": "deny",
        "skill": "deny"
      }
    }
  }
}
```

Invoke with `@llama` in OpenCode chat.

---

## Expected Performance (RTX 4070 8GB)

| Metric | Approximate value |
|--------|-------------------|
| Prompt processing (pp) | ~3000–5000 tokens/s |
| Token generation (tg) | ~60–90 tokens/s |
| With MTP speculative decoding | ~80–120 effective tokens/s |
| VRAM usage (model + 8K ctx) | ~3.5 GB |
| VRAM usage (model + 131K ctx) | ~6.5–7.5 GB |

---

## Troubleshooting

**CUDA not found / model runs on CPU**
```powershell
nvidia-smi  # must return GPU info
```
If missing, install CUDA 12.4 toolkit or update drivers.

**Out of memory (OOM) at 131K context**
Reduce context window:
```powershell
# In start-server.ps1, change:
-c 131072
# to:
-c 65536  # or lower
```

**Port already in use**
```powershell
# In start-server.ps1, change:
--port 8080
# to another port, e.g. 8081
# Update baseURL in opencode.json accordingly
```

**Slow first load**
Normal — `--no-mmap` forces full model read into VRAM on startup (~5–15s). Subsequent requests are fast.

**Reasoning mode**
To enable chain-of-thought (slower but better for complex tasks):
```powershell
# In start-server.ps1, change:
--reasoning off
# to:
--reasoning on
```
