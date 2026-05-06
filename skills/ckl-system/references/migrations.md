# Migrations and re-embed — full reference

Heavy operations that mutate the underlying storage. Always **stop the daemon first** for large jobs.

## Table of contents

- [`ckl migrate-vectors`](#ckl-migrate-vectors)
- [`ckl reembed`](#ckl-reembed)
- [v0.5.0 — `StoragePort` trait amendment (L1b)](#v050--storageport-trait-amendment-l1b)
- [v0.5.4 — `blocks_by_blob_oid` reverse index back-fill](#v054--blocks_by_blob_oid-reverse-index-back-fill)
- [v0.5.5 — Lens crates (no migration)](#v055--lens-crates-no-migration)
- [`ckl migrate` / `ckl migrate-finalize`](#ckl-migrate--ckl-migrate-finalize)
- [Thresholds](#thresholds)

## `ckl migrate-vectors`

Migrates the vector index to the per-project shard layout (introduced in v0.3.0).

```bash
ckl migrate-vectors --confirm                    # standard migration
ckl migrate-vectors --force-rebuild              # rebuild from scratch
ckl migrate-vectors --confirm --pretty
```

After migration, `~/.ckl/data/vectors/` contains:
- `<project>.usearch` — one shard per project
- `_orphan.usearch` — blocks not associated with any project
- `legacy-bak/` — pre-migration index preserved for rollback

### When to run

- After upgrading from < v0.3.0.
- When `ckl status --pretty` reports a "vector layout out of date" warning.
- After bulk-importing a large graph (`ckl import`).

### Rollback

If migration produces unexpected results:
1. `ckl daemon stop`
2. Move the failed shards aside: `mv ~/.ckl/data/vectors ~/.ckl/data/vectors.failed`
3. Restore from `legacy-bak/`: `mv ~/.ckl/data/vectors.legacy-bak ~/.ckl/data/vectors`
4. `ckl daemon start`

## `ckl reembed`

Re-computes embeddings for existing blocks without mutating source files. Useful after:

- Switching `embeddings.provider` or `embeddings.model`.
- Switching `embeddings.dimensions` (forces full rebuild).
- Detecting drift in semantic search quality.

```bash
ckl daemon stop                                              # required for large jobs
ckl reembed --project prj_xxx --pretty
ckl reembed --all --pretty                                   # all projects
ckl reembed --project prj_xxx --batch-size 100 --pretty
ckl daemon start
```

### Flags

| Flag | Effect |
|---|---|
| `--project <prj_id>` | Limit to one project |
| `--all` | Re-embed every project |
| `--batch-size N` | Embeddings per API call (default provider-specific) |
| `--dry-run` | Count what would be re-embedded without calling the API |
| `--confirm` | Required for ≥ 5k vectors |

### Cost note

Each block re-embedded counts against your embeddings provider's quota. Use `--dry-run` first to see scope.

## v0.5.0 — `StoragePort` trait amendment (L1b)

v0.5.0 added Atom-aware methods to the `StoragePort` trait. **In-tree** implementations (`SurrealStore`) ship with the new methods. **Out-of-tree** implementors (custom storage backends) must add:

```rust
// New in v0.5.0 — Atom envelope persistence
async fn create_atom(&self, atom: &Atom) -> Result<()>;
async fn get_atom(&self, id: &AtomId) -> Result<Option<Atom>>;
async fn list_atoms(&self, filter: AtomFilter) -> Result<Vec<Atom>>;
async fn count_atoms_by_kind(&self) -> Result<AtomKindCounts>;
```

If you maintain a custom backend, add these methods before upgrading. The trait is **not** sealed — backwards-compatible only by being explicitly versioned. This is the only breaking change in the v0.5.x line.

No data migration is required for the in-tree backend; existing blocks gain a default `Atom` envelope on next access (lazy upgrade), and `ckl status` will start reporting `atoms.{total, by_kind}` immediately.

## v0.5.4 — `blocks_by_blob_oid` reverse index back-fill

v0.5.4 introduced an inline `blocks_by_blob_oid` reverse index so `ckl blob <oid> --refs` and the default JSON envelope drop to O(log N + k) instead of scanning every block. New writes emit the index inline, but blocks written under v0.5.3 or earlier are not in the index until you back-fill.

```bash
ckl blob reindex --pretty
```

- **Idempotent** (set semantics) — safe to re-run.
- **One-shot** — recommended once on first read post-upgrade. New writes maintain the index automatically.
- **No data migration** required for content. The CAS store (`~/.ckl/blobs/`) is unchanged; only the SurrealKV side gets the inverse mapping.

If you skip the back-fill, blob reads continue to work but `--refs` may report `refs_count: 0` for legacy blocks until you call `ckl blob reindex`.

## v0.5.5 — Lens crates (no migration)

v0.5.5 ships two new crates (`ckl-lens` foundation and `ckl-lens-markdown` first concrete impl) but **no CLI surface changes** and no on-disk format changes. There is nothing to migrate. Out-of-tree consumers that depend on `ckl-types::Atom` can opt into the bidirectional projection model by depending on `ckl-lens` and implementing the `Compiler` / `Lens` traits — see the `ckl-knowledge` skill for the conceptual overview and the well-behaved-lens contract.

## `ckl migrate` / `ckl migrate-finalize`

Wave-6 migration: blocks > N tokens move from inline storage to a CAS (content-addressed) blob store.

```bash
ckl migrate --pretty                            # forward migration
ckl migrate-finalize --pretty                   # purge vlog versions, GC blob store
```

Run `migrate` first; once you're confident the new path works, `migrate-finalize` purges the old version log and runs garbage collection on the blob store.

### When to run

- After upgrading from a pre-Wave-6 ckl version.
- When `ckl status --pretty` reports `wave6_migrated: false`.

## Thresholds

Auto-migration kicks in below these thresholds. Above, ckl asks for explicit confirmation.

| Vectors in DB | Behavior |
|---|---|
| < 500 | Auto-migrate on demand, no prompt |
| 500 — 5,000 | Auto-migrate, log warning |
| 5,000 — 500,000 | Requires `--confirm` flag |
| > 500,000 | Requires `CKL_MIGRATE_CONFIRM=1` env var **and** `--confirm` |

Example for a large production graph:

```bash
ckl daemon stop
CKL_MIGRATE_CONFIRM=1 ckl migrate-vectors --confirm --pretty
ckl daemon start
```

## Verify after migration

```bash
ckl status --pretty                       # vector layout, on_disk count
ckl warm --pretty                         # ensure shards load into RAM
ckl query "<known term>" --pretty         # smoke test semantic search
ckl audit --pretty                        # confirm no quality regressions
```
