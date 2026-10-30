# Chapter 8: fit the model to your RAM

Start from your row, then tune to what your memory monitor shows.

| Your RAM | Context Ollama gives you | Model | Quantization |
|---|---|---|---|
| under 24GB (no-GPU laptop, ~16GB) | about 4k | `qwen2.5-coder:3b` or `:7b` | `q4_K_M` |
| 24 to 48GB (~32GB workstation) | about 32k | `qwen2.5-coder:7b` or `:14b` | `q4_K_M` |
| 48GB and up (GPU box, big unified memory) | up to 256k | `:14b` to `:32b` | `q4_K_M` or higher |

Old guides say Ollama defaults to 2048 tokens. It doesn't; the tier above wins. Quantization lives in the tag (`ollama pull qwen2.5-coder:7b-instruct-q4_K_M`); there's no `--quantize` flag. Set context yourself with `OLLAMA_CONTEXT_LENGTH=64000 ollama serve`.

When a task crawls, freezes or turns memory red, back off in this order and re-run the same task after each step:

1. drop the model one size (`:14b` to `:7b`, `:7b` to `:3b`)
2. lower `OLLAMA_CONTEXT_LENGTH`

Once a real task runs smoothly, write the slug and context value into [`my-local-stack.txt`](my-local-stack.txt) in place of the book's example and keep it next to `~/litellm/config.yaml`. The memory reading and the timing come off your own machine, so they live in your notes, not in this file.
