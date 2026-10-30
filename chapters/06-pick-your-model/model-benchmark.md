# Model benchmark

One fixed task, two or three models, your own clock (ch06:57-73). You're timing a real agent loop on your own files.

## The task

Keep it identical for every model. The book's (ch06:61), with your own file:

> In this file, find the function that parses dates, add handling for null and malformed input, and write three tests for it.

## Pull and switch

Start with your baseline and add one or two that fit your RAM (chapter 8's table):

```bash
ollama pull qwen2.5-coder
ollama pull qwen3.6
ollama pull gemma4
```

To switch models between runs:

- Codex: `-m qwen3.6`
- Claude Code: change the `model:` line under `claude-3-5-sonnet` in `~/litellm/config.yaml`, then restart the proxy. The `claude-3-5-haiku` entry still answers the quick requests; change it too if you want one model on both
- OpenCode: pick the other model in OpenCode (it has to be listed in `opencode.json`)

## Your results

Time from Enter to done. Mark it **pass** (whole task done, tests pass, stayed on track), **partial** (got there with your help, or tests failed) or **fail**. A model you had to nudge through three tool-call stumbles is partial, whatever the clock says.

| Model slug | Seconds | pass / partial / fail |
|---|---|---|
| | | |
| | | |
| | | |

**Primary** (best mix of correct and fast on your machine):

**Fallback** (the one you switch to when the primary struggles):

Set the primary as the default in your config, and keep the fallback pulled so switching is one command (ch06:93-101).
