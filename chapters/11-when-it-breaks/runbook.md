# When it breaks

Name the symptom (ch11:87-105, appendices:134-146), find the layer (model, runtime, proxy, harness), change one thing, re-run.

## Five symptoms

| Symptom | What it usually is | Fix |
|---|---|---|
| Slow, or a tool call hangs | Memory red: thrashing. Memory fine: the model fumbling tool calls | Red: smaller model, then smaller context. Fine: raise `OLLAMA_CONTEXT_LENGTH` (if it still fits), or a faster runtime (ch8, ch7) |
| Machine freezes or times out | Model plus context overran your RAM | Drop a full model size and lower the context; close other memory hogs (ch8) |
| Mangles your code | No guardrails | Approvals on, everything committed first, commands in a sandbox. No `--dangerously-skip-permissions` while you're learning (ch11, ch12) |
| Parsing error mid-stream | Format mismatch at a layer boundary | Check the `ollama_chat/` prefix in `config.yaml`, read the proxy's `--detailed_debug` log; for gpt-oss metadata errors, pull the model (ch2, ch5) |
| Tool loop stalls or wanders | Long tool-call chains are local models' weak spot | Split the task into shorter ones, raise context, try a steadier model or harness (ch6, ch7) |

Open your memory monitor and re-run the slow task before you change anything: red memory and a busy disk is one fix, comfortable memory is the other.

## Error strings, decoded

| You see | It means | Do this |
|---|---|---|
| `Model metadata for gpt-oss:20b not found` | the model isn't fully pulled, or a rough edge between it and Ollama | `ollama pull gpt-oss:20b`, or `-m` a model you've confirmed |
| connection refused, "cannot reach" | the thing on the other end isn't running | `ollama ls`; on Claude Code, is the proxy terminal still open? Start the server; leave the config alone |
| `API Error: 400 anthropic_messages: Invalid model name passed in model=claude-opus-5-5` | Claude Code asked for a name `config.yaml` doesn't map | set `ANTHROPIC_MODEL` to a `model_name` from `config.yaml` (the repo's `local-claude.sh` does) |
| `API Error: 400 No connected db.` | the token Claude Code sent doesn't match the proxy's `LITELLM_MASTER_KEY` | make `ANTHROPIC_AUTH_TOKEN` and `LITELLM_MASTER_KEY` the same value |
| `Not logged in · Please run /login` | no token set in this terminal | `source ~/litellm/local-claude.sh` here |
| `LiteLLM proxy refused to start: no master key is set` | LiteLLM 1.106.6 needs a master key | start it with `LITELLM_MASTER_KEY=sk-local-anything` (chapter 5 README) |
| `There's an issue with the selected model (claude-3-5-sonnet)` | Claude Code is pointed at Ollama on 11434 | `ANTHROPIC_BASE_URL=http://localhost:4000` |
| malformed response, parsing error mid-stream | format mismatch at the proxy | `ollama_chat/` prefix, then the debug log |
| no error, a spinner forever | usually thrashing | check memory before you assume the worst |

The book says a 401 means you set `ANTHROPIC_API_KEY` instead of `ANTHROPIC_AUTH_TOKEN`. With LiteLLM 1.106.6 both variables got through; the wrong-token message above is what a mismatch actually looked like. [BOOK-FIXES.md](../../BOOK-FIXES.md) has the runs.

## Break it on purpose

Do these on a throwaway repo, calm, before a real deadline does them to you (ch11:73-85).

1. **Slow.** Pull a model a size or two above your RAM tier, run a task with your memory monitor open, watch it crawl. Drop to a model that fits and run the same task again.
2. **Dangerous, safely.** With everything committed, ask for "refactor everything to be cleaner". Watch how much it wants to change, decline, then `git status` to see nothing landed. If something did: `git status`, `git diff`, then `git restore .` to throw the working-copy changes away.
3. **Wiring** (Claude Code). Change `ollama_chat/` to `ollama/` in `~/litellm/config.yaml`, or point it at a model you haven't pulled. Restart the proxy with `--detailed_debug`, find where it fails in the log, put it back.

Each one fixed without a reinstall is the chapter's checkpoint.
