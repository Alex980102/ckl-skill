# Ingest commands — `crawl`, `watch`, `watch-session`

Continuous ingest brings new content into the indexed graph as it appears.

## Table of contents

- [`ckl crawl`](#ckl-crawl)
- [`ckl watch`](#ckl-watch)
- [`ckl watch-session`](#ckl-watch-session)
- [Comparison](#comparison)

## `ckl crawl`

Fetches documentation from a URL and stores it as indexed `documentation` blocks.

```bash
ckl crawl discover https://example.com/docs --pretty       # preview crawlable pages (read-only)
ckl crawl index https://example.com/docs --project prj_xxx --pretty
```

| Subcommand | Effect |
|---|---|
| `discover <url>` | Read-only: lists pages reachable from the seed URL |
| `index <url>` | Fetch + parse to markdown + store as `doc` blocks |

### Why `ckl crawl` often beats headless browsers

Cloudflare and bot-protection layers reject puppeteer/chromium signatures. `ckl crawl` uses an HTTP client tuned to look like a regular user agent and frequently succeeds where headless fails. **Try it first** before reaching for puppeteer.

### Flags

| Flag | Effect |
|---|---|
| `--project <prj_id>` | Scope to a project |
| `--max-depth N` | Crawl depth (default 2) |
| `--max-pages N` | Cap pages crawled |
| `--include-pattern <regex>` | Only follow URLs matching pattern |
| `--exclude-pattern <regex>` | Skip URLs matching pattern |
| `--user-agent <str>` | Override User-Agent header |
| `--strip-tags <tags>` | Remove `<style>`, `<script>`, etc. (default strips both) |

Output is markdown stored as `documentation`-typed blocks, searchable via `ckl query`.

## `ckl watch`

Live re-index of a project directory on file changes. Useful during active development to keep the graph fresh.

```bash
ckl watch /path/to/project --pretty
ckl watch /path/to/project --debounce 500 --pretty       # ms before re-indexing after last change
ckl watch /path/to/project --include "**/*.rs" --pretty
```

| Flag | Default | Effect |
|---|---|---|
| `--debounce N` | 250 ms | Coalesce rapid changes |
| `--include <glob>` | all parsed | Only watch matching paths |
| `--exclude <glob>` | none | Skip matching paths |
| `--initial-index` | true | Index existing tree before watching |

Run as a background process or under a process supervisor.

## `ckl watch-session`

Indexes a Claude Code session transcript file as the agent runs. Each user/assistant message becomes a `conversation`-typed block.

```bash
ckl watch-session --transcript /path/to/session.jsonl --follow --pretty
ckl watch-session --transcript .claude/sessions/<id>/session.jsonl --follow --project prj_xxx
```

| Flag | Effect |
|---|---|
| `--transcript <path>` | Path to the session jsonl file |
| `--follow` | Tail the file (re-read appended lines) |
| `--project <prj_id>` | Project scope for indexed messages |
| `--entity <id>` | Optionally attach as nutrient source |

Use case: index your own agent's transcripts so future sessions can `ckl search` past conversations.

## Comparison

| Need | Tool |
|---|---|
| One-time fetch of external docs | `ckl crawl index` |
| Preview what's at a URL | `ckl crawl discover` |
| Live updates from local code | `ckl watch` |
| Capture agent's running transcript | `ckl watch-session --follow` |
| Bulk re-index after major changes | `ckl index <path>` (one-shot, in this same skill — see [setup.md](setup.md)) |
