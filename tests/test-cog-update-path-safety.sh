#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

make_upstream() {
  local path="$1"
  git init -q -b main "$path"
  git -C "$path" config user.name "COG Test"
  git -C "$path" config user.email "cog-test@example.invalid"
  printf '9.9.9\n' > "$path/COG-VERSION"
  printf 'upstream readme\n' > "$path/README.md"
  git -C "$path" add COG-VERSION README.md
  git -C "$path" commit -q -m "fixture: upstream"
}

make_consumer() {
  local path="$1"
  local upstream="$2"
  git init -q -b main "$path"
  git -C "$path" config user.name "COG Test"
  git -C "$path" config user.email "cog-test@example.invalid"
  cp "$ROOT_DIR/cog-update.sh" "$path/cog-update.sh"
  printf '1.0.0\n' > "$path/COG-VERSION"
  printf 'local readme\n' > "$path/README.md"
  git -C "$path" add cog-update.sh COG-VERSION README.md
  git -C "$path" commit -q -m "fixture: consumer"
  git -C "$path" remote add cog-upstream "$upstream"
}

# Regression 1: a framework path must never follow a symlink outside the checkout.
symlink_upstream="$TMP_DIR/symlink-upstream"
symlink_consumer="$TMP_DIR/symlink-consumer"
outside_target="$TMP_DIR/private-user-file.txt"
make_upstream "$symlink_upstream"
make_consumer "$symlink_consumer" "$symlink_upstream"
printf 'private user content\n' > "$outside_target"
rm "$symlink_consumer/README.md"
ln -s "$outside_target" "$symlink_consumer/README.md"

git -C "$symlink_consumer" add README.md
git -C "$symlink_consumer" commit -q -m "fixture: symlinked framework path"

set +e
symlink_output="$(cd "$symlink_consumer" && bash cog-update.sh --force 2>&1)"
symlink_status=$?
set -e

if [[ "$(cat "$outside_target")" != "private user content" ]]; then
  fail "updater followed README.md symlink and modified content outside the checkout (status=$symlink_status): $symlink_output"
fi

# Regression 2: running from a nested directory must still operate on the Git root.
root_upstream="$TMP_DIR/root-upstream"
root_consumer="$TMP_DIR/root-consumer"
make_upstream "$root_upstream"
make_consumer "$root_consumer" "$root_upstream"
mkdir -p "$root_consumer/nested/work"

set +e
root_output="$(cd "$root_consumer/nested/work" && bash ../../cog-update.sh --force 2>&1)"
root_status=$?
set -e

if [[ $root_status -ne 0 ]]; then
  fail "updater failed when invoked from a nested directory (status=$root_status): $root_output"
else
  if [[ "$(cat "$root_consumer/README.md")" != "upstream readme" ]]; then
    fail "nested invocation did not update root README.md"
  fi
  if [[ "$(tr -d '[:space:]' < "$root_consumer/COG-VERSION")" != "9.9.9" ]]; then
    fail "nested invocation did not update root COG-VERSION"
  fi
  if [[ -e "$root_consumer/nested/work/README.md" || -e "$root_consumer/nested/work/COG-VERSION" ]]; then
    fail "nested invocation created framework files below the current subdirectory"
  fi
fi

if [[ $failures -gt 0 ]]; then
  echo "$failures updater path-safety regression(s) reproduced" >&2
  exit 1
fi

echo "cog-update anchors writes at the repository root and does not follow framework symlinks"
