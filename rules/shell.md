# Scripts and shell

- Every script you write starts with `set -euo pipefail`.
- No hardcoded `/tmp` paths. Use `mktemp -d`, or the session scratchpad
  directory when one is provided. A fixed path under `/tmp` survives a
  reboot, so the next run reads a stale file and believes it is fresh.
- Put anything beyond a single pipeline in a script file rather than
  inlining it, so it can be read and re-run.
- Pass filenames as `-- <name>` or `./<name>` so one beginning with `-`
  is not parsed as a flag.
- A pipeline that exits 0 because nothing matched is not a pipeline that
  passed. Distinguish the two explicitly in any guard, and watch for
  SIGPIPE closing a pipe early under `pipefail`.
- Run the script yourself once before calling it done. If it writes or
  deletes anything, give it a `--dry-run` and run that first.
