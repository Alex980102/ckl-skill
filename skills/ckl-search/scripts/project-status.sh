#!/usr/bin/env bash
# project-status.sh — Full status overview for a CKL-indexed project.
#
# Usage:
#   bash project-status.sh [project_id]
#
# Shows:
#   - Index status (docs, blocks, embeddings, last index time)
#   - Knowledge graph map (with quality signals)
#   - Recent knowledge blocks
#
# Requires: ckl >= 0.4.9 on $PATH.

set -euo pipefail

if ! command -v ckl >/dev/null 2>&1; then
  echo "error: ckl binary not found on PATH" >&2
  echo "install: cargo install --git https://github.com/koslab/ckl ckl-cli" >&2
  exit 127
fi

PROJECT_FLAG=()
if [ -n "${1:-}" ]; then
  PROJECT_FLAG=(--project "$1")
fi

echo "=== CKL Status ==="
ckl status "${PROJECT_FLAG[@]}" --pretty

echo ""
echo "=== Knowledge Graph Map ==="
ckl map "${PROJECT_FLAG[@]}" --quality --pretty

echo ""
echo "=== Recent Knowledge Blocks ==="
ckl list blocks --content-type knowledge --limit 20 "${PROJECT_FLAG[@]}" --pretty
