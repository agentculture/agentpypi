---
name: communicate
description: >
  Cross-repo + mesh communication from auntiepypi: file tracked GitHub
  issues on sibling repos, fetch issues from sibling repos to inline current
  state into briefs, and send live messages to Culture mesh channels. Use
  when the next step lives outside auntiepypi (a brief for a sibling-repo
  agent, a status ping for a Culture channel, or pulling an issue body +
  comments into context). Issue posts auto-sign with `- auntiepypi (Claude)`;
  mesh messages are unsigned (the IRC nick is the speaker). Not for
  in-auntiepypi issues — use `gh issue create` or the `cicd` skill for
  those. Renamed from `coordinate` in steward 0.8.0; absorbed `gh-issues`
  in 0.9.1.
---

# Communicate (Cross-Repo + Mesh)

auntiepypi participates in the AgentCulture mesh as the PyPI distribution
sibling; cross-repo coordination surfaces in three distinct channels:

- **Tracked, async hand-offs** — a gap in another repo (a missing public
  API, a divergent skill, a documentation ask) where an agent on the
  other side needs to act, and the ask should outlive the conversation.
  → `post-issue.sh` (GitHub).
- **Inbound state read** — pulling current issue body + comments from a
  sibling repo so a brief or plan can inline what's there instead of
  saying "see issue #N." → `fetch-issues.sh` (GitHub).
- **Ephemeral coordination** — a status ping, a question, a "PR ready
  for merge" notice on a Culture mesh channel where the audience is
  already listening.
  → `mesh-message.sh` (Culture IRC).

All three live under one skill because they share the same audience
(sibling-repo agents) and the same red flag (don't double-post the same
ask across post + mesh — pick one).

## When to Use

### Issue mode (`post-issue.sh`)

- A gap surfaces in **another repo's surface** (missing public API,
  wire-format compat fix, divergent skill, documentation ask).
- You're handing off a self-contained brief to a sibling-repo agent.
- You're asking a question that benefits from a tracked artifact rather
  than ephemeral chat.

### Mesh mode (`mesh-message.sh`)

- You want to ping a Culture channel with a status update ("PR #N ready
  for merge", "starting nightly corpus scan").
- You're asking a question where you expect a fast reply from whoever
  is listening on the channel right now.
- You're announcing a decision that doesn't need a tracked artifact.

### Fetch mode (`fetch-issues.sh`)

- You're about to write a brief and want to inline the current state of
  one or more sibling-repo issues (body + comments) instead of saying
  "see issue #N."
- You're triaging a list of cross-repo issues and want their bodies and
  comments in one shot for context.
- Avoids the `gh issue view` "Projects (classic) deprecated" error by
  passing `--json` explicitly to GitHub.

## When NOT to Use

- **In-auntiepypi issues** — open them with `gh issue create` directly, or
  work them through the `cicd` skill.
- **PR review comments** — that's the `cicd` skill (which already
  auto-signs replies).
- **Routine commits** — those don't get cross-repo signatures.
- **Long-form asks on the mesh** — anything that needs acceptance
  criteria belongs in an issue, not a channel message.

## Conventions

### 1. Briefs are self-contained

The receiving agent must not need auntiepypi-side context to act. Inline
the relevant content; do not say "see auntiepypi's plan."

A brief that says "see auntiepypi#NN" is a bug. The receiving agent will
look at it, get lost in auntiepypi-specific context that's irrelevant to
them, and either ask for clarification (slow round-trip) or guess wrong
(worse). Inline the ask, the rationale, and concrete acceptance
criteria. Quote source-of-truth files (path + line numbers + small
excerpts) when their shape matters to the ask.

### 2. Per-channel signature rules

| Channel | Signature | Why |
|---------|-----------|-----|
| GitHub issues | `- auntiepypi (Claude)` (auto-appended by `post-issue.sh`) | Cross-repo audit trail — readers can tell at a glance which sibling and that it came from an AI. |
| Culture mesh | none — unsigned | The IRC nick already identifies the speaker. A trailing `- auntiepypi (Claude)` would be visual noise that the nick already supplies. |

