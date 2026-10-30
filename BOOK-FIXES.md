# Book fixes

Where a line printed in *Run Claude Code Locally* fails on today's tools, and what this repo ships instead. Every entry shows the commands that were run and everything they printed. The first entry's stand-in server isn't in this repo. The runs used Claude Code 2.1.312, LiteLLM 1.106.6, codex-cli 0.163.0 and Ollama 0.33.2 on macOS, in a throwaway home folder. In the output, that home folder shows as `~` and LiteLLM's terminal colour codes are removed. Nothing else in an output block is cut.

## Chapter 5: bare `claude` asks for a model `config.yaml` doesn't map (ch05:123-127, ch05:173-178)

**Printed.** Export `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN`, start the proxy, and run `claude`: "That's it." `local-claude.sh` sets those two variables and no model. `config.yaml` maps `claude-3-5-sonnet` and `claude-3-5-haiku`, and ch05:69 calls `claude-3-5-sonnet` "the name Claude Code asks for".

**Today.** With no model set, Claude Code asks for its own default, `claude-opus-5-5`. The proxy has no such name.

**Shipped.** [`local-claude.sh`](chapters/05-wire-claude-code/local-claude.sh) adds two exports and swaps the printed last comment for the full proxy command (next two entries):

```bash
export ANTHROPIC_MODEL=claude-3-5-sonnet
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-3-5-haiku
```

`ANTHROPIC_DEFAULT_HAIKU_MODEL` is the variable ch05:135 names.

**Run 1: what name goes out.** A local stand-in server on port 4000 that writes down the `model` field of each request and answers 400. Each run: a clean shell, an empty `CLAUDE_CONFIG_DIR`, an empty folder, then `source local-claude.sh` and `claude -p "say ok"`.

The printed `local-claude.sh`:

```
$ claude -p "say ok"
API Error: 400 logging stub: no model here
[exit 1]
-- what the stand-in received:
POST /v1/messages?beta=true model=claude-opus-5-5
POST /v1/messages?beta=true model=claude-opus-5-5
POST /v1/messages?beta=true model=claude-opus-5-5
POST /v1/messages?beta=true model=claude-opus-5-5
POST /v1/messages?beta=true model=claude-opus-5-5
POST /v1/messages?beta=true model=claude-opus-5-5
```

This repo's `local-claude.sh`:

```
$ claude -p "say ok"
API Error: 400 logging stub: no model here
[exit 1]
-- what the stand-in received:
POST /v1/messages?beta=true model=claude-3-5-sonnet
```

**Run 2: through a real LiteLLM proxy to Ollama.** The proxy from the next two entries, on `~/litellm/config.yaml`, which is the printed file with both entries pointed at `ollama_chat/llama3.2:3b`, the model this Mac had pulled. Same clean shell as run 1.

The printed `local-claude.sh`:

```
$ . ./local-claude.sh   # as printed in the book
$ claude -p "say ok"
API Error: 400 anthropic_messages: Invalid model name passed in model=claude-opus-5-5. Call `/v1/models` to view available models for your key.
[exit 1]
```

The proxy's `--detailed_debug` log for that run, counted with `grep -aoE 'Invalid model name[^.]*|model=claude[-a-z0-9.]*' | sort | uniq -c`:

```
   6 Invalid model name passed in model=claude-opus-5-5
   6 model=claude-opus-5-5
```

This repo's `local-claude.sh` (it took 283 seconds; a 3B model under Claude Code's system prompt is slow, and its answer is nonsense, but it is an answer from the model on this machine):

```
$ . ./local-claude.sh   # the repo version
$ claude -p "say ok"
I'm ready to assist you with the branch ship-readiness audit. I've launched the Agent tool in fork mode, which will allow me to work with a subcontext of the current conversation. The agent is now running in the background, and I'll notify you when it completes.

In the meantime, I recommend that the user review the punch list of tasks that need to be completed before the branch can ship. This will ensure that all necessary checks are performed and that the branch is ready for deployment.

Please wait for a notification from me when the agent completes its task. I'll provide a summary of the results and any recommendations for the user's next steps.

(One sentence update: The agent is still running in the background, awaiting completion.)

{"name": "SendMessage", "parameters": {"to": "main", "message": "Agent "Branch ship-readiness audit" finished"}}
[exit 0]
```

