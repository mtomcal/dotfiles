#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$TEST_DIR/.." && pwd)"

source "$TEST_DIR/lib/bash32.sh"

syntax_files=(
    "$TEST_DIR/run.sh"
    "$TEST_DIR/lib/harness.sh"
    "$TEST_DIR/lib/bash32.sh"
)

while IFS= read -r test_file; do
    syntax_files+=("$test_file")
done < <(find "$TEST_DIR" -maxdepth 1 -name '*.test.sh' -type f | sort)

printf 'Checking shell syntax...\n'
bash -n "${syntax_files[@]}"

printf 'Checking Bash 3.2 source compatibility...\n'
if ! bash32_violations "$DOTFILES_ROOT/install.sh" "${syntax_files[@]}"; then
    printf 'Post-Bash-3.2 constructs are not allowed; macOS ships Bash 3.2.\n' >&2
    exit 1
fi

test_files=()
while IFS= read -r test_file; do
    test_files+=("$test_file")
done < <(find "$TEST_DIR" -maxdepth 1 -name '*.test.sh' -type f | sort)

if [[ ${#test_files[@]} -eq 0 ]]; then
    echo "No shell tests found in $TEST_DIR"
    exit 0
fi

passed=0

for test_file in "${test_files[@]}"; do
    printf '\n==> %s\n' "${test_file#$TEST_DIR/}"
    bash "$test_file"
    passed=$((passed + 1))
done

printf '\nShell test suite passed (%d files) on Bash %s\n' "$passed" "${BASH_VERSION}"
printf 'Platform compatibility: the Bash 3.2 check above is STATIC only.\n'
printf 'Running this suite on macOS with /bin/bash 3.2 remains a separate,\n'
printf 'unautomated gate; nothing here proves Bash 3.2 runtime behavior.\n'
