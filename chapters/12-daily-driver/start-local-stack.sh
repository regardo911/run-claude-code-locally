#!/usr/bin/env bash
# start-local-stack.sh — chapter 12 (ch12:15-25), the "tiny shell script" that starts your stack.
#
#   start-local-stack.sh claude   [--check]
#   start-local-stack.sh codex    [--model <ollama-slug>] [--check]
#   start-local-stack.sh opencode [--check]
#
# checks each layer in the book's order (ollama, model, proxy, harness) and says which one is
# down. without --check it starts what is not running (ollama serve, the litellm proxy on
# 127.0.0.1:4000) and then launches the harness in the folder you ran it from. it never pulls a
# model: a missing model stops it with the ollama pull line to run.
# local-claude.sh is your file in ~/litellm, so shellcheck cannot follow it
# shellcheck disable=SC1090
set -eu

LITELLM_DIR="$HOME/litellm"
VENV="$LITELLM_DIR/.venv"
OLLAMA_URL="http://localhost:11434"
PROXY_URL="http://localhost:4000"

usage() {
  sed -n '4,6p' "$0" | sed 's/^# *//'
}

harness="" model="" check=0
while [ $# -gt 0 ]; do
  case "$1" in
    claude|codex|opencode) harness=$1; shift ;;
    --model) [ $# -ge 2 ] || { echo "--model needs a value" >&2; exit 2; }; model=$2; shift 2 ;;
    --check) check=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
done
[ -n "$harness" ] || { usage >&2; exit 2; }
[ -z "$model" ] || [ "$harness" = codex ] || { echo "--model is for codex; claude reads ~/litellm/config.yaml and opencode reads ./opencode.json" >&2; exit 2; }

DOWN=""
ok()   { echo "ok    $1"; }
down() { echo "down  $1"; echo "      $2"; [ -n "$DOWN" ] || DOWN=$1; }
answers() { curl -s -m 3 -o /dev/null "$1" 2>/dev/null; }
finish_check() {
  if [ -n "$DOWN" ]; then echo; echo "first layer down: $DOWN"; exit 1; fi
  echo; echo "all layers up"; exit 0
}
# a layer is down: report it, and either keep checking (--check) or stop here
stop_or_continue() { [ "$check" -eq 1 ] || finish_check; }

# --- 1. ollama on 11434 (chapter 4) -------------------------------------------------
if ! command -v ollama >/dev/null 2>&1; then
  down "ollama is not installed" "install it from ollama.com/download (chapter 4)"
  finish_check
fi
if answers "$OLLAMA_URL/api/tags"; then
  ok "ollama answering on localhost:11434"
elif [ "$check" -eq 1 ]; then
  down "ollama is not answering on localhost:11434" "start it: ollama serve (or open the Ollama app)"
  finish_check
else
  log="${TMPDIR:-/tmp}/ollama-serve.log"
  echo "start ollama serve (log: $log)"
  nohup ollama serve >"$log" 2>&1 &
  i=0; until answers "$OLLAMA_URL/api/tags"; do
    i=$((i + 1)); [ "$i" -le 20 ] || { down "ollama did not come up in 20s" "read $log"; finish_check; }
    sleep 1
  done
  ok "ollama answering on localhost:11434"
fi

# --- 2. the models this harness will ask for (chapters 4-6) -------------------------
case "$harness" in
  claude)
    [ -f "$LITELLM_DIR/config.yaml" ] || { down "no ~/litellm/config.yaml" "run ./install.sh claude from the repo"; finish_check; }
    want=$(sed -n 's/^ *model: *"ollama_chat\/\([^"]*\)".*/\1/p' "$LITELLM_DIR/config.yaml" | awk '!seen[$0]++') ;;
  codex) want=${model:-qwen2.5-coder} ;;
  opencode)
    [ -f opencode.json ] || { down "no opencode.json in $(pwd)" "run ./install.sh opencode $(pwd) from the repo"; finish_check; }
    want=$(sed -n 's/.*"models": *{ *"\([^"]*\)".*/\1/p' opencode.json) ;;
esac
[ -n "$want" ] || { down "no model names found to check" "open the config file and look at the model lines"; finish_check; }
pulled=$(ollama ls 2>/dev/null | awk 'NR > 1 { print $1 }')
for m in $want; do
  case "$m" in *:*) tag=$m ;; *) tag="$m:latest" ;; esac
  if printf '%s\n' "$pulled" | grep -qxF "$tag"; then
    ok "model pulled: $m"
  else
    down "model not pulled: $m" "ollama pull $m   (or put a model ollama ls shows in its place)"
  fi
done
[ -z "$DOWN" ] || stop_or_continue

