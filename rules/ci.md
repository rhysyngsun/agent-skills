# Hooks, guards and CI checks

- After adding or changing a hook, lint rule, guard or test, prove it
  fires: introduce a deliberate violation, run it, confirm it fails,
  then revert. A green run on an unchanged tree is not evidence the
  check works - it is equally consistent with the check matching
  nothing.
- Never add an exclude or ignore pattern to a secrets scanner or a
  linter without telling me which paths it now skips and why.
