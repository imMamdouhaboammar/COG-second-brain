#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

upstream="$TMP_DIR/upstream"
consumer="$TMP_DIR/consumer"

git init -q -b main "$upstream"
git -C "$upstream" config user.name "COG Test"
git -C "$upstream" config user.email "cog-test@example.invalid"
mkdir -p "$upstream/scripts"
printf '#!/usr/bin/env bash\necho fixture\n' > "$upstream/scripts/new-helper.sh"
chmod +x "$upstream/scripts/new-helper.sh"
git -C "$upstream" add scripts/new-helper.sh
git -C "$upstream" commit -q -m "fixture: executable helper"

git init -q -b main "$consumer"
git -C "$consumer" remote add fixture "$upstream"
git -C "$consumer" fetch -q fixture main

(
  cd "$consumer"
  # shellcheck disable=SC1090
  source <(sed '/^main "\$@"$/d' "$ROOT_DIR/cog-update.sh")
  REMOTE_NAME="fixture"
  BRANCH="main"

  update_file "scripts/new-helper.sh"

  if [[ ! -x scripts/new-helper.sh ]]; then
    echo "expected update_file to preserve the upstream executable bit" >&2
    exit 1
  fi
)

echo "cog-update preserves executable mode for new framework scripts"
