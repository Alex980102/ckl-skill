#!/usr/bin/env bash
# reindex.sh — Re-index a project directory after code changes.
#
# Usage:
#   bash reindex.sh [path]
#
# Defaults to the current directory. Re-runs the full ckl indexer
# (BM25 + semantic + graph) and prints updated stats.
#
# Requires: ckl >= 0.5.7 on $PATH.

set -euo pipefail

if ! command -v ckl >/dev/null 2>&1; then
  echo "error: ckl binary not found on PATH" >&2
  echo "install: cargo install --git https://github.com/koslab/ckl ckl-cli" >&2
  exit 127
fi

PROJECT_PATH="${1:-.}"

echo "Re-indexing ${PROJECT_PATH} ..."
ckl index "${PROJECT_PATH}" --pretty

echo ""
echo "=== Updated Stats ==="
ckl status --pretty