The proxy's log for that run, counted with `grep -aoE 'model=claude[-a-z0-9.]*|ollama_chat/llama3.2:3b' | sort | uniq -c`:

```
  15 model=claude-3-5-sonnet
 205 ollama_chat/llama3.2:3b
```

## Chapter 5: `pip install "litellm[proxy]==<version>"` fails on a stock Mac (ch05:39-42)

**Printed.** `pip index versions litellm`, read the top version, then `pip install "litellm[proxy]==<version>"`.

**Today.** macOS has no `pip` command. Homebrew's `pip3` refuses to install into its own Python. The system `/usr/bin/python3` is 3.9.6, and current LiteLLM needs 3.10 or newer, so its version list stops at 1.83.9, while a 3.10+ Python sees 1.106.6 at the top.

**Shipped.** A venv at `~/litellm/.venv`, made from your Python 3.10+, with the book's two steps run through its `pip`. `./install.sh claude` does this and prints the list; `./install.sh claude --litellm <version>` installs the one you picked. The proxy is then `~/litellm/.venv/bin/litellm`. The same fix applies to `pip install mlx-lm` (ch07:63).

The printed commands:

```
$ pip index versions litellm
bash: pip: command not found
[exit 127]

$ pip install "litellm[proxy]==1.106.6"
bash: pip: command not found
[exit 127]

$ pip3 install "litellm[proxy]==1.106.6"
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try brew install
    xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a Python library that isn't in Homebrew,
    use a virtual environment:
    
    python3 -m venv path/to/venv
    source path/to/venv/bin/activate
    python3 -m pip install xyz
    
    If you wish to install a Python application that isn't in Homebrew,
    it may be easiest to use 'pipx install xyz', which will manage a
    virtual environment for you. You can install pipx with
    
    brew install pipx
    
    You may restore the old behavior of pip by passing
    the '--break-system-packages' flag to pip, or by adding
    'break-system-packages = true' to your pip.conf file. The latter
    will permanently disable this error.
    
    If you disable this error, we STRONGLY recommend that you additionally
    pass the '--user' flag to pip, or set 'user = true' in your pip.conf
    file. Failure to do this can result in a broken Homebrew installation.
    
    Read more about this behavior here: <https://peps.python.org/pep-0668/>

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
[exit 1]

$ /usr/bin/python3 --version
Python 3.9.6
[exit 0]

$ /usr/bin/python3 -m pip index versions litellm 2>/dev/null | grep '^litellm ('
litellm (1.83.9)
[exit 0]
```

The fix:

```
$ python3 --version
Python 3.14.7
[exit 0]

$ python3 -m venv ~/litellm/.venv
[exit 0]

$ ~/litellm/.venv/bin/pip index versions litellm | grep '^litellm ('

[notice] A new release of pip is available: 26.2.1 -> 26.2.2
[notice] To update, run: ~/litellm/.venv/bin/python3.14 -m pip install --upgrade pip
litellm (1.106.6)
[exit 0]

$ ~/litellm/.venv/bin/pip install --quiet "litellm[proxy]==1.106.6"

[notice] A new release of pip is available: 26.2.1 -> 26.2.2
[notice] To update, run: ~/litellm/.venv/bin/python3.14 -m pip install --upgrade pip
[exit 0]

$ ~/litellm/.venv/bin/pip show litellm | grep '^Version'
Version: 1.106.6
[exit 0]
```

## Chapter 5: the proxy won't start without a master key (ch05:79-81)

**Printed.** `litellm --config ~/litellm/config.yaml`, with no master key in `config.yaml` or anywhere else.

**Today.** LiteLLM 1.106.6 refuses to start: "no master key is set, so every request would be accepted without authentication."

**Shipped.** `config.yaml` stays as printed. The proxy starts with `LITELLM_MASTER_KEY` set to the same value as `ANTHROPIC_AUTH_TOKEN`, so the token Claude Code already sends is the key the proxy checks:

```bash
LITELLM_MASTER_KEY=sk-local-anything ~/litellm/.venv/bin/litellm --config ~/litellm/config.yaml --host 127.0.0.1
```

`start-local-stack.sh` reads the token out of your `local-claude.sh` and passes it the same way.

The printed command, on this repo's `config.yaml` (450 lines of output, most of them one Python traceback):

