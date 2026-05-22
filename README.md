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

## About Qwen3.5-4B

Qwen3.5 is Alibaba's third-generation language model family, released in 2025. The 4B variant is a dense transformer (not MoE) with 4 billion parameters.

### Architecture highlights

| Property | Value |
|----------|-------|
| Parameters | 4B (dense) |
| Context window | 131,072 tokens |
| Architecture | Transformer decoder, GQA |
| Training data cutoff | ~early 2025 |
| Reasoning | Built-in chain-of-thought (toggleable) |
| MTP heads | Yes — used for speculative decoding |
| Languages | Strong multilingual support (100+ languages) |

### Qwen3.5 vs Qwen3

| | Qwen3 | Qwen3.5 |
|-|-------|---------|
| MTP heads | No | Yes |
| Reasoning toggle | No | Yes (`/no_think` / `/think`) |
| Code quality | Good | Better |
| Context | 32K–128K | 131K |
| Multilingual | Good | Improved |

### Why 4B instead of a larger model?

On an 8 GB VRAM card, the 4B Q4_K_M fits entirely in VRAM with room for a 131K KV cache. Larger models (7B+) either require VRAM offloading to RAM (slow) or a reduced context window. For coding and file editing tasks, 4B at full context beats 7B at half context.

---

## Quantization Comparison

GGUF quantization trades model size and VRAM for quality. All options below are for the Qwen3.5-4B:

| Quantization | Size | VRAM (no ctx) | Quality loss | Recommended for |
|--------------|------|---------------|--------------|-----------------|
| Q2_K | ~1.5 GB | ~2 GB | High | Extremely limited VRAM |
| Q4_K_M | ~2.6 GB | ~3 GB | Low | **This config — best balance** |
| Q5_K_M | ~3.1 GB | ~3.5 GB | Very low | More VRAM available |
| Q8_0 | ~4.5 GB | ~5 GB | Minimal | Near-original quality |
| F16 | ~8 GB | ~8.5 GB | None | Reference / benchmarking |

**Q4_K_M** uses K-quant mixed precision: attention layers get higher precision (Q6/Q8), FFN layers get Q4. Better than plain Q4_0 at the same size.

To use a different quantization, update the model filename in `setup.ps1` and `start-server.ps1`.

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

## Generation Parameters

These are passed in the API request body and control output behavior:

| Parameter | Default | Effect |
|-----------|---------|--------|
| `temperature` | 0.8 | Randomness. `0` = deterministic, `1.0` = creative, `>1.2` = chaotic |
| `top_p` | 0.95 | Nucleus sampling — only consider tokens in top P% of probability mass |
| `top_k` | 40 | Only consider top K tokens per step. Lower = more focused |
| `min_p` | 0.05 | Minimum probability relative to top token — filters unlikely tokens |
| `repeat_penalty` | 1.1 | Penalizes recently used tokens. Higher = less repetition |
| `max_tokens` | 512 | Max tokens to generate in one response |
| `seed` | -1 | `-1` = random. Set a fixed value for reproducible outputs |
| `stream` | false | Stream tokens as they generate instead of waiting for full response |

### Recommended presets

**Coding / precise tasks**
```json
{ "temperature": 0.2, "top_p": 0.95, "top_k": 20, "repeat_penalty": 1.05 }
```

**General chat**
```json
{ "temperature": 0.7, "top_p": 0.95, "top_k": 40, "repeat_penalty": 1.1 }
```

**Creative writing**
```json
{ "temperature": 1.1, "top_p": 0.98, "top_k": 60, "repeat_penalty": 1.15 }
```

### Reasoning mode (Qwen3.5 specific)

Qwen3.5 supports toggling chain-of-thought per request via system prompt or the `--reasoning` server flag.

Enable per-request (overrides server flag):
```json
{
  "messages": [
    {"role": "system", "content": "/think"},
    {"role": "user", "content": "Solve this step by step..."}
  ]
}
```

Disable per-request:
```json
{
  "messages": [
    {"role": "system", "content": "/no_think"},
    {"role": "user", "content": "Quick answer: what is 2+2?"}
  ]
}
```

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

## Other Compatible Tools

Any tool that supports a custom OpenAI `baseURL` works out of the box.

### Continue.dev (VS Code / JetBrains)

Add to `~/.continue/config.json`:

```json
{
  "models": [
    {
      "title": "Qwen3.5-4B (local)",
      "provider": "openai",
      "model": "qwen3.5-4b",
      "apiBase": "http://localhost:8080/v1",
      "apiKey": "none"
    }
  ]
}
```

### Cursor

In Settings → Models → Add model:
- Provider: OpenAI-compatible
- Base URL: `http://localhost:8080/v1`
- Model name: `qwen3.5-4b`
- API key: `none`

### Open WebUI

```powershell
docker run -d -p 3000:8080 `
  -e OPENAI_API_BASE_URL=http://host.docker.internal:8080/v1 `
  -e OPENAI_API_KEY=none `
  ghcr.io/open-webui/open-webui:main
```

Access at `http://localhost:3000`.

### Python (openai SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="none",
)

response = client.chat.completions.create(
    model="qwen3.5-4b",
    messages=[{"role": "user", "content": "Hello!"}],
    temperature=0.7,
)
print(response.choices[0].message.content)
```

### LangChain

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    base_url="http://localhost:8080/v1",
    api_key="none",
    model="qwen3.5-4b",
)
```

---

## Other Models for RTX 4070 8GB

These models also run well with this setup. Update filenames in `setup.ps1` and `start-server.ps1` accordingly.

| Model | Size | VRAM | Strengths |
|-------|------|------|-----------|
| **Qwen3.5-4B Q4_K_M** *(this config)* | 2.6 GB | ~3.5 GB | Best speed+quality balance for coding |
| Qwen3.5-4B Q8_0 | 4.5 GB | ~5 GB | Near-original quality, same speed |
| Qwen3.5-7B Q4_K_M | 4.8 GB | ~5.5 GB | Better reasoning, fits with reduced context |
| Qwen3-8B Q4_K_M | 5.2 GB | ~6 GB | Strong general model |
| Mistral-7B-v0.3 Q4_K_M | 4.4 GB | ~5 GB | Fast, good for instruction following |
| Phi-4-mini Q4_K_M | 2.5 GB | ~3 GB | Small and fast, good for simple tasks |
| DeepSeek-Coder-V2-Lite Q4_K_M | 5.1 GB | ~6 GB | Specialized for code |

For 7B+ models, reduce context to avoid OOM:
```powershell
-c 65536  # instead of 131072
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

**Responses cut off early**
Increase `max_tokens` in the request, or raise `--ubatch-size` in `start-server.ps1` if throughput drops at long outputs.
