# Daemon, MCP, and warm — full reference

## Table of contents

- [`ckl daemon`](#ckl-daemon)
- [`ckl mcp`](#ckl-mcp)
- [`ckl warm`](#ckl-warm)
- [Lock and ownership model](#lock-and-ownership-model)

## `ckl daemon`

Manages the background process that owns the DB lock. Long-running clients (MCP, watchers) talk to the daemon over a Unix socket.

```bash
ckl daemon status            # is it running? PID? autoprewarm state?
ckl daemon start             # start in background
ckl daemon stop              # stop (required before reembed/migrate-vectors)
ckl daemon restart           # stop + start
ckl daemon logs              # tail logs
```

The daemon:
- Holds the DB lock so concurrent reads/writes are serialized.
- Replays the autoprewarm manifest at boot (sub-2s for typical projects).
- Periodically writes the autoprewarm manifest (60s tokio interval).
- Hosts the MCP socket for inbound stdio clients.

## `ckl mcp`

Starts an MCP server on stdio. Used by Claude Desktop / Code as a tool source.

```bash
ckl mcp                                # blocks; reads JSON-RPC on stdin, writes on stdout
```

Configure your client to launch `ckl mcp` as a stdio MCP server. Example Claude Desktop config:

```json
{
  "mcpServers": {
    "ckl": {
      "command": "ckl",
      "args": ["mcp"]
    }
  }
}
```

The MCP server proxies to the daemon if one is running, or holds the lock itself if the daemon is down.

### MCP tools exposed

`ckl mcp` exposes ~22 tools (after CIP migration phase 1):

- Core: `ckl_query`, `ckl_search`, `ckl_block`, `ckl_context`, `ckl_usages`, `ckl_traverse`
- Navigate: `ckl_doc`, `ckl_list`, `ckl_map`, `ckl_status`
- Capture: `ckl_capture`, `ckl_observe`, `ckl_promote`, `ckl_resolve`, `ckl_archive`, `ckl_deprecate`, `ckl_graduate`
- Kronos: `kronos_seed`, `kronos_cycle`, `kronos_health`, `kronos_ingest`
- Audit: `ckl_audit`

The `ckl-knowledge` and `ckl-evolve` skills cover when to use each.

## `ckl warm`

`pg_prewarm` analogue. Force-loads vector shards into RAM before a heavy search session to avoid first-query cold-start.

```bash
ckl warm --pretty                       # warm all shards
ckl warm --project prj_xxx --pretty     # warm one project
ckl warm --confirm --pretty             # warm even if already warm (force re-read)
```

Useful before:
- A long agent session that will issue many `ckl query` calls.
- Benchmarks where cold-start latency would skew results.
- Resuming work after a daemon restart.

## Lock and ownership model

The DB is single-writer. Three ownership modes:

| Mode | Who holds the lock | When |
|---|---|---|
| Daemon | `ckl daemon` process | Default; clients (MCP, watchers, CLI) connect to daemon |
| MCP-direct | `ckl mcp` process | If daemon is not running, `ckl mcp` holds the lock itself |
| CLI-direct | The `ckl` CLI invocation | If neither daemon nor MCP, the CLI command holds the lock for its duration |

**Rule:** stop the daemon before any heavy single-tenant op:

```bash
ckl daemon stop
ckl reembed --project prj_xxx --pretty
ckl daemon start
```

Without stopping the daemon, large `reembed` / `migrate-vectors` runs may queue behind incoming MCP requests and time out.

## Heartbeat checks

```bash
ckl daemon status --pretty               # is it alive?
ckl status --pretty                      # DB statistics (works without daemon — opens read-only)
```

If `ckl daemon status` says running but `ckl query` hangs, the socket may be stuck — `ckl daemon restart` clears most cases.
