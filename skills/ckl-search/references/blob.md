# `ckl blob` — direct CAS access (v0.5.3)

`ckl blob` reads block content directly from ckl's content-addressed store. The store is **gix-backed** (the same Rust git plumbing library), so OIDs are git-style 40-char SHA-1 hashes.

## Table of contents

- [Storage layout](#storage-layout)
- [Subcommand vs OID positional](#subcommand-vs-oid-positional)
- [Modes — default / `--raw` / `--info` / `--refs`](#modes--default---raw---info---refs)
- [`ckl blob list`](#ckl-blob-list)
- [`ckl blob reindex` (v0.5.4)](#ckl-blob-reindex-v054)
- [Daemon-lock trade-off](#daemon-lock-trade-off)
- [Examples](#examples)

## Storage layout

```text
~/.ckl/blobs/                     # gix-backed CAS root
├── objects/
│   ├── 4f/3a8b...                # loose objects (subdir = first 2 hex chars)
│   ├── 5d/9c1f...
│   └── pack/
│       ├── pack-<sha>.idx        # packed objects (after `git gc` analogue)
│       └── pack-<sha>.pack
└── info/
```

This is **not** SurrealKV — it's a separate store for binary-safe content. SurrealKV holds the metadata (block→blob_oid mapping); the gix store holds the actual bytes.

`ckl migrate-finalize` runs the gix-equivalent of `git gc`: packs loose objects and prunes unreferenced ones.

## Subcommand vs OID positional

```bash
ckl blob <OID>                    # read by OID (positional, required when no subcommand)
ckl blob list                     # subcommand — enumerate
ckl blob help                     # show help
```

If you pass an OID positional argument, the modes below apply. If you pass `list`, you get enumeration.

## Modes — default / `--raw` / `--info` / `--refs`

```bash
ckl blob 4f3a8b...                       # JSON envelope (default)
ckl blob 4f3a8b... --raw                  # raw bytes to stdout (binary-safe)
ckl blob 4f3a8b... --info --pretty        # metadata only, no content
ckl blob 4f3a8b... --refs --pretty        # reverse lookup
```

| Flag | Output | Locks DB? | Complexity |
|---|---|---|---|
| (none) | `{oid, size_bytes, content, encoding, refs_count, exists}`; `encoding` is `utf8` or `base64` | Yes (brief — reverse-index lookup, post-v0.5.4) | O(log N + k) |
| `--raw` | Raw bytes piped to stdout. **Skips refs lookup.** Binary-safe. | **No — fully lock-free** | O(1) |
| `--info` | `{oid, size_bytes, encoding, exists}` (no content, no refs) | Yes (brief) | O(log N) |
| `--refs` | `{oid, refs: [{block_id, project_id, name, ...}]}` | Yes (brief — reverse-index, post-v0.5.4) | O(log N + k) |
| `--pretty` | Pretty JSON. Ignored with `--raw`. | — | — |

**Defaults you should know:**

- The default JSON envelope encodes `content` as `utf8` when valid UTF-8, otherwise `base64`. Inspect `encoding` before parsing.
- `exists: false` means the OID is unknown to the loose store. It may have been packed and not yet unpacked, or GC'd.
- `refs_count` is the number of blocks whose `blob_oid` equals the OID. Often 1; can be >1 after dedup.

## `ckl blob list`

```bash
ckl blob list --pretty
ckl blob list --limit 100 --offset 0 --pretty       # paginated (sorted-hex order, stable)
```

Enumerates **loose objects only** — OIDs that live in `objects/<2-hex>/<rest>` directly. Packed objects (`objects/pack/*.pack`) are not iterated by this command. **Pack-aware enumeration is a v0.5.4 follow-up** (still pending in v0.5.5 — track upstream for completion).

Each item in the list now carries its `refs_count` (post-v0.5.4 reverse-index makes the per-item lookup O(log N + k)).

To inspect packed objects, run `ckl migrate` / `ckl migrate-finalize` workflow first or use a gix-aware tool.

## `ckl blob reindex` (v0.5.4)

Rebuilds the `blocks_by_blob_oid` reverse index from `blocks::`. Idempotent (set semantics).

```bash
ckl blob reindex --pretty
```

- **Run once after upgrading from v0.5.3.** Pre-v0.5.4 writes did not emit the reverse index; until you back-fill, `ckl blob <oid> --refs` returns empty for those blocks.
- New writes (capture/edit/write) emit the index inline regardless — you don't need to re-run after each session.
- Safe to re-run if you suspect drift.

## Daemon-lock trade-off

**Pre-v0.5.4** every non-`--raw` mode scanned all blocks for the refs lookup. **v0.5.4** introduced the `blocks_by_blob_oid` reverse index, dropping all SurrealKV-touching modes to O(log N + k). The lock is still held briefly, but contention is now negligible.

- `--raw` reads the gix object store directly via the gix crate — no SurrealKV access, no daemon contention. **Fully lock-free.**
- Default / `--info` / `--refs` touch SurrealKV via the reverse index. They will block briefly when the daemon holds the write lock, but the index lookup is fast (O(log N + k) instead of O(N)).

> **One-shot back-fill on upgrade from v0.5.3.** Pre-v0.5.4 `put_block` did not emit the reverse index, so blocks written before the upgrade are invisible to `--refs` until you run `ckl blob reindex --pretty` once. Idempotent (set semantics).

Implication for scripts:

| Pattern | Recommendation |
|---|---|
| One-off blob inspection | Default JSON envelope (with refs) — convenience wins, now cheap |
| Long-running pipeline reading N blobs | `--raw` — still the cheapest path (zero SurrealKV access) |
| Verifying CAS integrity | `--raw \| sha1sum` and compare to OID |
| Back-fill after upgrading from v0.5.3 | `ckl blob reindex --pretty` (idempotent, one-shot) |

## Examples

```bash
# Inspect an OID surfaced by `ckl audit`
ckl blob 4f3a8b... --pretty

# Verify the OID matches the content (round-trip integrity check)
ckl blob 4f3a8b... --raw | shasum -a 1
# → should print the same OID

# What blocks reference this content?
ckl blob 4f3a8b... --refs --pretty

# Recover content to a file
ckl blob 4f3a8b... --raw > /tmp/recovered.bin
file /tmp/recovered.bin

# List all loose objects (e.g. before GC)
ckl blob list --pretty

# Pipeline: stream content into a downstream tool
ckl blob 4f3a8b... --raw | jq .       # if you know it's JSON
```

## When NOT to use `ckl blob`

- You want the *block*, not the *content*: use `ckl block <blk_id> --pretty` — it returns the metadata + content + relationships in one call.
- You want to *search* for content: use `ckl query <text>` — `ckl blob` is purely OID-keyed, not searchable.
- You want to inspect *all* atoms in the store: use `ckl list atoms` (v0.5.1).

## See also

- [navigate.md](navigate.md) — `ckl block` for full block (metadata + content together)
- [../../ckl-system/references/migrations.md](../../ckl-system/references/migrations.md) — Wave-6 CAS migration / `ckl migrate-finalize`
- [../../ckl-knowledge/references/atom.md](../../ckl-knowledge/references/atom.md) — atoms reference content via `blob_oid`
