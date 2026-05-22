# llama.cpp local server

Servidor local de inferência com [llama.cpp](https://github.com/ggerganov/llama.cpp).

## Requisitos

- Windows 10/11 x64
- GPU NVIDIA com CUDA 12.4
- PowerShell 5+
- Modelo: `%USERPROFILE%\models\Qwen3.5-4B-Q4_K_M.gguf`

## Setup

```powershell
.\setup.ps1
```

Baixa e extrai o release `b9284` (CUDA 12.4) do repositório oficial.

## Uso

```powershell
.\start-server.ps1
```

Servidor sobe em `http://localhost:8080`.

| Parâmetro | Valor |
|-----------|-------|
| Modelo | Qwen3.5-4B Q4_K_M |
| Context | 131K tokens |
| GPU layers | 99 (tudo na GPU) |
| KV cache | q8_0 |
| MTP | draft-mtp, 3 tokens |
| Flash attention | on |

## Integração com OpenCode

Adicione o provider `llama-local` no `opencode.json` (`~/.config/opencode/opencode.json`):

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

Opcional — agent dedicado que só usa ferramentas locais (sem internet):

```json
{
  "agent": {
    "llama": {
      "description": "Local file agent — busca e edita arquivos sem internet",
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

Modelo aparece no seletor como **LLaMA Local → Qwen3.5-4B (local)**. Requer servidor rodando (`.\start-server.ps1`).
