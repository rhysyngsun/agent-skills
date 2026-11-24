# agent-skills

Personal [Agent Skills](https://agentskills.io/specification) and agent rule
files, kept in one place so they can be linted, validated and reused by any
runtime that speaks the standard.

## Skills

Each lives at `skills/<name>/SKILL.md`, where `<name>` is also the frontmatter
`name`.

| Skill | What it covers |
| --- | --- |
| [`stacked-prs`](skills/stacked-prs/SKILL.md) | Laying out a chain of stacked pull requests, opening each against its parent, and rebasing the stack with `--onto` when its base moves |
| [`lean-ctx`](skills/lean-ctx/SKILL.md) | Choosing the right `ctx_*` tool for reading, searching and navigating code in fewer round trips |

## Rules

`rules/*.md` are always-on instructions rather than skills: an agent loads all
of them at session start, so they stay short and say only what is checkable.

| Rule | What it covers |
| --- | --- |
| [`ci`](rules/ci.md) | Proving a new hook, lint rule or test actually fires before calling it done |
| [`git`](rules/git.md) | Force-push safety, rebasing a stack parent-first, pre-push review |
| [`guardrails`](rules/guardrails.md) | When to stop and ask: direction changes, credentials, writes to GitHub, scope creep |
| [`k8s`](rules/k8s.md) | Always naming the kubectl context explicitly |
| [`shell`](rules/shell.md) | `set -euo pipefail`, no hardcoded `/tmp`, dry-run before destructive scripts |
| [`style`](rules/style.md) | Reply length, no praise openers, prose that ships without narrating its own edits |
| [`tools`](rules/tools.md) | Routing code search through lean-ctx instead of grep/glob |

## Development

```bash
prek install            # install the git hooks
prek run --all-files    # run every check
```

`scripts/validate-skills.sh` is also runnable on its own. It checks each skill
directory locally (frontmatter `name` matches the directory, naming rules,
description length, `SKILL.md` spelling) and then hands it to the
[`skills-ref`](https://pypi.org/project/skills-ref/) reference validator via
`uvx`. Without `uvx` on `PATH` it prints a warning and runs the local layer
only.

CI runs the same `prek run --all-files`, plus a whole-tree gitleaks scan - the
gitleaks hook only looks at staged changes, which on a fresh checkout is
nothing.

## Consumption

A NixOS/home-manager flake pins this repository with nvfetcher. It walks
`skills/` and installs whatever it finds, so adding a skill here is a repin
and nothing else. `rules/` is not walked - each rule is named individually on
the consuming side, because it sits next to the hook or permission it
describes, so a new rule file needs a line over there too.
