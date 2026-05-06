---
name: my-skill
description: One- or two-sentence description that front-loads the trigger keywords an agent must see to activate this skill. Mention every relevant tool, domain term, and verb the user might use. Up to 1024 characters. The agent picks this skill based on this field alone — be specific and include "Use when ..." with concrete trigger phrases.
license: Apache-2.0
compatibility: List binary / runtime / network requirements (e.g. `Requires foo CLI >= 1.0 on $PATH`, or for ckl-skill clones: `Requires ckl binary >= 0.5.5 on $PATH`). 1–500 characters.
metadata:
  version: 0.2.2
  upstream: https://github.com/your-org/your-repo
  composes-with: other-skill-1, other-skill-2
  primary-commands: cmd-a, cmd-b, cmd-c
---

# My Skill

> One-paragraph north star: what this skill enables the agent to do, and why it exists. Reference the upstream tool, its config path, and any prerequisite skill.

## Quick Reference

A flat, scannable command/API map. Group by category. Keep examples copy-pasteable.

| Command | Purpose |
|---|---|
| `my-cli action --flag value` | Does X |
| `my-cli other --flag value` | Does Y |

Full per-flag reference: [references/details.md](references/details.md).

## The Flow

The canonical agent workflow this skill enforces. Three to five steps max.

1. **Find** — how to discover relevant items
2. **Read** — how to inspect them
3. **Act** — how to make changes
4. **Capture / Commit** — how to record outcomes

## Conventions

- Bullet-point any rules an agent must always follow.
- Keep this section short.
- Use imperative form: ALWAYS, NEVER, USE, DO NOT.

## When to Use What

| Situation | Use |
|---|---|
| Case A | Command A |
| Case B | Command B |

## Composes with

This skill is part of the `<your-org>` skill suite. Use it together with:

- **`other-skill-1`** — when …
- **`other-skill-2`** — when …

## Utility Scripts

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/example.sh
```

Falls back to `scripts/example.sh` for agents that don't expand `${CLAUDE_SKILL_DIR}`.

## Gotchas

1. List the top traps an agent will hit.
2. Be specific. Each gotcha should be one sentence.
3. Include the failure mode, not just the rule.

## See Also

- [references/details.md](references/details.md) — deeper material loaded on demand
- Upstream tool documentation: <link>
