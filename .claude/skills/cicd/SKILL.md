---
name: cicd
description: >
  auntiepypi's CI/CD lane: open PR (auto-wait for Qodo/Copilot), push fixes
  (re-poll bots), triage feedback, reply, resolve. Adds a portability lint
  (no absolute /home paths, no per-user dotfile refs in committed docs),
  an alignment-delta check when CLAUDE.md or culture.yaml change, and
  greenfield-aware test/version-bump steps. Use when: creating PRs in
  auntiepypi, handling review feedback, polling CI status, or the user says
  "create PR", "review comments", "address feedback", "resolve threads".
  Renamed from `pr-review` in steward 0.7.0.
---

# CI/CD — auntiepypi edition

auntiepypi's PRs touch Python packaging code, server config, vendored skills,
and CLAUDE.md guidance. The generic `pr-review` skills don't know that, so
they miss two classes of bugs the AgentCulture sibling pattern keeps
producing:

- **Path leaks** — committing absolute home-directory paths that work only on
  the author's machine. (Steward's PR #1 had four of these; the lint runs
  here so auntiepypi can't repeat the mistake.)
- **Per-user config dependencies** — referencing a dotfile under the user's
  home directory in repo guidance, breaking reproducibility for other
  contributors and CI.

This skill specializes Culture's `pr-review` flow to catch both up front, plus
an alignment-delta step when auntiepypi-affecting files change. The workflow
is encapsulated in `scripts/workflow.sh` — follow that, not a manual checklist.

## Prerequisites

Hard requirements: `gh` (GitHub CLI), `jq`, `bash`, `python3` (stdlib only),
`curl` (used by `pr-status.sh`).

Soft requirement: `PyYAML` is needed **only for suffix mode** of the sibling
`agent-config` skill, where it parses Culture's server manifest. Path mode
and every `cicd` script work without it. If suffix mode runs without
PyYAML it exits with a clear install hint.

Per-machine paths (sibling-project layout) live in
`.claude/skills.local.yaml`; see the committed `.example` for the schema.

## How to run

`scripts/workflow.sh` is the entry point. Subcommands:

| Command | Purpose |
|---------|---------|
| `workflow.sh lint` | Portability lint on the current diff (staged + unstaged). |
| `workflow.sh open-pr --title T [--body-file F] [--wait SECS] [...]` | `gh pr create` then sleep 180s (or `--wait SECS`) and fetch reviewer comments in one shot. Use after pushing the initial branch. |
| `workflow.sh poll <PR>` | Fetch and display all review comments. |
| `workflow.sh poll-readiness <PR> [--max-iters N] [--interval SECS] [--require LIST]` | Loop until all required reviewers are ready (default `qodo`; pass `--require qodo,copilot` to also gate on Copilot) — or the PR closes / iteration cap hits. Headline on stdout, per-iteration diagnostics on stderr. Direct wrapper around `scripts/poll-readiness.sh`. |
| `workflow.sh wait-after-push <PR> [--wait SECS]` | Sleep 180s (or `--wait SECS`) then re-fetch comments. Use after pushing fixes. |
| `workflow.sh await <PR>` | Poll for reviewer readiness (default: 30 × 60s ≈ 30 min cap, requires qodo only; tune with `STEWARD_PR_AWAIT_ITERS`, `STEWARD_PR_AWAIT_INTERVAL`, and `STEWARD_PR_REVIEWERS`), then run `pr-status.sh` (CI checks + SonarCloud quality gate, OPEN issues, hotspots) and `pr-comments.sh` (inline / issue / top-level / SonarCloud-new-issues sections). Exits non-zero on SonarCloud `ERROR` or unresolved threads. Setting the legacy `STEWARD_PR_AWAIT_SECONDS=<n>` falls back to a fixed sleep with a deprecation warning. |
| `workflow.sh delta` | Dump each sibling project's `CLAUDE.md` head + `culture.yaml`. |
| `workflow.sh reply <PR>` | Batch reply (JSONL on stdin) and resolve threads. |
| `workflow.sh help` | Print this list. |

The vendored single-comment helpers — `pr-reply.sh`, `pr-status.sh` — live
next to `workflow.sh` and are usable directly when batching isn't appropriate.

## Polling for reviewer readiness

`scripts/poll-readiness.sh` watches a PR until its required reviewers post
real (not placeholder) feedback, the PR closes, or an iteration cap fires.
It fetches `gh api` JSON directly — never `pr-comments.sh` output — so
truncation can't bias the gate. Default required set is qodo only
(see header comments and `--help` for tunables, env vars, and the `qodo` /
`copilot` heuristics; Copilot is detected but not required because its
review bot is silent on agentculture repos in 2026). Heartbeats stream to
stderr; the final headline is the only thing on stdout.

