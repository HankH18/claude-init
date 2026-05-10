#!/usr/bin/env bash
# setup-fork.sh — one-shot placeholder replacement for your fork of claude-init.
#
# Replaces <YOUR-GITHUB-USERNAME> in install.sh, README.md, and CHANGELOG.md,
# and <YOUR NAME> in LICENSE, in one pass. Pure bash — no sed portability woes.
#
# Usage:
#   ./setup-fork.sh USERNAME            # defaults LICENSE name to USERNAME
#   ./setup-fork.sh USERNAME "Real Name"
#
# Examples:
#   ./setup-fork.sh acme-corp
#   ./setup-fork.sh hank-dev "Hank Smith"
#
# Run once, then commit. Re-running is a no-op (it detects the placeholders are
# gone and exits cleanly).

set -euo pipefail

# ---------- color ----------
if [[ -t 1 ]]; then
  R=$'\033[0m'; B=$'\033[1m'; D=$'\033[2m'; GR=$'\033[32m'; YL=$'\033[33m'; RD=$'\033[31m'
else
  R=""; B=""; D=""; GR=""; YL=""; RD=""
fi
ok()   { printf "${GR}✓${R}  %s\n" "$*"; }
warn() { printf "${YL}⚠${R}  %s\n" "$*"; }
die()  { printf "${RD}✗${R}  %s\n" "$*" >&2; exit 1; }

# ---------- args ----------
if [[ $# -lt 1 ]]; then
  cat <<EOF
Usage: $0 USERNAME [REAL_NAME]

  USERNAME    Your GitHub user or org (e.g. 'acme-corp', 'hank-dev')
  REAL_NAME   Name for the LICENSE copyright line (defaults to USERNAME)

Examples:
  $0 acme-corp
  $0 hank-dev "Hank Smith"
EOF
  exit 1
fi

USERNAME="$1"
REAL_NAME="${2:-$USERNAME}"

# ---------- validate username ----------
# GitHub username/org rules: alphanumerics and single hyphens, can't start/end
# with hyphen, max 39 chars. We're lenient — just refuse spaces and slashes.
if [[ "$USERNAME" =~ [[:space:]/] ]]; then
  die "Username '$USERNAME' contains spaces or slashes. GitHub usernames don't allow these."
fi
if [[ -z "$USERNAME" ]]; then
  die "Username cannot be empty."
fi

# ---------- preflight: are we in the right directory? ----------
for required in install.sh README.md LICENSE CHANGELOG.md bin/claude-init; do
  [[ -f "$required" ]] || die "Expected file '$required' not found. Run this from the repo root."
done

# ---------- detect already-set-up repo ----------
# Note: we exclude setup-fork.sh itself, since it documents the placeholder
# strings as part of its own usage text.
REMAINING=$(grep -rl "<YOUR-GITHUB-USERNAME>\|<YOUR NAME>" . 2>/dev/null \
              --include='*.sh' --include='*.md' --include='LICENSE' \
              --exclude='setup-fork.sh' || true)
if [[ -z "$REMAINING" ]]; then
  warn "No placeholders found — this fork has already been set up. Nothing to do."
  exit 0
fi

# ---------- pure-bash file rewrite ----------
# Reads the file, applies parameter-expansion substitution, writes back.
# Works identically on macOS BSD bash and GNU bash; no sed -i quirks.
rewrite_file() {
  local file="$1" pattern="$2" replacement="$3"
  local content
  content=$(<"$file") || die "Couldn't read $file"
  if [[ "$content" != *"$pattern"* ]]; then
    return 1  # no match — caller decides whether to log
  fi
  content="${content//$pattern/$replacement}"
  printf "%s" "$content" > "$file" || die "Couldn't write $file"
  return 0
}

printf "\n${B}Setting up your fork${R}\n"
printf "  GitHub user/org : ${B}%s${R}\n" "$USERNAME"
printf "  LICENSE name    : ${B}%s${R}\n\n" "$REAL_NAME"

CHANGED=0
for file in install.sh README.md CHANGELOG.md; do
  if rewrite_file "$file" "<YOUR-GITHUB-USERNAME>" "$USERNAME"; then
    ok "$file ${D}— GitHub username substituted${R}"
    CHANGED=$((CHANGED + 1))
  fi
done

if rewrite_file "LICENSE" "<YOUR NAME>" "$REAL_NAME"; then
  ok "LICENSE ${D}— copyright name substituted${R}"
  CHANGED=$((CHANGED + 1))
fi

# ---------- verify nothing slipped through ----------
LEFTOVERS=$(grep -rl "<YOUR-GITHUB-USERNAME>\|<YOUR NAME>" . 2>/dev/null \
              --include='*.sh' --include='*.md' --include='LICENSE' \
              --exclude='setup-fork.sh' || true)
if [[ -n "$LEFTOVERS" ]]; then
  warn "Some placeholders remained — check these files manually:"
  printf '   %s\n' $LEFTOVERS
  exit 1
fi

# ---------- next steps ----------
printf "\n${GR}${B}Done.${R} Modified %d file(s).\n\n" "$CHANGED"
cat <<EOF
${B}Next steps:${R}
  ${D}1.${R}  Review the diffs:
        ${B}git diff${R}                                          (if already a git repo)
        ${B}grep -r "$USERNAME" install.sh README.md${R}          (sanity check otherwise)

  ${D}2.${R}  Initialize git and push:
        ${B}git init${R}
        ${B}git add -A${R}
        ${B}git commit -m "Initial release: claude-init"${R}
        ${B}gh repo create claude-init --public --source=. --push${R}
        (or create the repo on github.com first, then ${B}git remote add${R} + ${B}git push${R})

  ${D}3.${R}  Test the install one-liner from a fresh shell:
        ${B}curl -fsSL https://raw.githubusercontent.com/$USERNAME/claude-init/main/install.sh | bash${R}

  ${D}4.${R}  (Optional) Tag a release for users to pin against:
        ${B}git tag v1.3.0 && git push --tags${R}
EOF
