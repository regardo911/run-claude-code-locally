# Swap one variable

Same task, two setups, one thing changed (ch07:81-97).

Pick **one** axis to swap and hold the other still:

- two harnesses on one runtime: Codex vs OpenCode, both on Ollama
- two runtimes under one harness: Ollama vs llama.cpp's `llama-server`, both under Codex

Use the same model on both sides if you can, so you're testing the harness or the runtime and not the brain.

The task, identical on both runs (ch07:87):

> Find the function that handles user input, add validation, and run the tests

| | Setup | Wall-clock | Loop behaviour (clean, needed rescue, laggy between steps) |
|---|---|---|---|
| A | | | |
| B | | | |

What differed, beyond speed (approval prompts, how the tool calls went, how the same model behaved in each loop):

&nbsp;

## Your pairing

Harness + runtime, and one line on why the alternatives lost for you (ch07:107). The book's example: "Codex on Ollama, because I wanted no proxy and my laptop doesn't have a GPU to justify vLLM."

My pairing:

Why:
