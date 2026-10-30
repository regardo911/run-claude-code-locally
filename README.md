# Run Claude Code Locally: the files from the book

**Claude Code, Codex or OpenCode answering from an open model on your own machine, set up with the book's own config files.**

Companion files to the book *Run Claude Code Locally* · [youcanbuildthings.com](https://youcanbuildthings.com)

The book's config files and scripts, filed by chapter. `./install.sh claude` drops the Claude Code pair into `~/litellm/`. Two names to know. **Ollama** runs the model on your machine, port 11434 ([chapter 4](chapters/04-first-local-agent/README.md)). **LiteLLM** is the small proxy on port 4000 that turns Claude Code's requests into ones Ollama understands ([chapter 5](chapters/05-wire-claude-code/README.md)). Codex and OpenCode talk to Ollama directly, so they skip the proxy. Find your line below.

[![CI](https://github.com/regardo911/run-claude-code-locally/actions/workflows/ci.yml/badge.svg)](https://github.com/regardo911/run-claude-code-locally/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Start here

### I use Claude Code

```bash
git clone https://github.com/regardo911/run-claude-code-locally.git && cd run-claude-code-locally
./install.sh claude
```

That's the fastest way in. It copies the book's `config.yaml` and `local-claude.sh` into `~/litellm/`, makes the Python venv LiteLLM lives in, and prints the LiteLLM versions on PyPI, newest first. Pick one that isn't 1.82.7 or 1.82.8 and install it with `./install.sh claude --litellm <that version>`. Then pull the two models the config names and start the whole stack from inside your own repo:

```bash
ollama pull qwen2.5-coder && ollama pull qwen2.5-coder:3b
cd ~/your-repo && /path/to/run-claude-code-locally/chapters/12-daily-driver/start-local-stack.sh claude
```

The script checks Ollama, the models, LiteLLM and the proxy in the book's order. It starts Ollama and the proxy if they're down, stops with the fix if anything else is, then opens `claude` in your repo. The [chapter 5 README](chapters/05-wire-claude-code/README.md) walks the same steps by hand.

### I use Codex or OpenCode

```bash
ollama pull qwen2.5-coder
cd ~/your-repo && codex --oss --local-provider ollama -m qwen2.5-coder
```

For OpenCode, run `./install.sh opencode ~/your-repo` from this folder, then `opencode` in your repo. The [chapter 4 README](chapters/04-first-local-agent/README.md) has both paths and the prompts for your first offline edit.

### I finished the book and just want the files

Go to the [copy table](#copy-table).

![The first command and what each chapter folder holds. Top: the real output of ./install.sh claude run in an empty home folder. It makes ~/litellm/, copies config.yaml and local-claude.sh into it, makes the Python venv ~/litellm/.venv, prints the newest LiteLLM versions from PyPI and the line to install the one you pick, never 1.82.7 or 1.82.8. Below it, under What you get, one row per chapter: chapter 4, opencode.json and the Codex command for Ollama; chapter 5, config.yaml and local-claude.sh for Claude Code; chapter 6, a test sheet with one task, your models and your times; chapter 8, my-local-stack.txt for your RAM; chapter 9, break-even.sh, the month local pays for itself; chapter 11, a runbook with 5 symptoms and the fix for each; chapter 12, start-local-stack.sh, one command to start your day. Footer: every file is filed by chapter, and BOOK-FIXES.md lists what changed from the print.](docs/images/hero.png)

## Copy table

| Ch | In this repo | Goes to, on your machine | Done by |
|---|---|---|---|
| 4 | [`opencode.json`](chapters/04-first-local-agent/opencode.json) | `opencode.json` in your project | `./install.sh opencode <dir>` |
| 5 | [`config.yaml`](chapters/05-wire-claude-code/config.yaml) | `~/litellm/config.yaml` | `./install.sh claude` |
| 5 | [`local-claude.sh`](chapters/05-wire-claude-code/local-claude.sh) | `~/litellm/local-claude.sh` | `./install.sh claude` |
| 8 | [`my-local-stack.txt`](chapters/08-your-hardware/my-local-stack.txt) | beside `~/litellm/config.yaml`, with your own values | you |
| 12 | [`start-local-stack.sh`](chapters/12-daily-driver/start-local-stack.sh) | anywhere on your `PATH`, or run it from here | you |

The sheets for chapters 3, 6, 7, 10, 11 and 12 are Markdown files: copy one next to your project and fill it in.

## Chapter map

| Chapter | What you get | The command | What success looks like |
|---|---|---|---|
| [3](chapters/03-honest-map/local-or-cloud.md) | the local-or-cloud matrix, plus 5 rows for your own week | none: fill it in | you call green or amber before you start a task |
| [4](chapters/04-first-local-agent/README.md) | the Codex command, `opencode.json`, the prompts | `codex --oss --local-provider ollama -m qwen2.5-coder` | Wi-Fi off, the agent edits a file in your repo and the change is right |
| [5](chapters/05-wire-claude-code/README.md) | `config.yaml`, `local-claude.sh`, the LiteLLM install | `./install.sh claude` | the proxy starts on 4000 and `claude` answers through it |
| [6](chapters/06-pick-your-model/model-benchmark.md) | a benchmark sheet | one fixed task on 2 or 3 models | a table of slug, seconds and pass / partial / fail from your machine |
| [7](chapters/07-harness-and-runtime/swap-one-variable.md) | an A/B log | the same task on two setups | one difference you can name |
| [8](chapters/08-your-hardware/README.md) | `my-local-stack.txt`, the tier rows | `ollama pull qwen2.5-coder:7b-instruct-q4_K_M` | a real task finishes without memory going red |
| [9](chapters/09-cost-kill-math/README.md) | `break-even.sh` | `./break-even.sh --cloud <bill> --electricity <est> --hardware <price or 0>` | your break-even month and first-year net |
| [10](chapters/10-private-offline/privacy-runbook.md) | the airplane test and the 3-line runbook | network off, run a real task | the task finishes with the network physically off |
| [11](chapters/11-when-it-breaks/runbook.md) | 5 symptoms, the error strings, 3 drills | the drills, on a throwaway repo | three breaks fixed without a reinstall |
| [12](chapters/12-daily-driver/stack-recipe.md) | `start-local-stack.sh`, the stack recipe, the sandbox | `start-local-stack.sh claude --check` | a full day of real work on the local stack |

Chapters 1 and 2 have no folder. Chapter 1's Codex command is chapter 4's, and chapter 2's mapping is the first half of chapter 5's `config.yaml`.

## What it needs

- Ollama and at least one pulled model; each is several GB
- one harness: Claude Code (the npm package wants Node 22 or newer), Codex or OpenCode
- for Claude Code, Python 3.10 or newer, for the LiteLLM venv
- bash, git and curl (`bash tests/run.sh` also uses python3)

The scripts and `bash tests/run.sh` run on a machine with no model, no key and no network; only the venv step of `./install.sh claude` goes online, to PyPI.

A few printed lines fail on today's Claude Code, LiteLLM, Codex and stock macOS Python, and two claims don't hold. This repo ships the working versions, and [BOOK-FIXES.md](BOOK-FIXES.md) shows the runs.

## Contributing

Found a file that differs from your copy of the book, or a fix that stopped working on a newer tool? Open an issue. [CONTRIBUTING.md](CONTRIBUTING.md) has the two checks to run first.

## License

MIT, see [LICENSE](LICENSE). Educational software, provided as-is, with no warranty.
