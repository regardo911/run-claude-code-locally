#!/usr/bin/env bash
# install.sh — chapters 4 and 5. puts the book's files where the book says they go.
#
#   ./install.sh claude   [--model <ollama-slug>] [--litellm <version>] [--files-only]
#   ./install.sh opencode <project-dir> [--model <ollama-slug>]
#
# claude:   copies config.yaml and local-claude.sh into ~/litellm/ (ch05:65), makes the
#           python venv litellm goes into (~/litellm/.venv), then lists the litellm versions
#           on PyPI or installs the one you name with --litellm.
# opencode: copies opencode.json into your project (ch04:109).
#
# it never overwrites a file you have, never pulls a model and never starts a server.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
CH04="$HERE/chapters/04-first-local-agent"
CH05="$HERE/chapters/05-wire-claude-code"
LITELLM_DIR="$HOME/litellm"
VENV="$LITELLM_DIR/.venv"

usage() {
  cat <<'EOF'
usage:
  ./install.sh claude   [--model <ollama-slug>] [--litellm <version>] [--files-only]
  ./install.sh opencode <project-dir> [--model <ollama-slug>]

claude     copy config.yaml + local-claude.sh to ~/litellm/, make ~/litellm/.venv,
           then list litellm versions (no --litellm) or install the one you name.
  --model       serve claude-3-5-sonnet with ollama_chat/<slug> instead of qwen2.5-coder
  --litellm     install litellm[proxy]==<version> into ~/litellm/.venv (never 1.82.7 or 1.82.8)
  --files-only  copy the two files and stop: no venv, no network
opencode   copy opencode.json into <project-dir>
  --model       list <slug> in opencode.json instead of qwen2.5-coder

Existing files are reported as "kept:" and left alone.
EOF
}

die() { echo "install.sh: $*" >&2; exit 1; }
# the ~ is printed for you to read, not expanded
# shellcheck disable=SC2088
tilde() { case "$1" in "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;; *) printf '%s' "$1" ;; esac; }

# an ollama slug: name[:tag], letters, digits and . _ - : / only (it ends up inside a sed pattern)
check_slug() {
  case "$1" in
    ''|*[!A-Za-z0-9._:/-]*) die "--model '$1' is not an ollama model name (try: ollama ls)" ;;
  esac
}

# copy $1 to $2 unless $2 exists; prints copied:/kept:, returns 1 when kept
place() {
  if [ -e "$2" ]; then
    echo "kept:    $(tilde "$2") (already there, not touched)"
    return 1
  fi
  cp "$1" "$2"
  echo "copied:  $(tilde "$2")"
}

