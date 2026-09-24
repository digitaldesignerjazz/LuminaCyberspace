#!/usr/bin/env bash
# Compute the next sequential release tag (SemVer pre-release counter).
#   Usage: scripts/next-version.sh <alpha|beta|rc|stable> [base-version]
#   Reads existing tags from `git tag` (run `git fetch --tags` first).
#   Examples: v1.0.0-alpha.3 exists -> "alpha" => v1.0.0-alpha.4
#             "beta" (no beta yet)  => v1.0.0-beta.1
#             "stable"              => v1.0.0
# Prints the new tag (with leading "v") on stdout.
set -euo pipefail

CHANNEL="${1:?usage: $0 <alpha|beta|rc|stable> [base-version]}"
BASE="${2:-}"
BASE="${BASE#v}"

case "$CHANNEL" in alpha|beta|rc|stable) ;; *) echo "invalid channel: $CHANNEL" >&2; exit 2 ;; esac

rank() { case "$1" in alpha) echo 1 ;; beta) echo 2 ;; rc) echo 3 ;; stable) echo 4 ;; esac; }

# All tags following the scheme vX.Y.Z or vX.Y.Z-(alpha|beta|rc).N
TAGS="$(git tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-(alpha|beta|rc)\.[0-9]+)?$' || true)"

if [ -z "$BASE" ]; then
  # Default base = highest X.Y.Z among existing tags
  BASE="$(printf '%s\n' "$TAGS" | sed -E 's/^v([0-9]+\.[0-9]+\.[0-9]+).*/\1/' | grep -v '^$' | sort -V | tail -n1 || true)"
  BASE="${BASE:-1.0.0}"
fi
if ! [[ "$BASE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "invalid base version: $BASE (expected X.Y.Z)" >&2; exit 2
fi

if printf '%s\n' "$TAGS" | grep -qx "v${BASE}"; then
  echo "v${BASE} is already released as stable; pass a new base version (e.g. a higher X.Y.Z)" >&2
  exit 1
fi

# Highest channel already used for this base (prevents going backwards, e.g. beta -> alpha)
MAXRANK=0
for c in alpha beta rc; do
  if printf '%s\n' "$TAGS" | grep -q "^v${BASE}-${c}\."; then MAXRANK="$(rank "$c")"; fi
done
if [ "$(rank "$CHANNEL")" -lt "$MAXRANK" ]; then
  echo "channel '$CHANNEL' would go backwards for ${BASE} (a later pre-release channel already exists)" >&2
  exit 1
fi

if [ "$CHANNEL" = stable ]; then
  echo "v${BASE}"
  exit 0
fi

LAST="$(printf '%s\n' "$TAGS" | sed -nE "s/^v${BASE//./\\.}-${CHANNEL}\.([0-9]+)$/\1/p" | sort -n | tail -n1)"
echo "v${BASE}-${CHANNEL}.$(( ${LAST:-0} + 1 ))"