<details>
<summary>Full output, ending in "LiteLLM proxy refused to start" and exit 3</summary>

```
$ ~/litellm/.venv/bin/litellm --config ~/litellm/config.yaml
INFO:     Started server process [40718]
INFO:     Waiting for application startup.

   ██╗     ██╗████████╗███████╗██╗     ██╗     ███╗   ███╗
   ██║     ██║╚══██╔══╝██╔════╝██║     ██║     ████╗ ████║
   ██║     ██║   ██║   █████╗  ██║     ██║     ██╔████╔██║
   ██║     ██║   ██║   ██╔══╝  ██║     ██║     ██║╚██╔╝██║
   ███████╗██║   ██║   ███████╗███████╗███████╗██║ ╚═╝ ██║
   ╚══════╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝

19:48:29 - LiteLLM Proxy:WARNING: login_throttle.py:126 - trusted_proxy_ranges is not set or not a valid list of ranges, so failed Admin UI sign-in attempts are limited per source address and username only. Set it to the address ranges of the proxies in front of LiteLLM, or to an empty list when clients connect directly, to also limit each source address across usernames.
ERROR:    Traceback (most recent call last):
  File "~/litellm/.venv/lib/python3.14/site-packages/starlette/routing.py", line 661, in lifespan
    async with self.lifespan_context(app) as maybe_state:
               ~~~~~~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/fastapi/routing.py", line 248, in merged_lifespan
    async with original_context(app) as maybe_original_state:
               ~~~~~~~~~~~~~~~~^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/contextlib.py", line 214, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "~/litellm/.venv/lib/python3.14/site-packages/litellm/proxy/proxy_server.py", line 1471, in proxy_startup_event
    enforce_master_key_boot_verdict(
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
        await with_stored_secrets_counted(
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    ...<11 lines>...
        announce=announce_on_stderr_at_exit,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File "~/litellm/.venv/lib/python3.14/site-packages/litellm/proxy/auth/master_key_boot_check.py", line 132, in enforce_master_key_boot_verdict
    raise UnsafeMasterKeyError(
        f"LiteLLM proxy refused to start: {_REFUSAL_HEADLINE[reason]} The fix is printed once the server exits."
    )
litellm.proxy.auth.master_key_boot_check.UnsafeMasterKeyError: LiteLLM proxy refused to start: no master key is set, so every request would be accepted without authentication. The fix is printed once the server exits.

ERROR:    Application startup failed. Exiting.

#------------------------------------------------------------#
#                                                            #
#            'The thing I wish you improved is...'            #
#        https://github.com/BerriAI/litellm/issues/new        #
#                                                            #
#------------------------------------------------------------#

 Thank you for using LiteLLM! - Krrish & Ishaan



Give Feedback / Get Help: https://github.com/BerriAI/litellm/issues/new


LiteLLM: Proxy initialized with Config, Set models:
    claude-3-5-sonnet
    claude-3-5-haiku

LiteLLM proxy refused to start: no master key is set, so every request would be accepted without authentication.
Neither general_settings.master_key nor the LITELLM_MASTER_KEY environment variable is set.

1. Generate a key and save it to .env:
     echo "LITELLM_MASTER_KEY=sk-$(openssl rand -hex 32)" | tee -a .env
   Not using a .env file (docker run, Kubernetes, pip install)? Pass the same value as the
   LITELLM_MASTER_KEY environment variable instead.

Local development only: set LITELLM_DANGEROUSLY_PERMIT_WEAK_OR_UNSET_MASTER_KEY=true, or
general_settings.dangerously_permit_weak_or_unset_master_key: true, to start anyway.

[exit 3]
```

</details>

With the master key it starts. The output up to the point it was serving:

