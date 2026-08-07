#!/usr/bin/env python3
"""Regression tests for the safe harness HTML report renderer."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts/render-harness-report.py"
TEMPLATE = ROOT / "04-projects/harness/templates/report.html"
ONE_PIXEL_PNG = (
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6eQAAAABJRU5ErkJggg=="
)


def run_renderer(data: dict, directory: Path) -> subprocess.CompletedProcess[str]:
    data_path = directory / "report-data.json"
    output_path = directory / "report.html"
    data_path.write_text(json.dumps(data), encoding="utf-8")
    return subprocess.run(
        [
            sys.executable,
            str(RENDERER),
            "--template",
            str(TEMPLATE),
            "--data",
            str(data_path),
            "--output",
            str(output_path),
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def base_data() -> dict:
    injection = '</p><script>alert("x")</script><p>'
    return {
        "goal": injection,
        "north_star": "Ship <safe> evidence",
        "overall_status": 'done" onclick="alert(1)',
        "current_phase": "P1",
        "updated_at": "2026-08-07T08:00:00Z",
        "phases": [
            {
                "id": "P1",
                "goal": injection,
                "ac": "AC-1",
                "state": 'done" onclick="alert(2)',
                "evidence": "evidence/P1/",
            }
        ],
        "criteria": [
            {
                "id": "AC-1",
                "text": injection,
                "owner": "P1",
                "evidence": "CP-5",
                "status": "PASS",
            }
        ],
        "evidence": [
            {
                "ac": "AC-1",
                "checkpoint": "CP-5",
                "result": "PASS",
                "observation": injection,
                "artifact": 'artifact" onerror="alert(3)',
                "media": [
                    {
                        "data_uri": f"data:image/png;base64,{ONE_PIXEL_PNG}",
                        "alt": injection,
                        "caption": injection,
                    }
                ],
            }
        ],
        "open_items": [injection],
        "next_action": injection,
    }


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        directory = Path(tmp)
        result = run_renderer(base_data(), directory)
        if result.returncode != 0:
            raise AssertionError(result.stderr or result.stdout)

        rendered = (directory / "report.html").read_text(encoding="utf-8")
        if '<script>alert("x")</script>' in rendered:
            raise AssertionError("raw script markup reached the rendered report")
        if '&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;' not in rendered:
            raise AssertionError("untrusted report text was not HTML-escaped")
        if 'onclick="alert(' in rendered or 'onerror="alert(' in rendered:
            raise AssertionError("untrusted event-handler markup reached the report")
        if f"data:image/png;base64,{ONE_PIXEL_PNG}" not in rendered:
            raise AssertionError("validated data-image media was not rendered")

        unsafe = base_data()
        unsafe["evidence"][0]["media"] = [
            {
                "data_uri": "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==",
                "alt": "unsafe",
            }
        ]
        unsafe_result = run_renderer(unsafe, directory)
        if unsafe_result.returncode == 0:
            raise AssertionError("renderer accepted a non-image data URI")

    print("harness report renderer escapes text and rejects unsafe media")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
