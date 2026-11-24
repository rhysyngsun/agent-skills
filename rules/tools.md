# Code navigation

In a lean-ctx-indexed project, `Grep`, `Glob` and a bare `rg`/`grep`/`find`
are **blocked by a hook** - route code search through lean-ctx instead. The
tools are deferred, so load them in one call first:

    ToolSearch(query="select:mcp__plugin_claude-code-home-manager_lean-ctx__ctx_compose,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_search,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_glob,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_read")

Then:

- `ctx_search(action="regex", pattern=..., path=...)` - replaces `Grep`. Ranked,
  compressed matches with enclosing-symbol annotations, and it skips credential
  files by boundary policy rather than reading them.
- `ctx_glob(pattern=...)` - replaces `Glob`.
- `ctx_compose(task=...)` - ranked files plus inline source for one question, in
  one call. Best first move in unfamiliar code.
- `ctx_read(mode="signatures"|"map")` - a file's shape without its body.

Needs a tree-sitter grammar, so useless where files index as `Kind: text`
(every `.nix` file, for one - check `lean-ctx index status`):

- `ctx_search(action="symbol")` - exact definition
- `ctx_callgraph` - callers and callees

Searching *outside* the project - `/nix/store`, a vendored source tree, `/etc` -
is not blocked; use `rg` there as normal. If you genuinely need raw search inside
the project (binary files, a regex `ctx_search` cannot express), append
` # lean-ctx:bypass` to the shell command.

Keep using `Bash` for running commands - not `ctx_shell`. The lean-ctx
server is allowed whole-server, so routing commands through `ctx_shell`
would sidestep the per-command `Bash(...)` permission gates.

# CLI tools

Rules:

- You may execute read-only operations of CLI tools

Some standard CLI tools have been replaced with alternatives:

- `ls` is aliased to `pls` - run `pls -h` to see example usages
- Use ripgrep (`rg`) instead of `grep`, for known paths and one-off greps