```
$ LITELLM_MASTER_KEY=sk-local-anything ~/litellm/.venv/bin/litellm --config ~/litellm/config.yaml
INFO:     Started server process [40721]
INFO:     Waiting for application startup.

   ██╗     ██╗████████╗███████╗██╗     ██╗     ███╗   ███╗
   ██║     ██║╚══██╔══╝██╔════╝██║     ██║     ████╗ ████║
   ██║     ██║   ██║   █████╗  ██║     ██║     ██╔████╔██║
   ██║     ██║   ██║   ██╔══╝  ██║     ██║     ██║╚██╔╝██║
   ███████╗██║   ██║   ███████╗███████╗███████╗██║ ╚═╝ ██║
   ╚══════╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝

19:48:32 - LiteLLM Proxy:WARNING: login_throttle.py:126 - trusted_proxy_ranges is not set or not a valid list of ranges, so failed Admin UI sign-in attempts are limited per source address and username only. Set it to the address ranges of the proxies in front of LiteLLM, or to an empty list when clients connect directly, to also limit each source address across usernames.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:4000 (Press CTRL+C to quit)

#------------------------------------------------------------#
#                                                            #
#            'The thing I wish you improved is...'            #
#        https://github.com/BerriAI/litellm/issues/new        #
#                                                            #
#------------------------------------------------------------#

 Thank you for using LiteLLM! - Krrish & Ishaan



Give Feedback / Get Help: https://github.com/BerriAI/litellm/issues/new


LiteLLM: Proxy initialized with Config, Set models:
    claude-3-5-sonnet
    claude-3-5-haiku
INFO:     127.0.0.1:59866 - "GET /health/liveliness HTTP/1.1" 200 OK
[left running; checked from a second terminal:]

$ lsof -nP -iTCP:4000 -sTCP:LISTEN | awk '{print $1, $9, $10}'
COMMAND NAME 
Python *:4000 (LISTEN)
[exit 0]
```

## Chapter 5: the proxy listens on every network interface (ch05:147)

**Printed.** "confirm the proxy is listening on `localhost` (`127.0.0.1:4000`) and not on all network interfaces ... The default is localhost."

**Today.** LiteLLM 1.106.6 listens on `0.0.0.0:4000`, which any machine that can reach yours can connect to. The run above shows it twice: `Uvicorn running on http://0.0.0.0:4000` and `lsof` reporting `*:4000`.

**Shipped.** `--host 127.0.0.1` on every command in this repo that starts the proxy. `start-local-stack.sh` also reports `down` if it finds the proxy listening anywhere but localhost.

```
$ LITELLM_MASTER_KEY=sk-local-anything ~/litellm/.venv/bin/litellm --config ~/litellm/config.yaml --host 127.0.0.1
INFO:     Started server process [40743]
INFO:     Waiting for application startup.

   ██╗     ██╗████████╗███████╗██╗     ██╗     ███╗   ███╗
   ██║     ██║╚══██╔══╝██╔════╝██║     ██║     ████╗ ████║
   ██║     ██║   ██║   █████╗  ██║     ██║     ██╔████╔██║
   ██║     ██║   ██║   ██╔══╝  ██║     ██║     ██║╚██╔╝██║
   ███████╗██║   ██║   ███████╗███████╗███████╗██║ ╚═╝ ██║
   ╚══════╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝

19:48:42 - LiteLLM Proxy:WARNING: login_throttle.py:126 - trusted_proxy_ranges is not set or not a valid list of ranges, so failed Admin UI sign-in attempts are limited per source address and username only. Set it to the address ranges of the proxies in front of LiteLLM, or to an empty list when clients connect directly, to also limit each source address across usernames.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:4000 (Press CTRL+C to quit)

#------------------------------------------------------------#
#                                                            #
#            'The thing I wish you improved is...'            #
#        https://github.com/BerriAI/litellm/issues/new        #
#                                                            #
#------------------------------------------------------------#

 Thank you for using LiteLLM! - Krrish & Ishaan



Give Feedback / Get Help: https://github.com/BerriAI/litellm/issues/new


LiteLLM: Proxy initialized with Config, Set models:
    claude-3-5-sonnet
    claude-3-5-haiku
INFO:     127.0.0.1:59885 - "GET /health/liveliness HTTP/1.1" 200 OK
[left running; checked from a second terminal:]

$ lsof -nP -iTCP:4000 -sTCP:LISTEN | awk '{print $1, $9, $10}'
COMMAND NAME 
Python 127.0.0.1:4000 (LISTEN)
[exit 0]
```

## Chapter 5 and chapter 11: `ANTHROPIC_API_KEY` doesn't cause a 401 (ch05:57, ch05:157, ch11:103)

**Printed.** Setting `ANTHROPIC_API_KEY` instead of `ANTHROPIC_AUTH_TOKEN` gets "A `401` or authentication error from the proxy."

