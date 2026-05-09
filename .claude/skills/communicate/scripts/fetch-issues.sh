#!/usr/bin/env bash
# Fetch GitHub issues with full body and comments.
# Usage: fetch-issues.sh [RANGE|NUMBER...] [--repo OWNER/REPO]
#   fetch-issues.sh 191-197                   # range
#   fetch-issues.sh 191                       # single
#   fetch-issues.sh 191 192 195               # list
#   fetch-issues.sh --repo foo/bar 5          # explicit repo (otherwise gh resolves it from the git remote)
#
# Passing --json explicitly avoids the gh "Projects (classic) deprecated"
# error that bare `gh issue view <num>` triggers on issues attached to
# a classic project board.

set -euo pipefail

REPO_ARGS=()
NUMBERS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Error: --repo requires a value (OWNER/REPO)" >&2
        echo "Usage: fetch-issues.sh [RANGE|NUMBER...] [--repo OWNER/REPO]" >&2
        exit 1
      fi
      # Pass --repo and its value as separate argv elements so a value
      # that contains whitespace can't word-split into extra gh args.
      REPO_ARGS=(--repo "$2")
      shift 2 ;;
    *-*)  # range like 191-197
      IFS='-' read -r start end <<< "$1"
      for ((i=start; i<=end; i++)); do NUMBERS+=("$i"); done
      shift ;;
    *)  NUMBERS+=("$1"); shift ;;
  esac
done

if [[ ${#NUMBERS[@]} -eq 0 ]]; then
  echo "Usage: fetch-issues.sh [RANGE|NUMBER...] [--repo OWNER/REPO]" >&2
  exit 1
fi

for num in "${NUMBERS[@]}"; do
  echo "========================================"
  echo "ISSUE #${num}"
  echo "========================================"
  gh issue view "$num" "${REPO_ARGS[@]}" --json number,title,state,labels,body,comments \
    --jq '{
      number: .number,
      title: .title,
      state: .state,
      labels: [.labels[].name],
      body: .body,
      comments: [.comments[] | {author: .author.login, body: .body}]
    }' 2>/dev/null || echo "ERROR: Could not fetch issue #${num}"
  echo
done
