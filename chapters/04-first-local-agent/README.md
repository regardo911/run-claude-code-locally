# Chapter 4: your first local agent

Ollama, one model, and a harness that needs no proxy. Codex is the quickest; OpenCode works the same way with the [`opencode.json`](opencode.json) in this folder.

## Ollama and the model

```bash
ollama ls                    # an empty list is success: the server answered
ollama serve                 # only if ollama ls can't connect
ollama pull qwen2.5-coder    # several GB, needs the internet
ollama run qwen2.5-coder     # ask for something small, then /bye
```

Install Ollama from ollama.com/download (macOS, Windows) or with `curl -fsSL https://ollama.com/install.sh | sh` on Linux. If `ollama run` gives you a sensible answer, the model works, and anything that goes wrong after this is wiring.

## Path A: Codex

The book says "install Codex if you don't have it" without the command. It's this:

```bash
npm install -g @openai/codex
cd ~/your-repo && codex --oss --local-provider ollama -m qwen2.5-coder
```

Leave off `-m` and Codex asks Ollama for `gpt-oss:20b`, its default. You'd need that pulled too.

## Path B: OpenCode

```bash
npm install -g opencode-ai                       # opencode-ai, not opencode
./install.sh opencode ~/your-repo                # run from the repo root
cd ~/your-repo && opencode models                # look for ollama/qwen2.5-coder
opencode
```

`install.sh opencode` copies `opencode.json` into your project. If one is already there it's left alone, `--model` included, so edit the model name in it yourself. Pulled a different model? On a new copy, add `--model <slug>`. If `opencode models` shows your model, the JSON parsed and the provider registered.

## The offline edit

In a real repo of yours, under git with everything committed, give the agent this (with your own file and function):

> Add input validation to the function in `config.js` so it throws a clear error when a required field is missing.

Read the diff, accept it, open the file and check. Then turn Wi-Fi off and ask:

> now add a matching test for that validation

It works with the network off. That's the chapter's checkpoint: a correct change in your file, made by a model on your disk.

Five more green-zone tasks to build the habit, straight from the chapter:

- "Write a docstring for this function explaining what it does and what each parameter is for."
- "Convert this callback-style function to use async/await."
- "Add a `--verbose` flag to this CLI script that prints each step as it runs."
- "Explain what this regular expression matches, in plain English."
- "Write three unit tests for this function: the happy path, an empty input, and an invalid input."

Judge speed on the second task, not the first: the first one waits for Ollama to load the model.

## When it trips

- The agent describes the edit or prints JSON, and the file never changes: the model is sending its tool call as text. `ollama pull gpt-oss:20b`, then `codex --oss --local-provider ollama` without `-m`.
- `Model metadata for gpt-oss:20b not found`: pull it (`ollama pull gpt-oss:20b`) or use `-m qwen2.5-coder`.
- It can't connect at all: Ollama isn't running. `ollama ls`, then `ollama serve`.