# --- 3. claude only: litellm, local-claude.sh, the proxy (chapter 5) ----------------
if [ "$harness" = claude ]; then
  ver=$("$VENV/bin/pip" show litellm 2>/dev/null | sed -n 's/^Version: //p' || true)
  case "$ver" in
    "") down "litellm is not installed in ~/litellm/.venv" "run ./install.sh claude from the repo" ;;
    1.82.7|1.82.8) down "litellm $ver is a poisoned release" "uninstall it, install another version, rotate your keys (chapter 5)"; finish_check ;;
    *) ok "litellm $ver in ~/litellm/.venv" ;;
  esac

  env_file="$LITELLM_DIR/local-claude.sh"
  if [ ! -f "$env_file" ]; then
    down "no ~/litellm/local-claude.sh" "run ./install.sh claude from the repo"
  else
    names=$(sed -n 's/^ *- *model_name: *"\{0,1\}\([^"# ]*\)"\{0,1\}.*/\1/p' "$LITELLM_DIR/config.yaml")
    for var in ANTHROPIC_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL; do
      asked=$( (unset "$var"; . "$env_file"; eval "printf '%s' \"\${$var:-}\"") )
      if [ -z "$asked" ]; then
        [ "$var" = ANTHROPIC_DEFAULT_HAIKU_MODEL ] && continue
        down "local-claude.sh sets no $var" "add: export $var=<a model_name from config.yaml>"
      elif printf '%s\n' "$names" | grep -qxF "$asked"; then
        ok "local-claude.sh: $var=$asked, and config.yaml maps it"
      else
        down "local-claude.sh: $var=$asked; config.yaml maps $(printf '%s\n' "$names" | paste -sd ' ' -)" "make them the same name"
      fi
    done
  fi
  [ -z "$DOWN" ] || stop_or_continue

  if answers "$PROXY_URL/health/liveliness"; then
    ok "proxy answering on localhost:4000"
  elif [ "$check" -eq 1 ]; then
    down "proxy is not answering on localhost:4000" "LITELLM_MASTER_KEY=<your ANTHROPIC_AUTH_TOKEN> ~/litellm/.venv/bin/litellm --config ~/litellm/config.yaml --host 127.0.0.1"
  else
    token=$( (. "$env_file"; printf '%s' "${ANTHROPIC_AUTH_TOKEN:-}") )
    [ -n "$token" ] || { down "local-claude.sh sets no ANTHROPIC_AUTH_TOKEN" "the proxy needs it as its master key"; finish_check; }
    echo "start the litellm proxy on 127.0.0.1:4000 (log: ~/litellm/proxy.log)"
    LITELLM_MASTER_KEY=$token nohup "$VENV/bin/litellm" --config "$LITELLM_DIR/config.yaml" --host 127.0.0.1 \
      >"$LITELLM_DIR/proxy.log" 2>&1 &
    i=0; until answers "$PROXY_URL/health/liveliness"; do
      i=$((i + 1)); [ "$i" -le 60 ] || { down "proxy did not come up in 60s" "read ~/litellm/proxy.log"; finish_check; }
      sleep 1
    done
    ok "proxy answering on localhost:4000"
  fi
  if command -v lsof >/dev/null 2>&1; then
    bound=$(lsof -nP -iTCP:4000 -sTCP:LISTEN 2>/dev/null | awk 'NR > 1 { print $9 }' | head -1)
    case "$bound" in
      ""|127.0.0.1:4000|localhost:4000|"[::1]:4000") ;;
      *) down "proxy listens on $bound, which other machines can reach" "restart it with --host 127.0.0.1" ;;
    esac
  fi
fi

# --- 4. the harness (chapters 4, 5, 7) ----------------------------------------------
if command -v "$harness" >/dev/null 2>&1; then
  ok "$harness is installed"
else
  case "$harness" in
    claude) fix="npm install -g @anthropic-ai/claude-code" ;;
    codex) fix="npm install -g @openai/codex" ;;
    opencode) fix="npm install -g opencode-ai" ;;
  esac
  down "$harness is not installed" "$fix"
fi

if [ "$check" -eq 1 ] || [ -n "$DOWN" ]; then finish_check; fi

echo
case "$harness" in
  claude)
    . "$env_file"
    echo "claude in $(pwd), through the proxy"
    exec claude ;;
  codex)
    echo "codex in $(pwd) on $want, sandboxed to this folder, asking before risky commands"
    exec codex --oss --local-provider ollama -m "$want" --sandbox workspace-write --ask-for-approval on-request ;;
  opencode)
    echo "opencode in $(pwd)"
    exec opencode ;;
esac
