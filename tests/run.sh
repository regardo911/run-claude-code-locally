#!/usr/bin/env bash
# tests/run.sh — checks the scripts and the book's files. bash, awk, python3 for one json parse.
# no network, no ollama, no harness, no key.
#
#   bash tests/run.sh
#
# one ok/FAIL line per check, a count at the end, non-zero exit on any failure.
# the checks are strings handed to eval, so shellcheck cannot see the variables they read,
# and local-claude.sh is sourced from a path built at run time.
# shellcheck disable=SC2034,SC1091
set -u
cd "$(dirname "$0")/.." || exit 1
ROOT=$(pwd)
PASS=0 FAILS=0
ok()  { PASS=$((PASS + 1)); echo "ok    $1"; }
bad() { FAILS=$((FAILS + 1)); echo "FAIL  $1"; }
check() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
CH04=chapters/04-first-local-agent
CH05=chapters/05-wire-claude-code
BE=chapters/09-cost-kill-math/break-even.sh
STACK=chapters/12-daily-driver/start-local-stack.sh

# --- every script parses ------------------------------------------------------------
for f in $(find . -name '*.sh' -not -path './.git/*' | sort); do
  check "bash -n $f" "bash -n '$f'"
done

# --- the book's files still match the print -----------------------------------------
cat > "$TMP/config.book" <<'EOF'
model_list:
  - model_name: "claude-3-5-sonnet"        # the heavy-thinking requests
    litellm_params:
      model: "ollama_chat/qwen2.5-coder"
      api_base: "http://localhost:11434"
  - model_name: "claude-3-5-haiku"         # the quick, cheap requests
    litellm_params:
      model: "ollama_chat/qwen2.5-coder:3b"
      api_base: "http://localhost:11434"
EOF
check "config.yaml body is ch05:96-104" "grep -v '^#' $CH05/config.yaml | diff - '$TMP/config.book'"
check "config.yaml uses ollama_chat/, never ollama/" "! grep -q '\"ollama/' $CH05/config.yaml"

cat > "$TMP/opencode.book" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": { "baseURL": "http://localhost:11434/v1" },
      "models": { "qwen2.5-coder": { "name": "Qwen2.5 Coder" } }
    }
  }
}
EOF
check "opencode.json is ch04:112-122" "diff $CH04/opencode.json '$TMP/opencode.book'"
check "opencode.json parses" "python3 -m json.tool $CH04/opencode.json"

check "local-claude.sh keeps the book's two exports" \
  "grep -qx 'export ANTHROPIC_BASE_URL=http://localhost:4000' $CH05/local-claude.sh && grep -qx 'export ANTHROPIC_AUTH_TOKEN=sk-local-anything' $CH05/local-claude.sh"
check "my-local-stack.txt keeps ch08:110-113" \
  "grep -qx '# model:   qwen2.5-coder:7b-instruct-q4_K_M' chapters/08-your-hardware/my-local-stack.txt && grep -qx '# context: OLLAMA_CONTEXT_LENGTH=32000' chapters/08-your-hardware/my-local-stack.txt"

# --- local-claude.sh, sourced -------------------------------------------------------
sourced() { ( unset ANTHROPIC_BASE_URL ANTHROPIC_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL; . "$CH05/local-claude.sh"; eval "printf '%s' \"\${$1:-}\"" ); }
names=$(sed -n 's/^ *- *model_name: *"\([^"]*\)".*/\1/p' $CH05/config.yaml)
check "sourced: ANTHROPIC_BASE_URL is the proxy on 4000" "[ \"\$(sourced ANTHROPIC_BASE_URL)\" = http://localhost:4000 ]"
check "sourced: ANTHROPIC_MODEL is a model_name in config.yaml" "printf '%s\n' \"\$names\" | grep -qxF \"\$(sourced ANTHROPIC_MODEL)\""
check "sourced: ANTHROPIC_DEFAULT_HAIKU_MODEL is a model_name in config.yaml" "printf '%s\n' \"\$names\" | grep -qxF \"\$(sourced ANTHROPIC_DEFAULT_HAIKU_MODEL)\""

# --- install.sh claude --files-only, in a throwaway HOME -----------------------------
H="$TMP/home"; mkdir -p "$H"
out=$(HOME="$H" ./install.sh claude --files-only 2>&1); rc=$?
check "install claude --files-only exits 0" "[ $rc -eq 0 ]"
check "config.yaml lands in ~/litellm/" "cmp -s $CH05/config.yaml '$H/litellm/config.yaml'"
check "local-claude.sh lands in ~/litellm/" "cmp -s $CH05/local-claude.sh '$H/litellm/local-claude.sh'"
check "no venv with --files-only" "[ ! -e '$H/litellm/.venv' ]"
check "paths print as ~/..." "printf '%s' \"\$out\" | grep -q 'copied:  ~/litellm/config.yaml'"
echo "# a line you added" >> "$H/litellm/config.yaml"
before=$(cksum "$H/litellm/config.yaml" "$H/litellm/local-claude.sh")
out=$(HOME="$H" ./install.sh claude --files-only 2>&1)
check "second run reports kept:" "printf '%s' \"\$out\" | grep -q 'kept:    ~/litellm/config.yaml'"
check "second run changes nothing" "[ \"\$(cksum '$H/litellm/config.yaml' '$H/litellm/local-claude.sh')\" = \"\$before\" ]"

