# CKL Skills

Agent Skills for the [CKL Rust knowledge engine](https://github.com/koslab/ckl) — a hybrid (BM25 + semantic + graph) code knowledge graph with temporal evolution (Kronos) and a Capture/Intent Protocol (CIP).

These skills follow the [Agent Skills](https://agentskills.io) open standard and work with Claude Code, Codex, Cursor, Windsurf, and any other agent that supports `SKILL.md`.

## Skills

Five focused skills covering the full ckl surface. Activate by domain — Claude only loads the skill body when its description matches the user's intent.

| Skill | What it does |
|---|---|
| [`ckl-system`](skills/ckl-system/SKILL.md) | **Prerequisite.** Install ckl, index a project, configure auth, manage the daemon, crawl docs, run storage migrations. |
| [`ckl-search`](skills/ckl-search/SKILL.md) | Find code & navigate the knowledge graph (hybrid BM25 + semantic + graph search, traversal, project overview). |
| [`ckl-edit`](skills/ckl-edit/SKILL.md) | Modify code with provenance (`edit`/`write`/`apply`/`mv`/`session`) — every change auto-relates to the graph. |
| [`ckl-knowledge`](skills/ckl-knowledge/SKILL.md) | Capture knowledge via CIP, create typed argument edges (Toulmin), compile structured episodes, export/import the graph. |
| [`ckl-evolve`](skills/ckl-evolve/SKILL.md) | Run Kronos cycles, check entity health, audit graph quality (duplicates / contradictions / weak decisions), reconcile via LLM. |

Typical workflow: `ckl-system` (setup) → `ckl-search` (find) → `ckl-edit` (change) → `ckl-knowledge` (capture) → `ckl-evolve` (cycle).

## Install

### Claude Code (personal scope) — all skills

```bash
git clone https://github.com/koslab/ckl-skill ~/src/ckl-skill
ln -s ~/src/ckl-skill/skills/ckl-system    ~/.claude/skills/ckl-system
ln -s ~/src/ckl-skill/skills/ckl-search    ~/.claude/skills/ckl-search
ln -s ~/src/ckl-skill/skills/ckl-edit      ~/.claude/skills/ckl-edit
ln -s ~/src/ckl-skill/skills/ckl-knowledge ~/.claude/skills/ckl-knowledge
ln -s ~/src/ckl-skill/skills/ckl-evolve    ~/.claude/skills/ckl-evolve
```

Or symlink only the ones you need (each works standalone — `ckl-system` is the prerequisite for the others).

### Project scope

```bash
mkdir -p .claude/skills
for s in ckl-system ckl-search ckl-edit ckl-knowledge ckl-evolve; do
  ln -s "$(pwd)/../ckl-skill/skills/$s" ".claude/skills/$s"
done
```

### Via skills.sh (when published)

```bash
npx skills add koslab/ckl-skill/ckl-system
npx skills add koslab/ckl-skill/ckl-search
# ... etc
```

## Prerequisites

- `ckl` binary >= **0.5.3** on `$PATH`. Install:
  ```bash
  cargo install --git https://github.com/koslab/ckl ckl-cli
  ```
- An indexed project: `ckl index /path/to/your/repo`

### What's new in ckl 0.5.x (this skill release)

This is `ckl-skill` v0.2.0, which targets ckl 0.5.3. The skills now cover four new ckl minor releases since v0.4.9:

| ckl release | Adds | Skill that documents it |
|---|---|---|
| `v0.5.0` Atomic Knowledge | `Atom` envelope, JTB+S (`--holder` / `--kind` / `--container`), Curry-Howard tri-decomposition (Code/Claim/Proof), `ckl distill`, severity-graded `weak_decisions`, `StoragePort` trait amendment | `ckl-knowledge`, `ckl-evolve`, `ckl-system` |
| `v0.5.1` Scoped Search II | Unified scope filters (`--org` / `--source-id` / `--holder` / `--kind` / `--container`) on `query` / `search` / `list` / `audit`, `ckl audit --persist-findings`, `--exclude-low`, `atom_coverage` metric, `ckl list organizations \| atoms` | `ckl-search`, `ckl-evolve` |
| `v0.5.2` Agent-First Discovery | `ckl list all`, `--project-query` / `--org-query` / `--source-query` substring → ID resolvers | `ckl-search` |
| `v0.5.3` Direct Blob Access | `ckl blob OID` (default / `--raw` / `--info` / `--refs`), `ckl blob list`, gix-backed CAS at `~/.ckl/blobs/` | `ckl-search`, `ckl-system` |

## Repository layout

```
ckl-skill/
├── README.md
├── LICENSE                       # Apache-2.0
├── CHANGELOG.md
├── .gitignore
├── skills/
│   ├── ckl-system/               # prerequisite
│   │   ├── SKILL.md
│   │   ├── icon.svg
│   │   ├── references/           # setup, daemon, ingest, migrations
│   │   └── scripts/              # reindex.sh
│   ├── ckl-search/
│   │   ├── SKILL.md
│   │   ├── icon.svg
│   │   ├── references/           # query-flags, navigate, blob (v0.5.3)
│   │   └── scripts/              # project-status.sh
│   ├── ckl-edit/
│   │   ├── SKILL.md
│   │   ├── icon.svg
│   │   └── references/           # file-ops, session
│   ├── ckl-knowledge/
│   │   ├── SKILL.md
│   │   ├── icon.svg
│   │   └── references/           # cip, knowledge-types, distillation-rules, argument-relations, atom (v0.5.0)
│   └── ckl-evolve/
│       ├── SKILL.md
│       ├── icon.svg
│       └── references/           # kronos, audit, quality-gates
└── template/
    └── SKILL.md                  # starter template for new skills
```

Each skill follows the [Agent Skills](https://skill.md) progressive-disclosure pattern: `SKILL.md` is the entry point (≤ 500 lines), `references/` holds deeper detail loaded on demand, `scripts/` holds executable helpers that run without consuming context.

## Contributing

PRs welcome. Each skill must:

- Live in `skills/<skill-name>/` with a `SKILL.md` at its root.
- Follow the [Agent Skills frontmatter spec](https://agentskills.io) — only `description` is strictly required by the standard, but include `name` for explicit naming and a `description` ≤ 1,536 characters that front-loads triggers/keywords.
- Keep `SKILL.md` body under 500 lines. Push detailed material into `references/`.
- Use `${CLAUDE_SKILL_DIR}` (or relative paths from `SKILL.md`) for portable script references.
- Be written in English.

## License

Apache-2.0 — see [LICENSE](LICENSE).