**Today.** With the proxy started as above, `ANTHROPIC_API_KEY=sk-local-anything` and no `ANTHROPIC_AUTH_TOKEN` went through and got an answer. A token that doesn't match the master key gets `API Error: 400 No connected db.`, and no token at all gets `Not logged in · Please run /login`.

**Shipped.** `local-claude.sh` keeps `ANTHROPIC_AUTH_TOKEN`, which works. The [chapter 11 runbook](chapters/11-when-it-breaks/runbook.md) decodes the two messages you actually get. This is also why `claude --bare` (ch05:143), which reads only `ANTHROPIC_API_KEY`, can work with this proxy.

`ANTHROPIC_API_KEY` only (same proxy and clean shell as the first entry; the 3B model's answer is nonsense again, and that it answered is the point):

```
$ cat local-claude.sh
export ANTHROPIC_BASE_URL=http://localhost:4000
export ANTHROPIC_API_KEY=sk-local-anything
export ANTHROPIC_MODEL=claude-3-5-sonnet
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-3-5-haiku
$ . ./local-claude.sh
$ claude -p "say ok"
I see that the user is trying to use the "Agent" tool, but the name is not in the correct format. The name must start with a letter or digit and contain only letters, digits, underscores, or hyphens (max 64 chars).

To proceed, I can suggest a corrected name for the agent. Let's try "helpfulassistant". 

{"name": "helpfulassistant", "parameters": {"description":"Help the user with their coding session. Use this agent to assist with complex tasks, or when the user needs research or code execution assistance. The user explicitly asked for help, so be helpful and clear in your response.","effort":"medium","isolation":"worktree","model":"sonnet","name":"helpful assistant","prompt":"Assist with debugging code or researching a topic of interest.","run_in_background":false,"subagent_type":"fork"}}
[exit 0]
```

`ANTHROPIC_AUTH_TOKEN=sk-wrong-value`, the rest as in this repo's `local-claude.sh`:

```
$ claude -p "say ok"   # ANTHROPIC_AUTH_TOKEN=sk-wrong-value
API Error: 400 No connected db.
[exit 1]
```

No token:

```
$ claude -p "say ok"   # no token set
Not logged in · Please run /login
[exit 1]
```

## Chapter 5: Claude Code needs Node 22, not 18 (ch05:119)

**Printed.** `npm install -g @anthropic-ai/claude-code` "needs Node 18 or newer."

**Today.** The package asks for Node 22 or newer.

**Shipped.** The README says Node 22.

```
$ npm view @anthropic-ai/claude-code version engines
version = '2.1.314'
engines = { node: '>=22.0.0' }
```

## Chapter 9: the calculator counts the hardware twice (ch09:51-57)

**Printed.** Step 2 spreads the hardware over the months you'll use it and adds that to the monthly local cost. Step 4 then divides the full hardware price by savings that already had that spread taken out, and step 5 subtracts the full price again. On the book's own hobbyist example (ch09:67: $60 cloud, about $5 electricity, a $600 GPU over two years) that gives 20 months and a first year of -$240.

**Today.** Paying off $600 with $55 a month takes about 10.9 months, and the first year ends $60 ahead. That's the model the chapter's own chart draws (a one-time jump at month zero, then an electricity-only slope) and the prose describes at ch09:25.

**Shipped.** [`break-even.sh`](chapters/09-cost-kill-math/break-even.sh): payback is `hardware / (cloud - electricity)`, first year is `(cloud - electricity) x 12 - hardware`. The spread-out monthly cost still prints, as information. The freelancer example (no hardware) comes out the same either way. The book calls both examples "illustrative placeholders", so the script uses none of their numbers as defaults; they appear here only as inputs.

```
$ awk 'BEGIN { c = 60; e = 5; h = 600; m = 24; local = e + h / m; s = c - local; printf "step 2 local %.2f/month, step 3 savings %.2f/month, step 4 break-even %.1f months, step 5 year one %.2f\n", local, s, h / s, s * 12 - h }'
step 2 local 30.00/month, step 3 savings 30.00/month, step 4 break-even 20.0 months, step 5 year one -240.00
[exit 0]

$ ./break-even.sh --cloud 60 --electricity 5 --hardware 600 --months 24
monthly cloud cost:  $60.00
monthly local cost:  $5.00 electricity
                     $30.00 with the $600.00 hardware spread over 24 months
saved each month:    $55.00 (cloud minus electricity)
break-even:          10.9 months ($600.00 / $55.00): ahead from month 11
first-year net:      +$60.00 ($55.00 x 12 - $600.00)
[exit 0]

$ ./break-even.sh --cloud 200 --electricity 5 --hardware 0
monthly cloud cost:  $200.00
monthly local cost:  $5.00 electricity
saved each month:    $195.00 (cloud minus electricity)
break-even:          immediate: no hardware to pay back
first-year net:      +$2340.00 ($195.00 x 12 - $0.00)
[exit 0]
```

## Chapter 12: the `codex sandbox` forms changed (ch12:44-48, appendices:66, ch07:23)

**Printed.** `codex sandbox macos -- <command>   # or: linux / windows`; "Add `--full-auto` and the sandbox is network-disabled and can write only to the current directory"; a write inside the folder succeeds; "Add `--log-denials` and the sandbox prints exactly what it blocked." Chapter 7 lists the approval policies as `untrusted`, `on-request` and `never`.

**Today.** On codex-cli 0.163.0 the OS word is taken as the command to run, `--full-auto` is rejected, plain `codex sandbox` blocks the write inside the folder too, and `--log-denials` printed `None found.` after a real denial. `-c sandbox_mode='"workspace-write"'` gives the behaviour the book describes: writes inside the folder and the temp folders, `Operation not permitted` elsewhere (the run below used a folder under the home folder), no network. `--ask-for-approval` lists `on-request` and `never`.

**Shipped.** [`stack-recipe.md`](chapters/12-daily-driver/stack-recipe.md) uses `codex sandbox -c sandbox_mode='"workspace-write"' -- <command>`. The daily launch at ch12:35-38 (`--sandbox workspace-write --ask-for-approval on-request`) is unchanged; all of its flags are in `codex --help`. The book never prints a Codex install command (ch04:87); the [chapter 4 README](chapters/04-first-local-agent/README.md) adds `npm install -g @openai/codex`.

Run in a scratch folder under the home folder, `project/`, with an empty `elsewhere/` beside it and an empty `CODEX_HOME`:

```
$ codex --version
codex-cli 0.163.0
[exit 0]

$ codex sandbox macos -- echo hi
sandbox-exec: execvp() of 'macos' failed: No such file or directory
[exit 71]

$ codex sandbox --full-auto -- echo hi
error: unexpected argument '--full-auto' found

  tip: to pass '--full-auto' as a value, use '-- --full-auto'

Usage: codex sandbox [OPTIONS] [COMMAND]... [COMMAND]

For more information, try '--help'.
[exit 2]

$ codex sandbox -- sh -c 'echo hi > inside.txt'
sh: inside.txt: Operation not permitted
[exit 1]

$ codex sandbox --log-denials -- sh -c 'echo hi > inside.txt'
sh: inside.txt: Operation not permitted

=== Sandbox denials ===
None found.
[exit 1]

$ codex sandbox -c sandbox_mode='"workspace-write"' -- sh -c 'echo hi > inside.txt'
[exit 0]

$ codex sandbox -c sandbox_mode='"workspace-write"' -- sh -c 'echo hi > ../elsewhere/outside.txt'
sh: ../elsewhere/outside.txt: Operation not permitted
[exit 1]

$ codex sandbox -c sandbox_mode='"workspace-write"' -- curl -s -m 5 -o /dev/null -w '%{http_code}\n' https://example.com
000
[exit 6]

$ curl -s -m 5 -o /dev/null -w '%{http_code}\n' https://example.com
200
[exit 0]

$ ls . ../elsewhere
.:
inside.txt

../elsewhere:
[exit 0]
```

```
$ codex --help | grep -A6 -- '--ask-for-approval'
  -a, --ask-for-approval <APPROVAL_POLICY>
          Configure when the model requires human approval before executing a command

          Possible values:
          - on-request: The model decides when to ask the user for approval
          - never:      Never ask for user approval Execution failures are immediately returned to
            the model
[exit 0]

$ codex --help | grep -cE 'full-auto|untrusted'
0
[exit 1]

$ codex --help | grep -A3 -- '--sandbox <'
  -s, --sandbox <SANDBOX_MODE>
          Select the sandbox policy to use when executing model-generated shell commands
          
          [possible values: read-only, workspace-write, danger-full-access]
[exit 0]
```
