---
name: stacked-prs
description: Create and maintain a stack of pull requests - lay out the branch chain, open each PR against its parent, link them into a GitHub stack, and rebase the stack safely when its base moves. Use when asked to "restack", "rebase the stack", "rebase my PRs onto main", "stack this", "split this into a stack" or "open a stacked PR"; when a parent PR merged; when main moved under a stack; or after addressing feedback on a branch that has children.
---

# stacked-prs

A stack is a chain of branches where each one's base is the previous one,
and each PR's base is its parent's branch. Both halves of the lifecycle
fail the same silent way: every branch looks fine on its own and the chain
between them is wrong.

- **Creating it wrong.** A child PR opened against the trunk instead of its
  parent still shows a clean `gh pr view`. It reviews as a diff containing
  its parent's commits, which is the one thing a stack exists to avoid.
- **Rebasing it wrong.** Replaying each child onto the new base
  independently gives you N branches that all contain the base and none of
  which contain their parent. `git rebase <new-base> <child>` is the wrong
  command. The right one names the old parent explicitly, so only the
  child's own commits move:

      git rebase --onto <rebased-parent> <old-parent> <child>

Three things are mandatory on every path through this skill: snapshot the
tips before moving anything, verify the ancestor chain afterwards, and stop
for confirmation before the first push.

## 0. Pick the path

    gh stack --version          # extension present?
    gh stack view --json        # is THIS stack tracked locally?

| state | path |
| --- | --- |
| `view --json` returns the stack | gh-stack path |
| "not part of a stack", PRs exist | `gh stack link` first, then gh-stack path |
| "not part of a stack", no PRs | gh-stack path, from `gh stack init` |
| extension missing | raw-git path |

`gh stack` is v0.0.8. Read the field names off the JSON it actually returns
rather than assuming a schema.

## Part A - create a stack

### A1. Lay out the chain first

Print the intended chain bottom-up, trunk first, one line per branch saying
what it contains, and get it confirmed before creating anything. Reordering
later means `gh stack modify`, which you may not run (see below), or a hand
rebase of everything above the insertion point.

### A2. Create the branches

    gh stack init <bottom> <middle> <top>

`init` adopts branches that already exist and creates the ones that do not,
basing each on the previous and the first on the default branch. Pass
`--base <trunk>` to stack onto a release branch. To extend a stack that
already exists:

    gh stack add <branch>

Raw-git equivalent, one branch at a time:

    git switch -c <child> <parent>

### A3. Push the branches

    gh stack push                           # whole stack, bottom-up
    git push -u origin <branch>             # raw-git, one at a time

Read "Unguarded pushes" below before the first `gh stack push`.

### A4. Open one PR per branch, each against its parent

    gh pr create --base <parent-branch> ...

The base is the parent branch, never the trunk, for every PR but the bottom
one. On a `github.com/mitodl/` remote the title and body come from the
`create-ol-pull-request` skill - run it per branch rather than improvising a
body here.

Do not use `gh stack submit` for this. It opens an interactive editor, and
its only non-interactive form, `--auto`, invents PR titles and skips the
template.

### A5. Link them into a GitHub stack

    gh stack link <bottom> <middle> <top>   # bottom to top

`link` takes branch names, PR numbers or PR URLs and needs no local
tracking state, so it also works on a stack somebody built by hand. Pass an
existing stack number as the first argument to append to that stack instead
of re-listing it.

### A6. Report

Branch, PR number, base and CI status for each, bottom-up.

## Part B - restack onto a moved base

### B1. Establish the stack

    git fetch origin --prune
    gh stack view --json

Without the extension, reconstruct it from the PRs:

    gh pr list --author @me --state open --json number,headRefName,baseRefName,title

Order bottom-up by following `baseRefName` from the branch whose base is the
trunk. Print the chain and the PR number for each before touching anything.
A branch with no PR yet will not appear - get the rest of the chain from the
user rather than guessing.

### B2. Snapshot before moving anything

    for b in <branches>; do echo "$b $(git rev-parse "$b")"; done

Keep that output in the transcript. It is the undo: `git reset --hard <sha>`
per branch restores the pre-rebase state exactly. Required on both paths -
`gh stack rebase --abort` only helps while a rebase is still in progress.

### B3. Rebase, bottom-up

    gh stack rebase

That fetches and cascade-rebases the whole stack, each branch onto its
rebased parent. `--no-trunk` skips the trunk hop when only the inter-branch
relationships need fixing; `--continue` and `--abort` behave like git's.

Raw-git, recording each branch's old tip *before* you rebase it, because it
becomes the `<old-parent>` for its child:

    old_parent=$(git rev-parse <parent>)       # BEFORE rebasing <parent>
    git rebase --onto origin/main $(git merge-base <parent> origin/main) <parent>
    # then, for each child in order:
    git rebase --onto <parent> "$old_parent" <child>

Stop on the first conflict and resolve it. Do not continue down the stack
with an unresolved branch behind you.

### B4. Verify the chain - do not skip this

    git log --oneline --graph --decorate <branch1> <branch2> <branch3> ...

Every branch must contain its parent. Check it explicitly:

    git merge-base --is-ancestor <parent> <child> && echo "ok: <child>"

Run that for every parent/child pair, on both paths. A silent `ok` for all
of them is the only evidence the stack survived, and it checks
`gh stack rebase` exactly as much as it checks a hand-rolled rebase.

### B5. Stop and show the user

Print the graph and the per-pair ancestor results and **wait for
confirmation**. Nothing has been pushed yet, so everything so far is
undoable from the snapshot in B2. After the push it is not.

### B6. Push, bottom-up

    gh stack push
    git push --force-with-lease origin <branch>   # raw-git, one at a time

Parents first, so a reviewer never sees a child without its parent.

### B7. Retarget the bases

When the bottom of the stack merged, its child's PR still points at a
deleted branch:

    gh pr edit <number> --base <new-base>

`gh stack push` and `gh stack link` do this for a tracked stack. Check it
either way. Report the final state: branch, PR number, base, CI status.

## gh stack commands you may not run

- `gh stack submit` - interactive editor, and `--auto` invents PR titles and
  skips the org template. Use A4 and A5 instead.
- `gh stack modify` - interactive TUI with no non-interactive form.
  Restructure by hand, or hand it to the user.
- `gh stack sync` - fetches, rebases **and pushes** in one command, so it
  pushes before anyone has seen the result. That is the opposite of B5. Use
  `gh stack rebase`, then B4, then `gh stack push`.

## Unguarded pushes

`claude-force-push-guard` only inspects `git push` command lines. It never
sees `gh stack push`, `gh stack sync` or `gh stack submit`, every one of
which force-pushes with `--force-with-lease --atomic`. The lease alone does
not cover a stale remote-tracking ref, which is the case the guard exists
for.

So before any `gh stack` push, do the guard's job by hand:

    git fetch origin --prune
    git log --oneline <branch>..origin/<branch>    # per branch; empty means safe

If any of those is non-empty, stop and ask - the push would discard those
commits. A plain `git push --force` is still blocked by the hook, and so is
a lease push where the remote has moved since your last fetch; if the guard
fires, fetch and read the remote commits before doing anything else.

## Recovery

    git reset --hard <sha>       # per branch, from the B2 snapshot
    gh stack rebase --abort      # mid-rebase only; restores all branches
