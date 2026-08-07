#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

registry="04-projects/harness/ultragoals.md"
if [[ ! -f "$registry" ]]; then
  fail "ultragoal registry is missing: $registry"
fi

for skill in .claude/skills/ultragoal/SKILL.md skills/ultragoal/SKILL.md; do
  if ! grep -Fq "$registry" "$skill"; then
    fail "$skill no longer points to the ultragoal registry"
  fi
done

installer=".claude/lib/install-harness.sh"
if grep -Fq "$installer" WORKFLOW.md && [[ ! -f "$installer" ]]; then
  fail "WORKFLOW.md documents missing installer: $installer"
fi

backlog="04-projects/harness/BACKLOG.md"
if grep -Fq "$backlog" WORKFLOW.md && [[ ! -f "$backlog" ]]; then
  fail "WORKFLOW.md documents missing harness backlog: $backlog"
fi

if [[ $failures -gt 0 ]]; then
  echo "$failures harness bootstrap contract regression(s) reproduced" >&2
  exit 1
fi

echo "harness bootstrap registry and documented static paths are consistent"
