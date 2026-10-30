# Privacy runbook

A test you can run in front of a client (ch10:43-59, ch10:85-93).

## The airplane test

1. While online, pull your primary and fallback models. Check they're there with `ollama ls`. After the installs, this is the only step that needs the internet.
2. Turn Wi-Fi off and unplug any cable. Physically off.
3. In a real project, give your agent a multi-step task: read a file, change it, run the tests, fix what failed.
4. It finished, the edits are right, the tests ran. That completion is the proof: there was no connection for your code to leave on.

Want the strict version, "this process opened no connection at all"? Cut the network before you launch the harness, so even startup has nothing to talk to. Claude Code's `--bare` launch skips its background startup work too. It reads `ANTHROPIC_API_KEY`, not `ANTHROPIC_AUTH_TOKEN`, so send one request to check it still works.

## The three lines to keep next to your config

- Pull models while online; everything after is offline-capable.
- To prove privacy on demand, cut the network and run a real task. Completion is proof.
- To monitor while online, watch outbound connections; they should all be localhost.

For the third line, use whatever shows connections on your system (Little Snitch on a Mac, or your OS's own tools). Everything should go to `localhost` on 4000 and 11434. The book leaves the exact command to you on purpose, because a check that's subtly wrong for your OS gives you false confidence.
