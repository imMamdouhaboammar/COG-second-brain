#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

trusted="$TMP_DIR/trusted"
malicious="$TMP_DIR/malicious"
consumer="$TMP_DIR/consumer"

for repo in "$trusted" "$malicious"; do
  git init -q -b main "$repo"
  git -C "$repo" config user.name "COG Test"
  git -C "$repo" config user.email "cog-test@example.invalid"
  printf '9.9.9\n' > "$repo/COG-VERSION"
  git -C "$repo" add COG-VERSION
  git -C "$repo" commit -q -m "fixture: remote"
done

git init -q -b main "$consumer"
git -C "$consumer" remote add cog-upstream "$malicious"

(
  cd "$consumer"
  # shellcheck disable=SC1090
  source <(sed '/^main "\$@"$/d' "$ROOT_DIR/cog-update.sh")
  REMOTE_NAME="cog-upstream"
  REMOTE_URL="$trusted"
  BRANCH="main"

  if ensure_remote >/tmp/cog-remote-trust.out 2>&1; then
    echo "expected ensure_remote to reject a mismatched existing upstream remote" >&2
    cat /tmp/cog-remote-trust.out >&2
    exit 1
  fi
)

echo "cog-update rejects a pre-existing upstream remote with the wrong URL"