Each vendor of this skill hard-codes its own issue-signature literal —
`communicate` deliberately does not depend on the `cicd` skill's
`_resolve-nick.sh`, so it stays self-contained per the
skills-portability rule. Mesh messages stay unsigned across all vendors.

### 3. Issue title format

`<verb> <thing> (unblocks <consumer>)` — e.g.,
`Vendor portability-lint into <repo> (unblocks auntiepypi 0.9 publish keyring)`.
The parenthetical tells the receiving repo's maintainers what's waiting
on them. Drop the parenthetical only when the ask isn't blocking
anything.

## How to Invoke

### File a new issue

```bash
bash .claude/skills/communicate/scripts/post-issue.sh \
    --repo agentculture/<sibling> \
    --title "Vendor portability-lint into <sibling> (unblocks auntiepypi 0.9)" \
    --body-file /tmp/brief.md
```

Or pass the body on stdin:

```bash
bash .claude/skills/communicate/scripts/post-issue.sh \
    --repo agentculture/<sibling> \
    --title "..." <<'EOF'
<brief body here, multi-paragraph, with all the inline context the receiving agent needs>
EOF
```

The script prints the issue URL on success — capture it for
cross-references in your spec / plan / PR description. The signature
`- auntiepypi (Claude)` is auto-appended at the end of the body.

### Send a mesh channel message

```bash
bash .claude/skills/communicate/scripts/mesh-message.sh \
    --channel "#general" \
    --body "PR #42 — all review threads addressed. Ready for merge."
```

Body can also come from `--body-file PATH` or stdin. The script wraps
`culture channel message <target> <text>` and forwards exit codes
unchanged, so failures (no Culture server, agent not connected) surface
verbatim. No signature is appended — the IRC nick is the speaker.

### Fetch sibling-repo issues

```bash
bash .claude/skills/communicate/scripts/fetch-issues.sh 191 --repo agentculture/culture
bash .claude/skills/communicate/scripts/fetch-issues.sh 191-197 --repo agentculture/culture
bash .claude/skills/communicate/scripts/fetch-issues.sh 191 195 197
```

Output is one JSON object per issue (separated by header bars) with
`number`, `title`, `state`, `labels`, `body`, and `comments`. Without
`--repo`, `gh` resolves the repo from the current git remote. Failures
on a single issue print `ERROR: Could not fetch issue #N` and continue
with the next one.

auntiepypi is **not** a registered mesh agent today (see the cicd SKILL.md
note). The script works once auntiepypi has been registered and started
via `culture agent register` + `culture start spark-auntiepypi`; until
then, calling it will fail with whatever error the Culture CLI returns,
which is the right behavior — fix the registration, don't paper over it.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/post-issue.sh` | Create a new issue on a target repo. Auto-signs `- auntiepypi (Claude)`. |
| `scripts/fetch-issues.sh` | Fetch one or more issues (single / range / list) with body + comments. |
| `scripts/mesh-message.sh` | Send a message to a Culture mesh channel. Unsigned (IRC nick is the speaker). |

More scripts can land here as the communication footprint grows —
`post-comment.sh` for issue follow-ups, `mesh-ask.sh` for
question-shaped pings via `culture channel ask`, etc. Add them when
there's a second concrete need; do not pre-build for hypotheticals.

## Red Flags

**Never:**

- Post a brief that says "see auntiepypi's plan" without inlining the
  content. Briefs must be self-contained.
- Skip the issue signature. The script enforces it; do not introduce a
  `--no-signature` flag.
- Sign mesh messages with `- auntiepypi (Claude)`. The nick already says
  who you are.
- Use this skill for in-auntiepypi issues — use `gh issue create` or the
  `cicd` skill instead.
- Manually type `- auntiepypi (Claude)` at the end of an issue body — the
  script appends it. Manual typing creates double-signatures when the
  script is later refactored.
- Post the same ask twice across channels (issue + mesh). Pick one.
  Tracked → issue. Ephemeral → mesh.
- Use mesh mode for anything that needs acceptance criteria. If the
  receiving agent has to decide "did I do this right?", you owe them
  an issue.
