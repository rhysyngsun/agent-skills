# Git and stacked PRs

- Never force-push without first comparing against the remote. `git fetch
  <remote> <branch>`, then `git log --oneline <branch>..<remote>/<branch>`
  (what you would destroy) and the reverse (what you would add). If the
  first is non-empty, stop and ask.
- Force-push only with `--force-with-lease`. A plain `--force`/`-f` is
  blocked by a hook, as is a lease push where the remote has moved.
- Snapshot what you are about to move before any rebase or force-push:
  `git rev-parse <branch>` for each branch in the stack. Recovery is then
  one `git reset --hard <sha>` instead of a reconstruction.
- Rebase a stack parent-first, one child at a time, onto its *rebased*
  parent:

      git rebase --onto <new-parent> <old-parent> <child>

  Replaying each child off the original base is what severs the ancestor
  chain - every branch rebases cleanly and the stack is still wrong.
- After the whole pass, verify the chain before pushing anything:
  `git log --oneline --graph <branch1> <branch2> ...`. Each branch must
  contain its parent.
- When a parent merges, retarget the child PR with `gh pr edit --base`.
- The whole procedure for building or rebasing a stack, including the
  `gh stack` path and what it does not guard, is the `stacked-prs`
  skill.

# Before you push

Before pushing a branch that opens or updates a pull request, run the
`code-review` skill against the diff and tell me what it found. Every time
an independent reviewer has looked at a diff here it has found something -
a no-op hook, a stale editable install, an automerge regression - and the
misses all came from self-assessing with full context, where you see what
you meant rather than what you wrote.
