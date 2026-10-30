# chapter 5 (ch05:173-178). the lines under each "changed:" comment are not in the print; BOOK-FIXES.md shows why.
# local-claude.sh — source this to make Claude Code run on your machine
export ANTHROPIC_BASE_URL=http://localhost:4000
export ANTHROPIC_AUTH_TOKEN=sk-local-anything
# changed: without a model name, claude asks the proxy for its own default, which config.yaml does not map.
# both names below must match a model_name in ~/litellm/config.yaml.
export ANTHROPIC_MODEL=claude-3-5-sonnet
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-3-5-haiku
# changed: litellm lives in ~/litellm/.venv, refuses to start without a master key, and listens on every interface unless told otherwise.
# (start the proxy separately: LITELLM_MASTER_KEY=sk-local-anything ~/litellm/.venv/bin/litellm --config ~/litellm/config.yaml --host 127.0.0.1)
