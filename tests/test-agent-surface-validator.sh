#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fixture="$TMP_DIR/repo"
mkdir -p "$fixture"
git -C "$ROOT_DIR" archive HEAD | tar -xf - -C "$fixture"

rm "$fixture/.agents/skills/onboarding/SKILL.md"

set +e
output="$(cd "$fixture" && ./scripts/validate-agent-surface.sh 2>&1)"
status=$?
set -e

if [[ $status -eq 0 ]]; then
  echo "expected validator to reject a missing Antigravity skill stub" >&2
  echo "$output" >&2
  exit 1
fi

if ! grep -Fq "Antigravity is missing skill stubs: onboarding" <<< "$output"; then
  echo "validator failed, but not with the expected Antigravity parity diagnostic" >&2
  echo "$output" >&2
  exit 1
fi

echo "validator rejects a missing Antigravity skill stub"
