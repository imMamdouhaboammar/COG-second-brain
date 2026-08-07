#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

failures=0
future_file="FUTURE-FRAMEWORK.md"

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

make_upstream() {
  local path="$1"
  git init -q -b main "$path"
  git -C "$path" config user.name "COG Test"
  git -C "$path" config user.email "cog-test@example.invalid"
  cp "$ROOT_DIR/cog-update.sh" "$path/cog-update.sh"
  python3 - "$path/cog-update.sh" "$future_file" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
future = sys.argv[2]
text = path.read_text(encoding="utf-8")
marker = '  "COG-VERSION"\n'
addition = f'  "{future}"\n'
if text.count(marker) != 1:
    raise SystemExit("fixture could not find unique FRAMEWORK_FILES marker")
path.write_text(text.replace(marker, marker + addition, 1), encoding="utf-8")
PY
  chmod +x "$path/cog-update.sh"
  printf '9.9.9\n' > "$path/COG-VERSION"
  printf 'future framework asset\n' > "$path/$future_file"
  git -C "$path" add cog-update.sh COG-VERSION "$future_file"
  git -C "$path" commit -q -m "fixture: upstream adds a newly tracked framework file"
}

make_consumer() {
  local path="$1"
  local upstream="$2"
  git init -q -b main "$path"
  git -C "$path" config user.name "COG Test"
  git -C "$path" config user.email "cog-test@example.invalid"
  cp "$ROOT_DIR/cog-update.sh" "$path/cog-update.sh"
  printf '1.0.0\n' > "$path/COG-VERSION"
  git -C "$path" add cog-update.sh COG-VERSION
  git -C "$path" commit -q -m "fixture: consumer before preview refresh"
  git -C "$path" remote add cog-upstream "$upstream"
}

upstream="$TMP_DIR/upstream"
make_upstream "$upstream"

for mode in --check --dry-run; do
  consumer="$TMP_DIR/consumer-${mode#--}"
  make_consumer "$consumer" "$upstream"

  set +e
  output="$(cd "$consumer" && COG_UPSTREAM_URL="$upstream" bash cog-update.sh "$mode" 2>&1)"
  status=$?
  set -e

  if [[ $status -ne 0 ]]; then
    fail "$mode failed while previewing an upstream updater change (status=$status): $output"
  fi
  if [[ "$output" != *"$future_file"* ]]; then
    fail "$mode omitted a framework file tracked only by the upstream updater: $output"
  fi
  if [[ -e "$consumer/$future_file" ]]; then
    fail "$mode mutated the working tree while discovering the upstream framework list"
  fi
done

if [[ $failures -gt 0 ]]; then
  echo "$failures updater preview-refresh regression(s) reproduced" >&2
  exit 1
fi

echo "cog-update previews the upstream framework file list without installing it"
