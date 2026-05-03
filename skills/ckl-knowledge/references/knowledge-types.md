# Knowledge Types

CKL distinguishes **22 canonical epistemological types** (the conceptual model) from **12 CLI-exposed types** (the values you pass to `--type`). Capture maps your reality to a CLI type; the engine retains the full epistemic intent.

## The 4-question heuristic

Before capturing, ask:

1. **Is it a claim about the world?** → DECISION, INVARIANT, BEHAVIOR, FACT
2. **Is it a recipe to act?** → PATTERN, ANTIPATTERN, RUNBOOK, RECIPE
3. **Is it a warning of failure?** → GOTCHA, BUG, RISK
4. **Is it a future intent or open question?** → TODO, QUESTION, HYPOTHESIS

If none fit, it is probably **CONTEXT** (background) or **GLOSSARY** (definition).

## Canonical types (22) — by category

### A. Decisions & rules (immutable claims)

| Canonical | Meaning | Maps to CLI |
|---|---|---|
| `decision` | An explicit choice with rationale and trade-offs | `decision` |
| `invariant` | Something that must always hold (assertion, contract) | `decision` |
| `policy` | A team rule or constraint | `decision` |
| `principle` | Higher-order guideline that motivates decisions | `decision` |

### B. Behavioral knowledge (how the system works)

| Canonical | Meaning | Maps to CLI |
|---|---|---|
| `behavior` | Observed runtime behavior of a component | `behavior` |
| `fact` | Verified empirical observation | `behavior` |
| `mechanism` | How a feature is implemented internally | `behavior` |

### C. Patterns (positive recipes)

| Canonical | Meaning | Maps to CLI |
|---|---|---|
| `pattern` | A reusable solution to a recurring problem | `pattern` |
| `idiom` | Language or framework convention | `pattern` |
| `recipe` | Concrete steps to achieve something | `pattern` |
| `runbook` | Operational playbook | `pattern` |

### D. Antipatterns & failures (negative recipes)

| Canonical | Meaning | Maps to CLI |
|---|---|---|
| `antipattern` | A common mistake to avoid | `antipattern` |
| `gotcha` | Surprising trap that bites people | `gotcha` |
| `bug` | Known defect | `gotcha` |
| `risk` | Identified threat or fragility | `gotcha` |

### E. Open work (things to do or resolve)

| Canonical | Meaning | Maps to CLI |
|---|---|---|
| `todo` | Pending action item | `todo` |
| `question` | Open question awaiting an answer | `question` |
| `hypothesis` | Unverified claim under investigation | `question` |

### F. Context (everything else)

| Canonical | Meaning | Maps to CLI |
|---|---|---|
| `context` | Background, history, motivation | `context` |
| `glossary` | Term definition | `glossary` |
| `example` | Worked example or sample | `context` |
| `note` | Catch-all freeform note | `context` |

## CLI-exposed types (12)

These are the valid values for `--type` in `ckl capture`:

```
decision     behavior      pattern       antipattern
gotcha       todo          question      context
glossary     fact          recipe        runbook
```

Every canonical type maps to one of these. When recalling, search by CLI type and disambiguate via tags or content.

## Examples

### Decision
```bash
ckl capture --type decision \
  --title "Use sled over rocksdb for embedded KV" \
  --content "Sled gives us pure-Rust, no compile dependency, ~80% of rocksdb perf for our workload" \
  --rationale "Avoids the LLVM toolchain headache on macOS CI" \
  --tags storage,rust,decision
```

### Pattern
```bash
ckl capture --type pattern \
  --title "Wrap tokio::select with cancellation token" \
  --content "Always pair select! with a CancellationToken so background tasks shut down cleanly" \
  --tags async,tokio,shutdown
```

### Gotcha
```bash
ckl capture --type gotcha \
  --title "ckl list expects 'documents' not 'docs'" \
  --content "ckl list docs returns empty silently. Use 'documents'." \
  --tags ckl,cli,plurality
```

### Question
```bash
ckl capture --type question \
  --title "Should embeddings be quantized at index time?" \
  --content "Currently float32. Quantization to int8 would 4x storage but unclear recall impact" \
  --tags embeddings,perf,open
```

## Choosing a tag taxonomy

CKL does not enforce tags, but consistent tags massively improve recall. Suggested top-level tags:

- **Domain**: `storage`, `search`, `graph`, `cli`, `ui`, `auth`
- **Technology**: `rust`, `sled`, `tokio`, `serde`
- **Lifecycle**: `decision`, `open`, `resolved`, `deprecated`
- **Severity** (for gotchas/bugs): `critical`, `major`, `minor`

## Promotion across types

Knowledge can change type as it matures:

- `hypothesis` → `fact` (after validation) → `invariant` (if generalized)
- `question` → `decision` (when answered) → `policy` (if team-wide)
- `todo` → `pattern` (after implementation reveals a reusable approach)
- `gotcha` → `antipattern` (when frequency justifies a named anti-pattern)

Use `ckl promote <id> --to <type>` (or update via `ckl edit`) to record the transition. The Kronos layer tracks confidence and reuse — promotions usually reflect Kronos signals.
