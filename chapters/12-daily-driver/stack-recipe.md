# Your daily-driver stack

Chapter 12 (ch12:15-72). Write the recipe once, start it with one command, run a real day on it.

## The recipe

| | Yours |
|---|---|
| Harness | |
| Runtime | |
| Model, with size and quant tag | |
| Fallback model (pulled, ready) | |
| `OLLAMA_CONTEXT_LENGTH` | |
| Proxy start (Claude Code only) | `LITELLM_MASTER_KEY=sk-local-anything ~/litellm/.venv/bin/litellm --config ~/litellm/config.yaml --host 127.0.0.1` |
| Sandbox | |

## Start it

From inside the repo you're about to work in:

```bash
/path/to/run-claude-code-locally/chapters/12-daily-driver/start-local-stack.sh claude
/path/to/run-claude-code-locally/chapters/12-daily-driver/start-local-stack.sh codex --model <your slug>
/path/to/run-claude-code-locally/chapters/12-daily-driver/start-local-stack.sh opencode
```

It starts Ollama if it isn't answering, checks every model your config asks for is pulled, and for Claude Code checks the LiteLLM version, matches the names in `local-claude.sh` against `config.yaml`, and starts the proxy on 127.0.0.1:4000 with its log in `~/litellm/proxy.log`. Then it opens the harness. Add `--check` to see the `ok` / `down` list without starting anything (if Ollama is down, that's the whole list). A missing model stops it with the `ollama pull` line to run.

## The sandbox

The daily Codex launch, as printed (ch12:35-38); its flags are all in `codex --help` on codex-cli 0.163.0, and it's the line `start-local-stack.sh codex` runs:

```bash
codex --oss --local-provider ollama -m qwen2.5-coder \
  --sandbox workspace-write --ask-for-approval on-request
```

`--sandbox` takes `read-only`, `workspace-write` or `danger-full-access`. `--ask-for-approval` takes `on-request` or `never` on that version. Leave `--dangerously-bypass-approvals-and-sandbox` alone.

To wrap any single command, from any harness, in the same sandbox:

```bash
codex sandbox -c sandbox_mode='"workspace-write"' -- <command>
```

That form writes inside the current folder and the temp folders, gets `Operation not permitted` writing anywhere else, and has no network. The printed `codex sandbox macos -- <command>` and `--full-auto` fail on codex-cli 0.163.0, and plain `codex sandbox -- <command>` blocks writes even inside the folder. `--log-denials` printed `None found.` after a real denial in our runs, so trust the command's own `Operation not permitted`. [BOOK-FIXES.md](../../BOOK-FIXES.md) has the full runs.

Try it before you trust it:

```bash
codex sandbox -c sandbox_mode='"workspace-write"' -- sh -c 'echo hi > inside.txt'        # works
codex sandbox -c sandbox_mode='"workspace-write"' -- sh -c 'echo hi > ../outside.txt'     # Operation not permitted (unless your project sits under /tmp)
```

The safety trio for the day: approvals on, a clean git branch with everything committed, and the sandbox for anything that runs commands.

## When a session goes wrong

Before you open the cloud tool, three moves (ch12:88): name the symptom (slow, freeze, mangle, parse error, wander), find the layer, test it alone. `ollama ls` for the server, `ollama run qwen2.5-coder` for the bare model, the proxy's `--detailed_debug` log for the format. The [chapter 11 runbook](../11-when-it-breaks/runbook.md) has the fixes.

## End of the day

What sent you to the cloud today, if anything? Genuine need (a huge-context job, a long cross-file chain) is fine. Friction (the proxy wasn't up, the model wasn't tuned) is a setup problem, and the chapter that fixes it is in the runbook.
