# Code navigation

In a lean-ctx-indexed project, `Grep`, `Glob` and a bare `rg`/`grep`/`find`
are **blocked by a PreToolUse hook**. Its denial carries the `ToolSearch`
selector and the replacement calls, so you do not need them memorised - but
reaching for the built-in first costs a round trip. The full tool map is the
`lean-ctx` skill.

Searching *outside* the project - `/nix/store`, a vendored source tree, `/etc` -
is not blocked; use `rg` there as normal.

Keep using `Bash` for running commands - not `ctx_shell`. The lean-ctx
server is allowed whole-server, so routing commands through `ctx_shell`
would sidestep the per-command `Bash(...)` permission gates.

# CLI tools

Rules:

- You may execute read-only operations of CLI tools

Some standard CLI tools have been replaced with alternatives:

- `ls` is aliased to `pls` - run `pls -h` to see example usages
- Outside an indexed project, where the hook above does not apply, use
  ripgrep (`rg`) instead of `grep`
