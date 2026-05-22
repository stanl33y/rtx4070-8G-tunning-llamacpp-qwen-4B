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
