# Evidence Ledger

Use one row per observed acceptance-criterion result. Evidence should describe what was actually observed and point to the artifact, command, URL, or file that supports the result.

| Acceptance criterion | Checkpoint | Result | Observation | Artifact |
|---|---|---|---|---|

## Evidence row contract

```text
EVIDENCE <AC-id> | <checkpoint> | PASS|FAIL|SKIP | <observation> | <artifact-path-or-command>
```

A criterion is ready to ship only when it has at least one relevant evidence row. Keep raw checkpoint events in `checkpoints.tsv`; use this ledger for criterion-traced verification evidence.
