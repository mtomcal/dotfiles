#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

syntax_files=(
    "$TEST_DIR/run.sh"
    "$TEST_DIR/lib/harness.sh"
)

while IFS= read -r test_file; do
    syntax_files+=("$test_file")
done < <(find "$TEST_DIR" -maxdepth 1 -name '*.test.sh' -type f | sort)

printf 'Checking shell syntax...\n'
bash -n "${syntax_files[@]}"

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

printf '\nShell test suite passed (%d files)\n' "$passed"
