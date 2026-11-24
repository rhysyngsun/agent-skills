---
name: lean-ctx
description: Pick the right lean-ctx tool for reading, searching, understanding and running code with fewer tokens and fewer round trips. Use when lean-ctx MCP tools (ctx_*) are available or when a command output, file read or search would be large.
---

# lean-ctx

lean-ctx shapes context before it reaches you: cached reads, focused search, a
symbol index and a call graph over the current repo. Two rules beat every
detail:

1. **Fewer round trips beat smaller outputs.** One call that answers the
   question is cheaper than three small ones. Never add a call just to save a
   few hundred tokens.
2. **Never wait by polling.** Do not loop `sleep` + status checks.

## Loading the tools

These tools are deferred - the host lists them by name only. Load what the
task needs in **one** call:

    ToolSearch(query="select:mcp__plugin_claude-code-home-manager_lean-ctx__ctx_compose,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_search,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_read,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_callgraph")

The prefix is `mcp__plugin_claude-code-home-manager_lean-ctx__`. A bare
`mcp__lean-ctx__...` selector matches nothing.

## Start here - no built-in equivalent

| You want to... | Call |
| --- | --- |
| Understand how something works (unknown location) | `ctx_compose(task)` - ranked files + inline source in one call; use it FIRST instead of search -> read -> read |
| Find the exact definition of a symbol | `ctx_search(action="symbol", name=...)` |
| Find code by meaning | `ctx_search(action="semantic", query=...)` |
| Who calls X / what X calls | `ctx_callgraph(action="callers"\|"callees", symbol=...)` |
| A file's shape without its body | `ctx_read(path, mode="signatures"\|"map")` |

These four are the reason to reach for lean-ctx at all. Everything below
overlaps a built-in and is a judgement call.

## Overlaps a built-in

| You want to... | Call |
| --- | --- |
| Find a text/regex pattern | `ctx_search(pattern=..., path=...)`, or `Bash(rg ...)` for a known path |
| Read a file you will edit | `ctx_read(path, mode="anchored")`, then the native `Edit` tool |
| Read a range | `ctx_read(path, mode="lines:N-M")` |
| Re-check a file after editing | `ctx_read(path, mode="diff")` |
| List files / directory shape | `ctx_glob(pattern)` / `ctx_tree(path, depth)` |
| Remember across sessions | `ctx_session(action="finding"\|"decision"\|"task", value=...)`; durable project facts: `ctx_knowledge(action="remember", ...)` |

**Do not use `ctx_shell`.** Run commands with the native `Bash` tool. The
lean-ctx server is allowed whole-server here, so `ctx_shell` would bypass the
per-command `Bash(...)` permission gates - including the ones requiring
confirmation before a commit or a push. This deliberately contradicts the
server's own "Shell/bash -> ctx_shell" instruction.

Also do not read or search *through* a shell (`cat`, `sed -n`, `grep`): that
bypasses the read cache and the symbol index. Use `ctx_read` / `ctx_search`.

## Tools not in the list

The exposed surface is the `standard` profile (~19 tools). A tool named above
that your list lacks is still callable:

    ctx_call(name="ctx_knowledge", arguments={...})
    ctx_call(name="ctx_discover_tools", arguments={"query": "..."})

## Long-running commands

- Prefer the host's own background execution that notifies on completion:
  `Bash` with `run_in_background`, or `Monitor`. Start it, then continue other
  work or end the turn - you will be told when it finishes.
- Never `sleep` in a loop to poll for a result.

## Truncated output

Compressed or archived output ends with a recovery handle. Fetch only the
slice you need - `ctx_expand(id, search=... | head=N | json_path=...)`, or
`ctx_read(path, raw=true)` for exact bytes. Do not re-run the command.

## Configuration

This install is declarative, in `modules/programs/programs-ai-lean-ctx.nix` of
the nixos flake. Do **not** run `lean-ctx setup`, `lean-ctx bootstrap`,
`lean-ctx config set`, or any `curl | bash` installer: the config and this file
are read-only store symlinks, so those commands fail - and where they succeed
they leave untracked drift. Change the nix module and run `just switch-user`.
