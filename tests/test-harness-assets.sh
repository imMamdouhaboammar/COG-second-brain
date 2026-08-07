#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

required=(
  "04-projects/harness/templates/evidence-ledger.md"
  "04-projects/harness/templates/SPEC-template.md"
  "04-projects/harness/templates/report.html"
)

for path in "${required[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "missing harness asset: $path" >&2
    exit 1
  fi
done

if ! grep -Fq '04-projects/harness/templates/SPEC-template.md' .claude/skills/closed-loop/SKILL.md; then
  echo "closed-loop no longer points to the shipped spec template" >&2
  exit 1
fi

if ! grep -Fq '04-projects/harness/templates/report.html' .claude/skills/closed-loop/SKILL.md; then
  echo "closed-loop no longer points to the shipped report template" >&2
  exit 1
fi

if ! grep -Fq '04-projects/harness/templates/SPEC-template.md' .claude/skills/ultragoal/SKILL.md; then
  echo "ultragoal no longer points to the shipped spec template" >&2
  exit 1
fi

if ! grep -Fq '04-projects/harness/templates/report.html' .claude/skills/ultragoal/SKILL.md; then
  echo "ultragoal no longer points to the shipped report template" >&2
  exit 1
fi

echo "closed-loop harness assets are present at the paths used by the shipped skills"
