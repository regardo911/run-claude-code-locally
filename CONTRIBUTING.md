# Contributing

Issues and pull requests are welcome. The two that help most:

- a file here that differs from your printed copy of the book (say which chapter and line)
- a fix in [BOOK-FIXES.md](BOOK-FIXES.md) that stopped working on a newer Claude Code, LiteLLM, Codex or Ollama, with the version and the output you got

Before a pull request, run these. shellcheck prints nothing when it's clean. Paste the last line of the tests (`N passed, 0 failed`):

```bash
shellcheck -s bash $(git ls-files '*.sh')
bash tests/run.sh
```

Keep the book's files as the book prints them. A change to one of them goes in BOOK-FIXES.md, with the command that shows the printed version failing and its full output.

`sk-local-anything` is the book's placeholder for a proxy on your own machine. Never commit a real key or token.
