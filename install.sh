#!/usr/bin/env bash
# install.sh — one-line installer for claude-init
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/HankH18/claude-init/main/install.sh | bash
#
# Optional environment overrides:
#   CLAUDE_INIT_REPO    — owner/repo (default: HankH18/claude-init)
#   CLAUDE_INIT_BRANCH  — branch or tag (default: main)
#   CLAUDE_INIT_PREFIX  — install dir (default: $HOME/.local/bin)
#
# Examples:
#   # Install from a private fork
#   CLAUDE_INIT_REPO=acme/claude-init curl -fsSL .../install.sh | bash
#
#   # Pin to a specific tag
#   CLAUDE_INIT_BRANCH=v1.3.0 curl -fsSL .../install.sh | bash
#
#   # Install system-wide (needs sudo on the curl pipe — see README)
#   CLAUDE_INIT_PREFIX=/usr/local/bin curl ... | sudo -E bash

set -euo pipefail

REPO="${CLAUDE_INIT_REPO:-HankH18/claude-init}"
BRANCH="${CLAUDE_INIT_BRANCH:-main}"
PREFIX="${CLAUDE_INIT_PREFIX:-$HOME/.local/bin}"
DEST="$PREFIX/claude-init"
URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/bin/claude-init"

# ---------- color (only if stderr is a tty) ----------
if [[ -t 2 ]]; then
  R=$'\033[0m'; B=$'\033[1m'; GR=$'\033[32m'; YL=$'\033[33m'; RD=$'\033[31m'
else
  R=""; B=""; GR=""; YL=""; RD=""
fi
say()  { printf "%s\n" "$*" >&2; }
ok()   { printf "${GR}✓${R}  %s\n" "$*" >&2; }
warn() { printf "${YL}⚠${R}  %s\n" "$*" >&2; }
die()  { printf "${RD}✗${R}  %s\n" "$*" >&2; exit 1; }

# ---------- preflight ----------
command -v curl >/dev/null 2>&1 || die "curl is required."
command -v bash >/dev/null 2>&1 || die "bash is required."

if [[ "$REPO" == *"HankH18"* ]]; then
  die "This installer still has the placeholder repo name. Edit install.sh and replace HankH18 with your GitHub username, or set CLAUDE_INIT_REPO=owner/repo when running."
fi

# ---------- download ----------
say ""
say "${B}claude-init installer${R}"
say "  source: $URL"
say "  target: $DEST"
say ""

mkdir -p "$PREFIX"
if ! curl -fsSL "$URL" -o "$DEST.tmp"; then
  die "Download failed. Check that $REPO exists and the branch '$BRANCH' has bin/claude-init."
fi

# Sanity-check it's a bash script
if ! head -n 1 "$DEST.tmp" | grep -q '^#!/usr/bin/env bash'; then
  rm -f "$DEST.tmp"
  die "Downloaded file doesn't look like a bash script. Aborting."
fi

mv "$DEST.tmp" "$DEST"
chmod +x "$DEST"
ok "Installed to $DEST"

# ---------- PATH check ----------
case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *)
    warn "$PREFIX is not on your PATH."
    say ""
    say "  Add this to your shell rc (~/.zshrc, ~/.bashrc, etc.):"
    say "    ${B}export PATH=\"$PREFIX:\$PATH\"${R}"
    say ""
    say "  Then reload: ${B}source ~/.zshrc${R}  (or restart your terminal)"
    say ""
    ;;
esac

# ---------- verify ----------
if "$DEST" --help >/dev/null 2>&1; then
  ok "Verified: $DEST --help works"
fi

# ---------- next steps ----------
say ""
say "${GR}${B}Done.${R}"
say ""
say "Next:"
say "  ${B}claude-init --configure${R}    # (optional) set global model defaults"
say "  ${B}cd /path/to/project${R}        # then..."
say "  ${B}claude-init${R}                # initialize the project"
say ""
say "Help:    ${B}claude-init --help${R}"
say "Docs:    https://github.com/$REPO"
say ""