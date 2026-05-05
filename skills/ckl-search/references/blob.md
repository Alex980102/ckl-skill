# `ckl blob` — direct CAS access (v0.5.3)

`ckl blob` reads block content directly from ckl's content-addressed store. The store is **gix-backed** (the same Rust git plumbing library), so OIDs are git-style 40-char SHA-1 hashes.

## Table of contents

- [Storage layout](#storage-layout)
- [Subcommand vs OID positional](#subcommand-vs-oid-positional)
- [Modes — default / `--raw` / `--info` / `--refs`](#modes--default---raw---info---refs)
- [`ckl blob list`](#ckl-blob-list)
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

| Flag | Output | Locks DB? |
|---|---|---|
| (none) | `{oid, size_bytes, content, encoding, refs_count, exists}`; `encoding` is `utf8` or `base64` | Yes (refs lookup) |
| `--raw` | Raw bytes piped to stdout. **Skips refs lookup.** Binary-safe. | **No — fully lock-free** |
| `--info` | `{oid, size_bytes, encoding, exists}` (no content, no refs) | Yes |
| `--refs` | `{oid, refs: [{block_id, project_id, name, ...}]}` | Yes |
| `--pretty` | Pretty JSON. Ignored with `--raw`. | — |

**Defaults you should know:**

- The default JSON envelope encodes `content` as `utf8` when valid UTF-8, otherwise `base64`. Inspect `encoding` before parsing.
- `exists: false` means the OID is unknown to the loose store. It may have been packed and not yet unpacked, or GC'd.
- `refs_count` is the number of blocks whose `blob_oid` equals the OID. Often 1; can be >1 after dedup.

## `ckl blob list`

```bash
ckl blob list --pretty
```

Enumerates **loose objects only** — OIDs that live in `objects/<2-hex>/<rest>` directly. Packed objects (`objects/pack/*.pack`) are not iterated by this command.

To inspect packed objects, run `ckl migrate` / `ckl migrate-finalize` workflow first or use a gix-aware tool.

## Daemon-lock trade-off

v0.5.3 has a subtle caveat: **only `ckl blob OID --raw` is fully lock-free.**

- Default / `--info` / `--refs` modes touch SurrealKV to do the refs lookup (or to verify the OID exists in the metadata table). They will block briefly when the daemon holds the lock.
- `--raw` reads the gix object store directly via the gix crate — no SurrealKV access, no daemon contention.

Implication for scripts:

| Pattern | Recommendation |
|---|---|
| One-off blob inspection | Default JSON envelope (with refs) — convenience wins |
| Long-running pipeline reading N blobs | `--raw` — avoid contending with the daemon |
| Verifying CAS integrity | `--raw \| sha1sum` and compare to OID |

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
