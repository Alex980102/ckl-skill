# CIP — Capture / Intent Protocol

CIP is CKL's verb-oriented protocol for evolving the knowledge graph. Every CIP verb is a first-class `ckl` subcommand and emits an event into the audit log.

## The seven verbs

| Verb | Purpose | Typical use |
|---|---|---|
| **capture** | Record a new atom of knowledge | `ckl capture --type pattern …` |
| **observe** | Signal that an atom was used / is still relevant | `ckl observe <id>` |
| **promote** | Move an atom to a higher Kronos layer | `ckl promote <id> --to high` |
| **resolve** | Reconcile duplicates or contradictions | `ckl resolve <id> --as duplicate-of <other>` |
| **archive** | Remove from active recall, keep history | `ckl archive <id>` |
| **deprecate** | Mark superseded by another atom | `ckl deprecate <id> --supersededBy <other>` |
| **do** | Execute an intent (todo/runbook) and record the trace | `ckl do <id>` |

## Lifecycle

```
              capture
                 │
                 ▼
            ┌─ Incoming ─┐
            │            │
        observe        capture --cycle
            │            │
            ▼            ▼
          Low ─► Medium ─► High ─► Nucleus
                     │
                  resolve / deprecate / archive
                     │
                     ▼
                  History (immutable)
```

Atoms never get hard-deleted from the active store — they move to `Archived` or `Deprecated` states and remain queryable with `--include-archived` / `--include-deprecated`.

## When to use which verb

### capture
- Anything new you want the engine to remember.
- Always include `--type`, `--title`, and meaningful `--tags`.
- Add `--rationale` for decisions.
- Add `--source <file:line>` when the knowledge has a code origin.

### observe
- Cheapest verb. Run it when you act on a pattern, follow a decision, or otherwise rely on an atom.
- Boosts Kronos confidence with a soft signal.

### promote
- Use sparingly. Most promotions should come from `--cycle` automatically.
- Manual promotion is useful when a human (or you, the agent) has high-bandwidth context the auto-cycle doesn't.

### resolve
- For **duplicates**: `ckl resolve <id> --as duplicate-of <other>` collapses both atoms; the kept one inherits tags and observations.
- For **contradictions**: `ckl resolve <id> --as contradicts <other>` records a tension; downstream queries surface both with a warning.
- Always run after `ckl audit duplicates` / `ckl audit contradictions`.

### archive
- Atom is no longer relevant but historically interesting.
- Removes it from default recall.

### deprecate
- Atom has been replaced. Always pair with `--supersededBy <new-id>`.
- Queries that match the old atom auto-redirect to the new one.

### do
- Executes a runbook, recipe, or todo with provenance.
- The execution trace becomes a child atom linked to the parent.
- Useful for "do this todo and record what happened" workflows.

```bash
ckl do <todo-id> --note "ran lint, fixed 3 warnings"
```

## CIP and the audit log

Every verb writes an event:

```bash
ckl audit log --since 24h --limit 50
```

This is the source of truth for "who/what changed in this knowledge base and when". It powers:

- Incremental sync to remote graphs.
- Replay for forensics.
- Reverting individual operations with `ckl audit revert <event-id>`.

## Best practices

- **One verb per intent.** Don't conflate `observe` with `promote`.
- **Always tag.** Untagged atoms are second-class citizens in retrieval.
- **Resolve, don't delete.** Hard-deletion is reserved for accidental captures via `ckl archive --hard <id>` (rare).
- **Run `--cycle` end of session.** Lets Kronos consume your CIP events and update the graph.
- **Never fabricate IDs.** Always use IDs returned by capture or by `ckl query`.

## Programmatic CIP

`ckl apply` accepts a JSON batch of CIP operations:

```json
[
  {"op": "capture", "type": "pattern", "title": "...", "content": "...", "tags": ["..."]},
  {"op": "observe", "id": "blk_abc123"},
  {"op": "resolve", "id": "blk_def456", "as": "duplicate-of", "target": "blk_ghi789"}
]
```

Use this for scripted workflows (CI hooks, post-merge captures, agent batch operations). See `ckl apply --help` for full schema.