claude_install() {
  model="" version="" files_only=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --model) [ $# -ge 2 ] || die "--model needs a value"; model=$2; shift 2 ;;
      --litellm) [ $# -ge 2 ] || die "--litellm needs a value"; version=$2; shift 2 ;;
      --files-only) files_only=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option '$1' (see ./install.sh --help)" ;;
    esac
  done
  [ -z "$model" ] || check_slug "$model"
  # ch05:25. refused here, before anything touches the network.
  case "$version" in
    1.82.7|1.82.8) die "litellm $version is one of the two releases that shipped credential-stealing malware (chapter 5). pick another version." ;;
    *[!0-9A-Za-z.]*) die "--litellm '$version' is not a version number" ;;
  esac

  if [ -d "$LITELLM_DIR" ]; then
    echo "found:   $(tilde "$LITELLM_DIR")/"
  else
    mkdir -p "$LITELLM_DIR"
    echo "made:    $(tilde "$LITELLM_DIR")/"
  fi

  if place "$CH05/config.yaml" "$LITELLM_DIR/config.yaml"; then
    if [ -n "$model" ]; then
      # the sonnet line is the only one that ends in qwen2.5-coder" ; the haiku line ends in :3b"
      sed "s|\"ollama_chat/qwen2.5-coder\"|\"ollama_chat/$model\"|" "$LITELLM_DIR/config.yaml" > "$LITELLM_DIR/config.yaml.tmp"
      mv "$LITELLM_DIR/config.yaml.tmp" "$LITELLM_DIR/config.yaml"
      echo "         claude-3-5-sonnet -> ollama_chat/$model"
    fi
  elif [ -n "$model" ]; then
    echo "         --model not applied: edit the model: line in $(tilde "$LITELLM_DIR")/config.yaml yourself"
  fi
  place "$CH05/local-claude.sh" "$LITELLM_DIR/local-claude.sh" || true

  if [ "$files_only" -eq 0 ]; then
    command -v python3 >/dev/null 2>&1 || die "python3 not found. litellm needs Python 3.10 or newer (python.org, or: brew install python)."
    pyver=$(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])')
    python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' \
      || die "python3 is $pyver. litellm needs 3.10 or newer (python.org, or: brew install python), then rerun."
    if [ -x "$VENV/bin/pip" ]; then
      echo "kept:    $(tilde "$VENV") (Python $("$VENV/bin/python" -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])'))"
    else
      python3 -m venv "$VENV"
      echo "made:    $(tilde "$VENV") (Python $pyver)"
    fi

    have=$("$VENV/bin/pip" show litellm 2>/dev/null | sed -n 's/^Version: //p')
    case "$have" in
      1.82.7|1.82.8)
        echo "WARNING: litellm $have is installed in $(tilde "$VENV"). it is one of the two poisoned releases." >&2
        echo "         uninstall it ($(tilde "$VENV")/bin/pip uninstall litellm), install another version, and rotate every key that was in your environment." >&2
        exit 1 ;;
    esac

    if [ -z "$version" ]; then
      [ -z "$have" ] || echo "found:   litellm $have in $(tilde "$VENV")"
      out=$("$VENV/bin/pip" index versions litellm 2>/dev/null) || die "could not read the version list from PyPI (are you online?)"
      newest=$(printf '%s\n' "$out" | sed -n 's/^litellm (\(.*\))$/\1/p')
      list=$(printf '%s\n' "$out" | sed -n 's/^Available versions: //p' | tr -d ' ' | tr ',' '\n' | head -6 | paste -sd ' ' -)
      echo "PyPI:    newest first: $list ..."
      echo "         (from $(tilde "$VENV")/bin/pip index versions litellm)"
      echo
      echo "check the one you pick is not 1.82.7 or 1.82.8, then install it:"
      echo "  ./install.sh claude --litellm ${newest:-<version>}"
      exit 0
    fi

    if [ "$have" = "$version" ]; then
      echo "kept:    litellm $have in $(tilde "$VENV")"
    else
      echo "pip:     $(tilde "$VENV")/bin/pip install \"litellm[proxy]==$version\""
      "$VENV/bin/pip" install --quiet --disable-pip-version-check "litellm[proxy]==$version" \
        || die "pip could not install litellm[proxy]==$version (is that version on the list?)"
      echo "added:   litellm $("$VENV/bin/pip" show litellm | sed -n 's/^Version: //p') in $(tilde "$VENV")"
    fi
  fi

  models=$(sed -n 's/^ *model: *"ollama_chat\/\([^"]*\)".*/\1/p' "$LITELLM_DIR/config.yaml" | awk '!seen[$0]++' | paste -sd ' ' -)
  echo
  echo "config.yaml sends requests to these ollama models: ${models:-none found}"
  echo "pull any that ollama ls does not show, then:"
  echo "  1. LITELLM_MASTER_KEY=sk-local-anything ~/litellm/.venv/bin/litellm --config ~/litellm/config.yaml --host 127.0.0.1"
  echo "  2. in a second terminal: source ~/litellm/local-claude.sh"
  echo "  3. cd into your own repo and run: claude"
}

opencode_install() {
  [ $# -ge 1 ] || die "opencode needs a project folder: ./install.sh opencode ~/your-project"
  case "$1" in -h|--help) usage; exit 0 ;; esac
  dir=$1; shift; model=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --model) [ $# -ge 2 ] || die "--model needs a value"; model=$2; shift 2 ;;
      *) die "unknown option '$1' (see ./install.sh --help)" ;;
    esac
  done
  [ -z "$model" ] || check_slug "$model"
  [ -d "$dir" ] || die "$dir is not a folder"
  dir=$(cd "$dir" && pwd)
  listed="ollama/${model:-qwen2.5-coder}"
  if place "$CH04/opencode.json" "$dir/opencode.json"; then
    if [ -n "$model" ]; then
      sed "s|\"qwen2.5-coder\": { \"name\": \"Qwen2.5 Coder\" }|\"$model\": { \"name\": \"$model\" }|" "$dir/opencode.json" > "$dir/opencode.json.tmp"
      mv "$dir/opencode.json.tmp" "$dir/opencode.json"
      echo "         model: $model"
    fi
  else
    # kept your file, so --model was not applied; don't promise a model we didn't write
    listed="the ollama/ model named in your opencode.json"
  fi
  echo
  echo "next: cd $(tilde "$dir") && opencode models"
  echo "      the list should include $listed. then run: opencode"
}

[ $# -ge 1 ] || { usage; exit 1; }
cmd=$1; shift
case "$cmd" in
  claude) claude_install "$@" ;;
  opencode) opencode_install "$@" ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 1 ;;
esac
