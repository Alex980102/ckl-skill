# Agent-first file operations — full reference

All commands return JSON by default. Pass `--pretty` for humans, `--dry-run` to preview without disk/graph writes.

## Table of contents

- [`edit`](#edit) — exact string replacement
- [`write`](#write) — atomic file + knowledge
- [`apply`](#apply) — JSON batch with rollback
- [`mv`](#mv) — rename + graph update
- [`mkdir`](#mkdir) — create directory
- [`rm`](#rm) — tombstone-aware delete
- [Error model](#error-model)

## `edit`

```bash
ckl edit <path> --old "x" --new "y" --reason "..."
ckl edit f.txt --old foo --new bar --replace-all --dry-run
```

| Flag | Required | Effect |
|---|---|---|
| `--old <str>` | yes | Exact text to replace; must be unique unless `--replace-all` |
| `--new <str>` | yes | Replacement text |
| `--reason <str>` | yes (unless `--dry-run`) | Audit trail for the change |
| `--replace-all` | no | Replace every occurrence |
| `--type <T>` | no (default `decision`) | Knowledge type: `decision`, `fact`, `process`, `pattern` |
| `--entity <id>` | no | Emit `Edit` nutrient on touched indexed blocks |
| `--session <id>` | no | Attach to active session |
| `--dry-run` | no | Preview without disk/graph writes |

Returns updated file metadata + the knowledge block that documents the change.

## `write`

```bash
ckl write <path> --content "..." --reason "..." --entity <id>
echo "content" | ckl write <path> --reason "..."
```

Atomic create-or-overwrite + knowledge entry + Edit nutrient.

| Flag | Required | Effect |
|---|---|---|
| `--content <str>` | yes (or stdin) | File content |
| `--reason <str>` | yes | Documents the creation |
| `--type <T>` | no (default `decision`) | Knowledge type |
| `--entity <id>` | no | Emit `Edit` nutrient per indexed block |
| `--dry-run` | no | Preview |

## `apply`

JSON on stdin. Two-pass: validate-all, then apply-all. Rollback on any failure.

```bash
cat <<EOF | ckl apply --pretty
{
  "reason": "refactor X across 3 files",
  "entity": "entity_ckl",
  "operations": [
    { "op": "edit",  "path": "a.rs", "old": "foo", "new": "bar" },
    { "op": "write", "path": "b.rs", "content": "..." },
    { "op": "mv",    "src":  "old.rs", "dst": "new.rs" },
    { "op": "mkdir", "path": "src/new" },
    { "op": "rm",    "path": "src/legacy.rs" }
  ]
}
EOF
```

One knowledge block documents the entire batch (with `PART_OF` edges to per-op entries).

### Exit codes

| Code | Meaning |
|---|---|
| 0 | OK — all ops succeeded |
| 1 | User error (malformed JSON, missing field) |
| 2 | Conflict at pass 1 (validation failed; nothing written) |
| 3 | Rollback OK — pass 2 failed, all changes reverted |
| 4 | Rollback FAILED — disk/graph may be inconsistent (CRITICAL) |

## `mv`

```bash
ckl mv <src> <dst>                 # rename + update graph
ckl mv old.rs new.rs --pretty
```

Updates every block that referenced the old path. Indexer sees the new path on next query.

## `mkdir`

```bash
ckl mkdir src/new_dir              # plain dir create
ckl mkdir src/a/b/c                # creates intermediate dirs
```

Agent-first analogue of `mkdir -p`. Idempotent.

## `rm`

```bash
ckl rm src/legacy.rs               # tombstone-aware delete
```

Tombstones the corresponding indexed blocks so subsequent `ckl query` doesn't surface stale references. Followed by `ckl index <path>` if other files moved as a result.

## Error model

All mutating commands return `{error, code, hint}` on failure:

```json
{
  "error": "old string not unique",
  "code": "CONFLICT",
  "hint": "Use --replace-all or provide larger context in --old"
}
```

| Code | Meaning |
|---|---|
| 1 | User error (input validation) |
| 2 | Conflict (uniqueness, race, lock) |
| 3 | Invalid state (file missing, graph inconsistency) |
| 4 | Critical (rollback failed in `apply`) |

Pair with `--dry-run` during development to see errors without side effects.
