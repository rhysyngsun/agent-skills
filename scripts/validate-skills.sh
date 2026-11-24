#!/usr/bin/env bash
# Validate every skill directory against the Agent Skills specification.
# https://agentskills.io/specification
#
# Two layers, because they fail differently:
#   1. Local checks, always run, no network. These catch the mistakes that are
#      actually made here - a renamed directory whose frontmatter `name` was not
#      renamed with it, a `skill.md` that should be `SKILL.md`.
#   2. `agentskills validate` from the reference library, which is the authority
#      on the spec and rejects frontmatter fields the local checks do not know
#      about. Skipped with a loud warning when uvx is unavailable, so a cold
#      offline checkout still gets layer 1.
#
# Usage: scripts/validate-skills.sh [skill-dir ...]
#        with no arguments, every directory under skills/ is checked.
set -euo pipefail

SKILLS_REF_VERSION="0.1.1"
MAX_NAME=64
MAX_DESCRIPTION=1024

repo_root=$(git rev-parse --show-toplevel)
cd -- "$repo_root"

failures=0

fail() {
  printf '  FAIL  %s\n' "$1" >&2
  failures=$((failures + 1))
}

# Read one top-level scalar out of the YAML frontmatter block. Deliberately not
# a YAML parser: the spec allows `name` and `description` to be folded scalars
# (`description: >`), so a continuation line indented under the key is joined
# onto the value and anything else at column 0 ends it.
frontmatter_field() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit 1 }
    NR == 1 { next }
    $0 == "---" { exit }
    {
      if ($0 ~ "^" key ":") {
        sub("^" key ":[[:space:]]*", "")
        if ($0 == ">" || $0 == "|" || $0 == ">-" || $0 == "|-") { value = "" }
        else { value = $0 }
        collecting = 1
        next
      }
      if (collecting) {
        if ($0 ~ /^[[:space:]]/) {
          line = $0
          sub(/^[[:space:]]+/, "", line)
          value = (value == "" ? line : value " " line)
          next
        }
        collecting = 0
      }
    }
    END { print value }
  ' "$1"
}

check_skill() {
  local dir="$1"
  local name_expected skill_md name description
  local -a misspelled

  dir="${dir%/}"
  # awk has no `--`, so a path is kept un-dashed by construction instead.
  case "$dir" in /* | ./*) ;; *) dir="./$dir" ;; esac
  name_expected=$(basename -- "$dir")
  skill_md="$dir/SKILL.md"

  printf 'skills/%s\n' "$name_expected"

  if [ ! -f "$skill_md" ]; then
    # Catch the lowercase spelling explicitly - it is the common mistake, and
    # "SKILL.md is missing" is a confusing thing to read next to a skill.md.
    shopt -s nullglob
    misspelled=("$dir"/[Ss][Kk][Ii][Ll][Ll].md)
    shopt -u nullglob
    if [ "${#misspelled[@]}" -gt 0 ]; then
      fail "SKILL.md must be spelled in uppercase, found ${misspelled[0]}"
    else
      fail "no SKILL.md"
    fi
    return
  fi

  if ! name=$(frontmatter_field "$skill_md" name); then
    fail "SKILL.md does not start with a --- frontmatter block"
    return
  fi
  description=$(frontmatter_field "$skill_md" description)

  if [ -z "$name" ]; then
    fail "frontmatter has no name"
  else
    if [ "$name" != "$name_expected" ]; then
      fail "frontmatter name '$name' does not match directory name '$name_expected'"
    fi
    if [ "${#name}" -gt "$MAX_NAME" ]; then
      fail "name is ${#name} characters, max is $MAX_NAME"
    fi
    if ! printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
      fail "name '$name' is not lowercase alphanumeric with single internal hyphens"
    fi
  fi

  if [ -z "$description" ]; then
    fail "frontmatter has no description"
  elif [ "${#description}" -gt "$MAX_DESCRIPTION" ]; then
    fail "description is ${#description} characters, max is $MAX_DESCRIPTION"
  fi
}

targets=("$@")
if [ "${#targets[@]}" -eq 0 ]; then
  # A skills/ directory with nothing in it is a broken checkout, not a pass.
  shopt -s nullglob
  targets=(skills/*/)
  shopt -u nullglob
  if [ "${#targets[@]}" -eq 0 ]; then
    printf 'no skill directories found under skills/\n' >&2
    exit 1
  fi
fi

for target in "${targets[@]}"; do
  check_skill "$target"
done

if command -v uvx >/dev/null 2>&1; then
  for target in "${targets[@]}"; do
    if ! uvx --quiet --from "skills-ref==$SKILLS_REF_VERSION" agentskills validate "${target%/}"; then
      fail "agentskills validate rejected ${target%/}"
    fi
  done
else
  printf 'WARNING: uvx not found, skipped the skills-ref spec validation\n' >&2
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d check(s) failed\n' "$failures" >&2
  exit 1
fi

printf '\nall skills valid\n'
