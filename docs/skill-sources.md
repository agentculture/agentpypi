# Skill upstream sources

auntiepypi vendors its `.claude/skills/` from steward (the canonical
sibling-pattern owner). This file tracks provenance so re-syncs are
deterministic.

| Skill | Upstream | Downstream copies (known) | Notes |
|-------|----------|---------------------------|-------|
| `version-bump` | `../steward/.claude/skills/version-bump/` | `auntiepypi` (this repo) | Pure-Python; CWD-aware. Re-sync when steward bumps the script. Identifier comments adapted (steward-cli → AgentCulture sibling convention). |
| `cicd` | `../steward/.claude/skills/cicd/` | `auntiepypi` (this repo) — adapted | Workflow shape kept verbatim; SKILL.md prose identifiers (`Steward` → `auntiepypi`) adapted where they identify the consumer. Upstream-history references (`Renamed from pr-review in steward 0.7.0`) and env var literals (`STEWARD_PR_AWAIT_*`) stay verbatim. Reviewer wiring (Qodo / Copilot) is the workspace default. Renamed from `pr-review` upstream in steward 0.7.0. |
| `communicate` | `../steward/.claude/skills/communicate/` | `auntiepypi` (this repo) — adapted | SKILL.md prose identifiers adapted. **`scripts/post-issue.sh` signature literal hard-coded to `- auntiepypi (Claude)`** per the per-vendor portability rule (the skill deliberately doesn't depend on `cicd/_resolve-nick.sh`, so each vendor edits the literal in-place). Renamed from `coordinate` upstream in steward 0.8.0; absorbed `gh-issues` in 0.9.1. |

## Re-sync procedure

```bash
# Diff against upstream before pulling:
diff -ru ../steward/.claude/skills/version-bump .claude/skills/version-bump
diff -ru ../steward/.claude/skills/cicd         .claude/skills/cicd
diff -ru ../steward/.claude/skills/communicate  .claude/skills/communicate

# Pull (overwrite identifier-only adapted scripts and re-apply the rename):
cp -R ../steward/.claude/skills/version-bump .claude/skills/
cp -R ../steward/.claude/skills/cicd         .claude/skills/
cp -R ../steward/.claude/skills/communicate  .claude/skills/

# Re-apply identifier substitutions in cicd/SKILL.md and
# communicate/SKILL.md (search-replace `steward` → `auntiepypi` and
# `Steward` → `auntiepypi` for *consumer* references; leave upstream
# citations and env var literals alone).
#
# Re-apply the per-vendor signature literal in
# communicate/scripts/post-issue.sh:
sed -i 's/- steward (Claude)/- auntiepypi (Claude)/g' \
    .claude/skills/communicate/scripts/post-issue.sh
```

If a re-sync would lose the auntiepypi adaptation, lift the change upstream
into steward first (per `../steward/docs/skill-sources.md` "When a skill
should be promoted upstream") and re-vendor.