H2="$TMP/home2"; mkdir -p "$H2"
HOME="$H2" ./install.sh claude --files-only --model my-model:7b >/dev/null 2>&1
check "--model rewrites the sonnet entry" "grep -q 'model: \"ollama_chat/my-model:7b\"' '$H2/litellm/config.yaml'"
check "--model leaves the haiku entry" "grep -q 'model: \"ollama_chat/qwen2.5-coder:3b\"' '$H2/litellm/config.yaml'"
check "--model refuses a name with a space" "! HOME='$TMP/home3' ./install.sh claude --files-only --model 'bad name'"

for v in 1.82.7 1.82.8; do
  H4="$TMP/home-$v"; mkdir -p "$H4"
  out=$(HOME="$H4" PATH=/nonexistent:/usr/bin:/bin ./install.sh claude --litellm "$v" 2>&1); rc=$?
  check "--litellm $v refused" "[ $rc -ne 0 ] && printf '%s' \"\$out\" | grep -q 'malware'"
  check "--litellm $v refused before anything was written" "[ ! -e '$H4/litellm' ]"
done

# --- install.sh opencode ------------------------------------------------------------
P="$TMP/project"; mkdir -p "$P"
check "install opencode exits 0" "./install.sh opencode '$P'"
check "opencode.json lands in the project and parses" "python3 -m json.tool '$P/opencode.json'"
check "second opencode run keeps the file" "./install.sh opencode '$P' | grep -q '^kept:'"
P2="$TMP/project2"; mkdir -p "$P2"
./install.sh opencode "$P2" --model qwen3-coder >/dev/null 2>&1
check "opencode --model writes your slug and still parses" "grep -q '\"qwen3-coder\": { \"name\": \"qwen3-coder\" }' '$P2/opencode.json' && python3 -m json.tool '$P2/opencode.json'"
check "opencode refuses a folder that does not exist" "! ./install.sh opencode '$TMP/nope'"

# --- break-even.sh ------------------------------------------------------------------
out=$($BE --cloud 60 --electricity 5 --hardware 600 --months 24)
check "hobbyist (ch09:67 inputs): 10.9 months" "printf '%s' \"\$out\" | grep -q '10.9 months'"
check "hobbyist: first year +\$60.00" "printf '%s' \"\$out\" | grep -q 'first-year net:      +\\\$60.00'"
check "hobbyist: \$30.00 a month with the hardware spread" "printf '%s' \"\$out\" | grep -q '\\\$30.00 with the \\\$600.00 hardware spread over 24 months'"
out=$($BE --cloud 200 --electricity 5 --hardware 0)
check "freelancer (ch09:65 inputs): immediate" "printf '%s' \"\$out\" | grep -q 'immediate'"
check "freelancer: first year +\$2340.00" "printf '%s' \"\$out\" | grep -q '+\\\$2340.00'"
check "cloud at or under electricity: never" "$BE --cloud 4 --electricity 5 --hardware 0 | grep -q 'never on cost alone'"
check "missing --hardware: exit non-zero" "! $BE --cloud 60 --electricity 5"
check "missing --hardware: prints usage" "$BE --cloud 60 --electricity 5 2>&1 | grep -q '^usage:'"
check "refuses a non-number" "! $BE --cloud sixty --electricity 5 --hardware 0"
check "no defaults: no arguments is an error" "! $BE"

# --- start-local-stack.sh --check with nothing installed ------------------------------
out=$(cd "$TMP" && env -i HOME="$TMP/empty" PATH=/usr/bin:/bin bash "$ROOT/$STACK" claude --check 2>&1); rc=$?
check "stack --check, nothing running: exits non-zero" "[ $rc -eq 1 ]"
check "stack --check names the first layer down" "printf '%s' \"\$out\" | grep -q '^first layer down: ollama is not installed'"
check "stack: unknown harness is an error" "! bash $STACK vim --check"

# --- what the repo must not hold -----------------------------------------------------
check "no harness config at the root" "[ ! -e opencode.json ] && [ ! -e AGENTS.md ] && [ ! -e CLAUDE.md ] && [ ! -e .codex ] && [ ! -e .claude ]"
check "no script passes a bypass flag" "! grep -rn -e '--dangerously' --include='*.sh' . | grep -v '^./tests/'"

echo
echo "$PASS passed, $FAILS failed"
[ "$PASS" -gt 0 ] && [ "$FAILS" -eq 0 ]