Two ways to drive it:

- **Synchronous** — `workflow.sh await <PR>` after `gh pr create`. The
  main session burns context during the wait; fine up to ~5 minutes.
- **Asynchronous** — for longer waits, run the looper inside a background
  subagent (Agent tool, `run_in_background: true`) so the main session
  only pays the cache cost when readiness fires. The subagent's only job
  is to invoke `poll-readiness.sh` and echo its headline back. The
  parent triages with `workflow.sh await <PR>` when the notification
  arrives. The user can interrupt with TaskStop.

This pattern is borrowed from sibling repo
[`agentculture/cfafi`](https://github.com/agentculture/cfafi)'s `poll`
skill — steward (and auntiepypi as a downstream vendor) ships only the
looper rather than promoting `poll` to its own first-class skill until
other verbs need the same primitive.

## End-to-end flow

```text
git checkout -b <type>/<desc>
# ... edit ...
.claude/skills/cicd/scripts/workflow.sh lint
git commit -am "..." && git push -u origin <branch>
gh pr create --title "..." --body "..."   # title <70 chars, body signed "- <nick> (Claude)"
.claude/skills/cicd/scripts/workflow.sh await <PR>   # readiness loop, then CI + SonarCloud + all comments
# triage; if CLAUDE.md/culture.yaml/.claude/skills changed:
.claude/skills/cicd/scripts/workflow.sh delta
# fix, re-lint, push
.claude/skills/cicd/scripts/workflow.sh reply <PR> < replies.jsonl
gh pr checks <PR>
# Wait for human merge — never merge yourself.
```

Branch naming: `fix/<desc>`, `feat/<desc>`, `docs/<desc>`, `skill/<name>`.
PR / comment signature: `- <nick> (Claude)`, where `<nick>` comes from
the agent's own `culture.yaml` — first agent's `suffix` — falling back
to the git-repo basename when no `culture.yaml` is present. The reply
script resolves this via `scripts/_resolve-nick.sh` and auto-appends the
signature only when the body isn't already signed, so JSONL reply
entries can include or omit it. Hand-rolled `gh pr create` and
`gh issue comment` calls should follow the same convention.

## Triage rules

For every comment, decide **FIX** or **PUSHBACK** with reasoning.

Default to **FIX** for: portability complaints (always valid for auntiepypi —
recurring bug class across the AgentCulture sibling pattern), test or doc
requests, style nits aligned with workspace conventions.

Default to **PUSHBACK** for: architecture opinions that conflict with workspace
`CLAUDE.md` or the all-backends rule; greenfield false-positives (e.g. "add
tests" before there's any source — defer to a later PR, don't refuse).

### Alignment-delta rule

If the PR touches `CLAUDE.md`, `culture.yaml`, or anything under
`.claude/skills/`, run `workflow.sh delta` **before** declaring FIX or
PUSHBACK on each comment. The script dumps the head of every sibling
project's `CLAUDE.md` plus the full `culture.yaml`, using `sibling_projects`
from `skills.local.yaml`. Note any sibling that needs a follow-up PR and
mention it in your reply.

## Greenfield-aware steps

The lint and the workflow script are always-on. Stack-specific steps are
conditional and currently no-op (greenfield repo):

```bash
[ -d tests ] && [ -f pyproject.toml ] && uv run pytest tests/ -x -q
[ -f pyproject.toml ] && bump_version_per_project_convention   # see project README
[ -f .markdownlint-cli2.yaml ] && markdownlint-cli2 "$(git diff --name-only --cached '*.md')"
```

Revisit each line as the corresponding stack element actually lands.

## Reply etiquette

Every comment must get a reply — no silent fixes. Always pass `--resolve`
when batch-replying so threads close automatically. Reference the
review-comment IDs in the fix-up commit message.

SonarCloud is queried in two places: `pr-status.sh` (quality gate, OPEN
issues, hotspots) and the Section-4 dump in `pr-comments.sh` (new-issue
list). Both derive the project key as `<owner>_<repo>`; override with
`SONAR_PROJECT_KEY=<key>` for non-standard naming, and they silently skip
when the project isn't on SonarCloud. auntiepypi isn't yet a registered mesh
agent, so the post-merge IRC ping that Culture's `pr-review` includes is
still skipped — that returns when auntiepypi joins the mesh.
