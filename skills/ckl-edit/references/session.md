# `ckl session` — group ops into one knowledge block

Sessions group multiple mutating operations (`edit`, `write`, `apply`, `mv`, etc.) into a single `process`-typed knowledge block with `PART_OF` edges to the underlying ops. A multi-step refactor becomes one auditable unit.

## Table of contents

- [Lifecycle](#lifecycle)
- [Commands](#commands)
- [Storage](#storage)
- [Examples](#examples)

## Lifecycle

```
start → (active: ops with --session <id>) → commit | abort
```

After `commit`, the session is archived as a `process` knowledge block; the underlying ops become children via `PART_OF` edges.

## Commands

| Command | Purpose |
|---|---|
| `ckl session start --pretty` | Create new session, return `<session_id>` |
| `ckl session status [--id <id>] --pretty` | Inspect active or specific session |
| `ckl session list --pretty` | List active and recent sessions |
| `ckl session commit [--id <id>] --pretty` | Finalize: emit `process` block + `PART_OF` edges |
| `ckl session abort [--id <id>] --pretty` | Discard the session and its ops |

Every mutating command (`edit`, `write`, `apply`, `mv`, `mkdir`, `rm`, `delete`) accepts `--session <id>` to attach to an active session.

## Storage

Active sessions live as JSON in `~/.ckl/sessions/<session_id>.json`. Once committed, the file is moved to a committed/ subfolder for traceability; the canonical record is the `process` block in the graph.

## Examples

### Group a 3-file refactor

```bash
SID=$(ckl session start --pretty | jq -r .id)

ckl edit src/a.rs --old "foo" --new "bar" --session "$SID" --reason "rename" --entity entity_ckl
ckl edit src/b.rs --old "foo" --new "bar" --session "$SID" --reason "rename"
ckl write src/c.rs --content "..." --session "$SID" --reason "new module"

ckl session commit --id "$SID" --pretty
```

The committed session becomes one `process` block (e.g. "Refactor: rename foo to bar across modules") that links to each individual edit/write block via `PART_OF`.

### Inspect before commit

```bash
ckl session status --id "$SID" --pretty       # see ops accumulated so far
```

### Abort if something went wrong

```bash
ckl session abort --id "$SID" --pretty        # discard
```

Aborting does NOT undo file changes — those are written immediately by each op. Aborting only discards the session metadata so no `process` block is created. To revert files use git or `ckl apply` with rollback.

## When to use sessions

| Situation | Use a session? |
|---|---|
| Single edit | No — `ckl edit --reason` is enough |
| Atomic multi-file change | Use `ckl apply` (better — true rollback) |
| Multi-step refactor across many calls | **Yes** — group with `session` |
| Interactive exploration that may produce captures | **Yes** — commit at the end as one process |
