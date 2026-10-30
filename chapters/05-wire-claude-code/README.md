# Chapter 5: Claude Code through your own proxy

Two files: [`config.yaml`](config.yaml), which tells LiteLLM which local model answers each name Claude Code asks for, and [`local-claude.sh`](local-claude.sh), which points Claude Code at the proxy. `./install.sh claude` (from the repo root) copies both into `~/litellm/`, the folder the book uses.

## Before you install LiteLLM

LiteLLM **1.82.7 and 1.82.8** shipped credential-stealing malware. Don't install either one, ever.

If LiteLLM is already on your machine anywhere, check it now: `pip show litellm`, or `~/litellm/.venv/bin/pip show litellm`. On either bad version, uninstall it, install a clean one, and rotate every API key, token and password that sat in your environment while it was there. The proxy sees every request you make. Read the version list before you install.

`install.sh` refuses both versions by name, and `start-local-stack.sh` stops if it finds one installed.

## Install it

```bash
./install.sh claude
./install.sh claude --litellm <the version you read>
```

The first run copies the two files, makes a Python venv at `~/litellm/.venv`, and prints the LiteLLM versions on PyPI, newest first. Same habit as the book (read the list, pin what you saw), but inside a venv, because the book's `pip install` fails on a stock Mac. [BOOK-FIXES](../../BOOK-FIXES.md) has the three reasons.

`--model <slug>` puts a model you've already pulled on the `claude-3-5-sonnet` line instead of `qwen2.5-coder`. The `claude-3-5-haiku` line stays on `qwen2.5-coder:3b`; change it by hand if you want something else there.

Pull whatever the config names: `ollama pull qwen2.5-coder && ollama pull qwen2.5-coder:3b` for the file as printed.

## Start the proxy

```bash
LITELLM_MASTER_KEY=sk-local-anything ~/litellm/.venv/bin/litellm --config ~/litellm/config.yaml --host 127.0.0.1
```

Three parts of that line aren't in the book:

- `~/litellm/.venv/bin/litellm` is where the venv put it.
- `LITELLM_MASTER_KEY`: LiteLLM 1.106.6 refuses to start without a master key. Use the same value as `ANTHROPIC_AUTH_TOKEN` in `local-claude.sh`, because that token is what Claude Code sends.
- `--host 127.0.0.1`: without it the proxy listens on `0.0.0.0:4000`, so other machines on your network can reach it.

It's working when the startup output shows `Uvicorn running on http://127.0.0.1:4000` and lists `claude-3-5-sonnet` and `claude-3-5-haiku` under "Set models". Leave that terminal open. Add `--detailed_debug` when you want to watch each request get translated.

## Point Claude Code at it

In a second terminal:

```bash
source ~/litellm/local-claude.sh
cd ~/your-repo && claude
```

![One request carries one model name through four places. Card 1, local-claude.sh: ANTHROPIC_MODEL=claude-3-5-sonnet. Card 2, claude: sends model "claude-3-5-sonnet" to localhost:4000. Card 3, config.yaml: model_name "claude-3-5-sonnet" maps to model "ollama_chat/qwen2.5-coder". Card 4, Ollama: localhost:11434 runs qwen2.5-coder. A band underneath reads: the name in local-claude.sh must match a model_name in config.yaml.](../../docs/images/four-names.png)

`local-claude.sh` adds two exports to the book's version: `ANTHROPIC_MODEL=claude-3-5-sonnet` and `ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-3-5-haiku`. Without them, Claude Code 2.1.312 asks the proxy for its own default model, `claude-opus-5-5`, and LiteLLM answers `400 anthropic_messages: Invalid model name passed in model=claude-opus-5-5`. Rename a `model_name` in `config.yaml` and you rename it here too.

Don't point Claude Code at port 11434. That's Ollama. Claude Code goes to the proxy on 4000, and the proxy goes to 11434.

## Your first task through the proxy

The book's prompt, with a file from your own repo in place of `utils.js`:

> Read `utils.js`, find the function that formats dates, and add handling for null input with a test.

With `--detailed_debug` on, a healthy step shows a request in for `claude-3-5-sonnet`, a translated call out to `ollama_chat/qwen2.5-coder` at `localhost:11434`, then tokens streaming back. If the request comes in and never goes out, look at `config.yaml`. If it goes out and nothing comes back, the model is busy or your machine is swapping, which is chapter 8.

If the answers feel a notch less sharp than cloud Claude, that's the model, not the wiring. Chapter 6 is how you pick a better one.

To check every layer at once, run [`start-local-stack.sh claude --check`](../12-daily-driver/stack-recipe.md) from chapter 12.
