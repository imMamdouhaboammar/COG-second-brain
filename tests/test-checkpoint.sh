#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

run_dir="$TMP_DIR/run"
output="$(bash "$ROOT_DIR/.claude/lib/checkpoint.sh" init "$run_dir" 2>&1)"

if [[ ! -f "$run_dir/evidence/ledger.md" ]]; then
  echo "checkpoint init did not create evidence/ledger.md" >&2
  echo "$output" >&2
  exit 1
fi

if ! grep -Fq "initialized: $run_dir/evidence/" <<< "$output"; then
  echo "checkpoint init did not report the initialized evidence directory" >&2
  echo "$output" >&2
  exit 1
fi

echo "checkpoint init creates the evidence ledger"
