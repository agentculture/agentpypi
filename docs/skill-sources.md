# Skill upstream sources

auntiepypi vendors its `.claude/skills/` from **guildmaster** — the
AgentCulture **skills supplier** after the steward → guildmaster cutover
(guildmaster 0.5.0, 2026-05-24). `steward` retains the **alignment** role
(`steward doctor`, the sibling-pattern baseline); only the skills-supplier
role moved. This file tracks provenance so re-syncs stay deterministic.

Three skills (`think`, `spec-to-plan`, `assign-to-workforce`) originate in
[`agentculture/devague`](https://github.com/agentculture/devague); guildmaster
only **re-broadcasts** them. Cite guildmaster's copy; track devague as the true
origin.

Every vendored `SKILL.md` carries `type: command`. auntiepypi declares a
culture agent (`culture.yaml`, `backend: claude`), and `core.skill_loader`
silently skips any `SKILL.md` lacking `type:` — so the field is load-bearing,
even where guildmaster's upstream copy omits it.

| Skill | Upstream | Origin | Notes | Last synced |
|-------|----------|--------|-------|-------------|
| `cicd` | `../guildmaster/.claude/skills/cicd/` | guildmaster | **Rebased on `agex pr`** (steward 0.12.0): the 5 thin scripts (`workflow.sh`, `pr-status.sh`, `pr-reply.sh`, `_resolve-nick.sh`, `portability-lint.sh`) delegate lint/open/read/reply/delta to `agex` and add the `status` / `await` SonarCloud-gating extensions. Replaces auntiepypi's earlier standalone 10-script copy. Consumer-identifying prose (`guildmaster` → `auntiepypi`) adapted; upstream history (`Renamed from pr-review in steward 0.7.0; rebased on agex in 0.12.0`) and env-var literals (`STEWARD_PR_AWAIT_*`) kept verbatim. PR signature resolves at runtime from `culture.yaml` via `_resolve-nick.sh` (→ `auntiepypi`). Requires `agex` on PATH. | 2026-05-25 (guildmaster 0.5.0) |
| `communicate` | `../guildmaster/.claude/skills/communicate/` | guildmaster | Consumer-identifying prose adapted. **No hard-coded signature literal** anymore — `post-issue.sh` is `agtag`-backed and resolves the signing nick from `culture.yaml` (→ `- auntiepypi (Claude)`); requires `agtag` (>=0.1) on PATH. Adds `post-comment.sh` and the supplier `templates/` (`skill-update-brief.md`, `skill-new-brief.md`) — kept verbatim; inert for a consumer (they cite guildmaster as upstream). Renamed from `coordinate` in steward 0.8.0; absorbed `gh-issues` in 0.9.1. | 2026-05-25 (guildmaster 0.5.0) |
| `version-bump` | `../guildmaster/.claude/skills/version-bump/` | guildmaster | Pure-Python, CWD-aware (`scripts/bump.py`). Verbatim except added `type: command`. | 2026-05-25 (guildmaster 0.5.0) |
| `agent-config` | `../guildmaster/.claude/skills/agent-config/` | guildmaster (origin steward) | Backs guildmaster's `guild show`; auntiepypi has no `guild` binary but can run `scripts/show.sh` directly. `scripts/show.sh` + `data/backend-fingerprints.yaml` verbatim; SKILL.md provenance line adapted to "Vendored via guildmaster (origin steward)". Already carried `type: command`. | 2026-05-25 (guildmaster 0.5.0) |
| `doc-test-alignment` | `../guildmaster/.claude/skills/doc-test-alignment/` | guildmaster | **STUB** — `scripts/check.sh` exits not-yet-implemented; the contract lives in SKILL.md. Verbatim except added `type: command`. | 2026-05-25 (guildmaster 0.5.0) |
| `pypi-maintainer` | `../guildmaster/.claude/skills/pypi-maintainer/` | guildmaster | Switch a package install between PyPI / TestPyPI / local editable (`scripts/switch-source.sh`). Verbatim except added `type: command`. | 2026-05-25 (guildmaster 0.5.0) |
| `run-tests` | `../guildmaster/.claude/skills/run-tests/` | guildmaster | pytest + xdist + coverage (`scripts/test.sh`). Verbatim except added `type: command`. | 2026-05-25 (guildmaster 0.5.0) |
| `sonarclaude` | `../guildmaster/.claude/skills/sonarclaude/` | guildmaster | SonarCloud API queries (`scripts/sonar.sh`). Verbatim except added `type: command`. | 2026-05-25 (guildmaster 0.5.0) |
| `think` | `../guildmaster/.claude/skills/think/` | **devague** (re-broadcast via guildmaster) | idea→spec leg of the devague workflow chain. Verbatim (already carried `type: command` at guildmaster). Origin/broadcast prose left verbatim. | 2026-05-25 (guildmaster 0.5.0) |
| `spec-to-plan` | `../guildmaster/.claude/skills/spec-to-plan/` | **devague** (re-broadcast via guildmaster) | spec→plan leg of the devague workflow chain. Verbatim (already carried `type: command`). | 2026-05-25 (guildmaster 0.5.0) |
| `assign-to-workforce` | `../guildmaster/.claude/skills/assign-to-workforce/` | **devague** (re-broadcast via guildmaster) | plan→parallel-implementation leg of the devague workflow chain. Verbatim (already carried `type: command`). | 2026-05-25 (guildmaster 0.5.0) |

## Re-sync procedure

```bash
# Diff against upstream before pulling (example: the three resync targets):
for s in cicd communicate version-bump; do
  diff -ru ../guildmaster/.claude/skills/$s .claude/skills/$s
done

# Pull a skill fresh (remove first so dropped scripts don't linger):
rm -rf .claude/skills/<skill>
cp -R ../guildmaster/.claude/skills/<skill> .claude/skills/

# Re-apply the identifier-only adaptations in SKILL.md:
#   - consumer-identifying prose: `guildmaster` → `auntiepypi` (NOT where it
#     cites guildmaster/steward/devague as the upstream/origin).
#   - add `type: command` to the frontmatter if guildmaster's copy omits it
#     (load-bearing for auntiepypi's culture/claude backend).
# No script bodies are edited (cite-don't-import). The communicate signature
# resolves from culture.yaml via agtag — no literal to patch.
```

If a re-sync would lose an auntiepypi adaptation, lift the change upstream into
guildmaster first (per guildmaster's `docs/skill-sources.md`) and re-vendor.

## Tooling prerequisites

- **`agex`** (>=0.21) on PATH — `cicd` delegates the PR lifecycle to `agex pr`.
- **`agtag`** (>=0.1) on PATH — `communicate` issue I/O wraps `agtag issue`.

Both ship on PATH in the standard AgentCulture dev setup (installed per the
agex-cli / agtag READMEs).
