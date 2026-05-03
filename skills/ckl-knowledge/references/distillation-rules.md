# Distillation rules — full guide

The single most important discipline when capturing: **distill, don't transcribe**. The graph's value comes from precision, not volume.

## Table of contents

- [The core rule](#the-core-rule)
- [What to compile](#what-to-compile)
- [What NOT to compile](#what-not-to-compile)
- [Title patterns](#title-patterns)
- [Content rules](#content-rules)
- [Search-first pattern](#search-first-pattern)
- [Anti-patterns](#anti-patterns)

## The core rule

> Most responses compile **nothing**. Be ruthless. Precision > recall.

A typical session captures 0–3 atoms. A noisy session captures 10. The latter degrades search quality for everyone. If in doubt, don't.

## What to compile

| Type | When | Example |
|---|---|---|
| `decision` | A choice was made with rationale | "Chose SurrealKV over RocksDB for embeddable MVCC" |
| `pattern` | Recurring approach worth reusing | "Validate-before-persist in auto-relate avoids dangling edges" |
| `gotcha` | Surprising failure mode | "Daemon holds DB lock during MCP proxy — stop before reembed" |
| `lesson` | Postmortem insight | "First-arrival warning post-upgrade should not touch keychain" |
| `rule` | Constraint or heuristic | "Quality gates: unresolved ≤ 0.15, coherence ≥ 0.8" |
| `process` | Multi-step procedure | "Release-train: phases ζ.G → ζ.H → tag at end" |
| `concept` | New abstraction | "Two CKL working modes split along code-as-graph and knowledge-as-graph" |
| `fact` | Architecture / system fact | "Vector index lives in ~/.ckl/data/vectors/<project>.usearch" |

## What NOT to compile

- ❌ Trivial edits: "Renamed variable", "Fixed typo".
- ❌ Raw tool-call output ("file contents", "log lines").
- ❌ "Done", "Fixed", "Tests pass" confirmations.
- ❌ Session debug narrative: "User asked X, I tried Y, then Z".
- ❌ Diff descriptions: "Removed 3 lines from line 45".
- ❌ Open questions without answers — they bloat the graph and leave no signal.
- ❌ Anything you'd find in a CHANGELOG entry that isn't actionable later.

## Title patterns

Searchable titles include tech / component names AND the insight in one sentence.

| Quality | Title |
|---|---|
| GOOD | "Drizzle ORM requires WAL mode for concurrent reads" |
| GOOD | "SurrealKV MVCC prevents write conflicts in concurrent indexing" |
| GOOD | "Two CKL working modes split along code-as-graph and knowledge-as-graph hot paths" |
| BAD | "Database finding" |
| BAD | "Config bug fix" |
| BAD | "Notes about session" |

The title is what `ckl search "<terms>"` will match. If your title doesn't contain the terms a future agent would search, the atom is invisible.

## Content rules

- **Plain paragraphs only.** Never use `##` sub-headings inside `--content`. Sub-headings create child blocks with generic names ("Why it matters", "Background") that fragment the insight and pollute search.
- **One atom = one atomic idea.** If you have 3 ideas, capture 3 atoms.
- **Stand-alone.** Content should make sense without reading the original conversation. Include enough context (component names, version, why it matters).
- **Always scope:** `--project` and `--entity` on every call. Otherwise the atom is orphaned.
- **Token budget:** aim for 50–300 tokens per atom. Longer than that → split.

## Search-first pattern

Before every capture:

```bash
ckl search "<3-5 key terms from your title>" --format compact --pretty
```

If a near-duplicate exists, **skip**. Or use `ckl promote --block <existing>` to boost it. Or use `ckl resolve --block <existing> --supersede` if you have new info that supersedes the old.

CIP `ckl capture` runs auto-dedup based on title overlap (~60% word overlap), but it's coarse. Manual `ckl search` first is more reliable.

## Anti-patterns

### The "session log" anti-pattern
Capturing every conversation step. Result: graph fills with `process` blocks that no one will ever search. Solution: capture the **distilled insight** at the end, not the journey.

### The "subheading" anti-pattern
```bash
# BAD
ckl capture --content "## Background\n...\n## Decision\n...\n## Why\n..."
```
Each `##` creates a child block. Fragmented. Solution: write a single paragraph.

### The "vague title" anti-pattern
```bash
# BAD
ckl capture --title "Important learning about the system"
```
Won't match any future search. Solution: name the components.

### The "orphan" anti-pattern
```bash
# BAD — no --project, no --entity
ckl capture --title "..." --content "..." --type decision
```
The atom isn't connected to anything. Solution: always pass `--project` and `--entity`.

### The "duplicate" anti-pattern
Capturing the same insight repeatedly because each session feels novel. Solution: search first. Promote existing atoms instead of creating new ones.
