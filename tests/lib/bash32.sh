#!/usr/bin/env bash
#
# Static guard for shell constructs that do not exist in Bash 3.2, the system
# shell on macOS. This is a source-level check only: it CANNOT prove runtime
# compatibility. Real Bash 3.2 / macOS execution remains a separate gate.

# Each entry is "description|extended-regex". A source line may opt out of the
# guard by carrying the literal marker "bash32-guard: allow" — used by this
# table and by the guard's own test fixtures.
BASH32_ALLOW_MARKER='bash32-guard: allow'

BASH32_FORBIDDEN=(
    'associative array declaration|(declare|typeset|local)[[:space:]]+-[A-Za-z]*A[A-Za-z]*[[:space:]]'  # bash32-guard: allow
    'mapfile builtin|(^|[^[:alnum:]_])mapfile([^[:alnum:]_]|$)'  # bash32-guard: allow
    'readarray builtin|(^|[^[:alnum:]_])readarray([^[:alnum:]_]|$)'  # bash32-guard: allow
    'case modification expansion|\$\{[A-Za-z_][A-Za-z_0-9]*(\[[^]]*\])?(\^\^?|,,?)'  # bash32-guard: allow
    'case fallthrough ;;&|;;&'  # bash32-guard: allow
    'case fallthrough ;&|[^;];&[[:space:]]*$'  # bash32-guard: allow
    'coproc keyword|(^|[^[:alnum:]_])coproc([^[:alnum:]_]|$)'  # bash32-guard: allow
    'append-both-streams &>>|&>>'  # bash32-guard: allow
    'test -v|\[\[[[:space:]]+-v[[:space:]]'  # bash32-guard: allow
    'negative array index|\$\{[A-Za-z_][A-Za-z_0-9]*\[-[0-9]'  # bash32-guard: allow
)

# Print "file:line: description" for every post-3.2 construct found in the
# given files. Returns non-zero when any violation was printed.
bash32_violations() {
    local file
    local entry
    local description
    local pattern
    local hits
    local found=1

    for file in "$@"; do
        [ -f "$file" ] || continue
        for entry in "${BASH32_FORBIDDEN[@]}"; do
            description="${entry%%|*}"
            pattern="${entry#*|}"
            hits="$(grep -nE "$pattern" "$file" | grep -Fv "$BASH32_ALLOW_MARKER" || true)"
            if [ -n "$hits" ]; then
                printf '%s\n' "$hits" | while IFS= read -r hit; do
                    printf '%s:%s: %s\n' "$file" "${hit%%:*}" "$description"
                done
                found=0
            fi
        done
    done

    return $((1 - found))
}
