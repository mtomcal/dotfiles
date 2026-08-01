#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

VSCODE_DIR="$DOTFILES_DIR/vscode"
SETTINGS="$VSCODE_DIR/settings.json"
KEYBINDINGS="$VSCODE_DIR/keybindings.json"
SNIPPETS_DIR="$VSCODE_DIR/snippets"
EXTENSIONS_DIR="$VSCODE_DIR/extensions"

# --- managed-data helpers -----------------------------------------------------

# Every path inside the managed settings document, rendered as the dotted
# setting identity VS Code uses regardless of flat or nested authoring.
settings_paths() {
    jq -r '[paths] | map(map(tostring) | join(".")) | .[]' "$SETTINGS"
}

settings_string_values() {
    jq -r '[.. | strings] | .[]' "$SETTINGS"
}

assert_json_value() {
    local filter="$1"
    local expected="$2"
    local label="$3"
    local actual

    actual="$(jq -c "$filter" "$SETTINGS")" || fail "$label: jq filter failed: $filter"
    [[ "$actual" == "$expected" ]] || fail "$label: expected $expected, got $actual"
}

assert_set_equal() {
    local label="$1"
    local actual="$2"
    local expected="$3"
    local diff_out

    if ! diff_out="$(diff <(printf '%s\n' "$actual" | sort) <(printf '%s\n' "$expected" | sort))"; then
        fail "$label mismatch (< actual, > expected):
$diff_out"
    fi
}

# --- Cycle A: language, formatter, and tooling-boundary contracts -------------

test_settings_is_strict_json_object() {
    [[ -f "$SETTINGS" ]] || fail "missing managed settings source: $SETTINGS"
    jq -e . "$SETTINGS" >/dev/null || fail "settings.json is not strict JSON"
    assert_json_value 'type' '"object"' 'settings root'
}

test_python_analysis_uses_basic_open_file_diagnostics_on_both_targets() {
    assert_json_value '."python.analysis.typeCheckingMode"' '"basic"' 'Pylance type checking'
    assert_json_value '."python.analysis.diagnosticMode"' '"openFilesOnly"' 'Pylance diagnostic mode'
    assert_json_value '."basedpyright.analysis.typeCheckingMode"' '"basic"' 'BasedPyright type checking'
    assert_json_value '."basedpyright.analysis.diagnosticMode"' '"openFilesOnly"' 'BasedPyright diagnostic mode'
}

test_python_files_lint_and_format_through_ruff() {
    assert_json_value '."[python]"."editor.defaultFormatter"' '"charliermarsh.ruff"' 'Python formatter'
    assert_json_value '."[python]"."editor.formatOnSave"' 'true' 'Python format on save'
    assert_json_value '."[python]"."editor.codeActionsOnSave"."source.fixAll.ruff"' '"explicit"' 'Ruff fix action'
    assert_json_value '."[python]"."editor.codeActionsOnSave"."source.organizeImports.ruff"' '"explicit"' 'Ruff import action'
}

test_language_formatter_mappings_are_exactly_the_managed_set() {
    local actual expected
    actual="$(jq -r 'to_entries | map(select(.key | startswith("["))) | map("\(.key)=\(.value."editor.defaultFormatter")") | .[]' "$SETTINGS")"
    expected='[python]=charliermarsh.ruff
[javascript]=esbenp.prettier-vscode
[javascriptreact]=esbenp.prettier-vscode
[typescript]=esbenp.prettier-vscode
[typescriptreact]=esbenp.prettier-vscode
[json]=esbenp.prettier-vscode
[jsonc]=esbenp.prettier-vscode
[css]=esbenp.prettier-vscode
[html]=esbenp.prettier-vscode
[markdown]=esbenp.prettier-vscode
[yaml]=esbenp.prettier-vscode'
    assert_set_equal 'language formatter mappings' "$actual" "$expected"
}

test_prettier_formats_only_projects_that_configure_it() {
    assert_json_value '."editor.formatOnSave"' 'true' 'format on save'
    assert_json_value '."prettier.requireConfig"' 'true' 'Prettier project-config requirement'
}

test_eslint_supplies_safe_fixes_without_competing_as_a_formatter() {
    assert_json_value '."eslint.format.enable"' 'false' 'ESLint formatter competition'
    assert_json_value '."editor.codeActionsOnSave"."source.fixAll.eslint"' '"explicit"' 'ESLint safe fix action'
}

test_settings_declare_no_global_project_tool_paths() {
    local prohibited=(
        prettier.prettierPath
        prettier.configPath
        prettier.resolveGlobalModules
        eslint.nodePath
        eslint.runtime
        eslint.options.overrideConfigFile
        eslint.options.resolvePluginsRelativeTo
        typescript.tsdk
        python.defaultInterpreterPath
        python.pythonPath
        python.testing.pytestPath
        ruff.path
        ruff.interpreter
        ruff.importStrategy
    )
    local paths key
    paths="$(settings_paths)"

    for key in "${prohibited[@]}"; do
        if printf '%s\n' "$paths" | grep -Fxq "$key"; then
            fail "managed settings must not override the project tool path '$key'"
        fi
    done
}

test_settings_select_no_global_test_framework() {
    local paths
    paths="$(settings_paths)"

    if printf '%s\n' "$paths" | grep -Eq '^python\.testing\.(pytest|unittest)Enabled$'; then
        fail "managed settings must not globally force a Python test framework"
    fi
    if printf '%s\n' "$paths" | grep -Eq '^(jest|vitest|playwright)\.'; then
        fail "managed settings must not select a global JavaScript test adapter"
    fi
}

test_settings_contain_no_machine_specific_paths() {
    local value
    while IFS= read -r value; do
        [[ -n "$value" ]] || continue
        if [[ "$value" =~ ^(/home/|/Users/|/usr/|/opt/|/private/|~/|[A-Za-z]:\\\\) ]]; then
            fail "managed settings contain a machine-specific path: $value"
        fi
    done < <(settings_string_values)
}

# --- Cycle B: VSCodeVim options, leader map, and native exceptions -----------

# The one native shortcut the managed layer hands back to the editor/browser.
NATIVE_EXCEPTION_KEY='<C-f>'
NATIVE_EXCEPTION_BINDING='ctrl+f=actions.find'

# Every managed Space-led sequence paired with the stable VS Code command it
# must invoke. Written as "sequence=command" with sequence keys joined by "+".
managed_leader_map() {
    cat <<'EOF'
 +f=editor.action.formatDocument
 +d+n=editor.action.marker.next
 +d+p=editor.action.marker.prev
 +d+l=workbench.actions.view.problems
 +e=workbench.view.explorer
 +o=workbench.action.quickOpen
 +g+g=workbench.view.scm
 +t+t=testing.runAtCursor
 +t+f=testing.runCurrentFile
 +b+b=editor.debug.action.toggleBreakpoint
 +b+s=workbench.action.debug.start
 +b+c=workbench.action.debug.continue
EOF
}

test_vim_core_options_are_exact() {
    assert_json_value '."vim.leader"' '" "' 'Vim leader'
    assert_json_value '."vim.useSystemClipboard"' 'true' 'Vim system clipboard'
    assert_json_value '."vim.incsearch"' 'true' 'Vim incremental search'
    assert_json_value '."vim.hlsearch"' 'true' 'Vim search highlighting'
    assert_json_value '."vim.surround"' 'true' 'Vim surround'
    assert_json_value '."vim.easymotion"' 'true' 'Vim EasyMotion'
    assert_json_value '."vim.vimrc.enable"' 'false' 'Vim vimrc loading'
    assert_json_value '."editor.lineNumbers"' '"relative"' 'relative line numbers'
}

test_managed_layer_does_not_couple_vscodevim_to_neovim() {
    local paths
    paths="$(settings_paths)"

    if printf '%s\n' "$paths" | grep -Eq '^vim\.(enableNeovim|neovimPath|neovimUseConfigFile|neovimConfigPath)$'; then
        fail "managed settings must not couple VSCodeVim to an embedded Neovim"
    fi
}

test_vim_leader_map_is_exactly_the_managed_command_set() {
    local actual expected
    actual="$(jq -r '.["vim.normalModeKeyBindingsNonRecursive"] | map("\(.before | join("+"))=\(.commands | join(","))") | .[]' "$SETTINGS")"
    expected="$(managed_leader_map)"
    assert_set_equal 'Vim leader map' "$actual" "$expected"
}

test_vim_leader_map_entries_are_well_formed_and_space_led() {
    local count entry

    count="$(jq -r '.["vim.normalModeKeyBindingsNonRecursive"] | length' "$SETTINGS")"
    [[ "$count" -eq "$(managed_leader_map | wc -l)" ]] ||
        fail "leader map contains $count entries; expected $(managed_leader_map | wc -l) with no duplicates or extras"

    # Every mapping must begin with the Space leader, invoke exactly one
    # command, and carry no keys other than 'before' and 'commands'.
    while IFS= read -r entry; do
        [[ "$entry" == "ok" ]] || fail "malformed leader mapping: $entry"
    done < <(jq -r '.["vim.normalModeKeyBindingsNonRecursive"][] |
        if (.before[0] != " ") then "not space-led: \(.before | tostring)"
        elif ((.before | length) < 2) then "leader with no sequence: \(.before | tostring)"
        elif ((.commands | length) != 1) then "not exactly one command: \(.commands | tostring)"
        elif ((keys_unsorted | sort) != ["before", "commands"]) then "unexpected fields: \(keys_unsorted | tostring)"
        else "ok" end' "$SETTINGS")

    # No managed sequence may shadow another by being its prefix.
    local sequences a b
    sequences="$(managed_leader_map | cut -d= -f1)"
    while IFS= read -r a; do
        while IFS= read -r b; do
            [[ "$a" == "$b" ]] && continue
            [[ "$b" == "$a"+* ]] && fail "leader sequence '$a' shadows '$b'"
        done <<<"$sequences"
    done <<<"$sequences"
    return 0
}

test_native_shortcut_exception_is_exactly_the_managed_exclusion() {
    local actual
    actual="$(jq -c '."vim.handleKeys"' "$SETTINGS")"
    [[ "$actual" == "{\"$NATIVE_EXCEPTION_KEY\":false}" ]] ||
        fail "vim.handleKeys must exclude exactly $NATIVE_EXCEPTION_KEY from Vim handling, got $actual"
}

test_keybindings_is_a_strict_json_array_of_plain_bindings() {
    [[ -f "$KEYBINDINGS" ]] || fail "missing managed keybindings source: $KEYBINDINGS"
    jq -e . "$KEYBINDINGS" >/dev/null || fail "keybindings.json is not strict JSON"

    local root entry
    root="$(jq -r 'type' "$KEYBINDINGS")"
    [[ "$root" == "array" ]] || fail "keybindings root must be an array, got $root"

    while IFS= read -r entry; do
        [[ "$entry" == "ok" ]] || fail "malformed keybinding: $entry"
    done < <(jq -r '.[] |
        if (type != "object") then "not an object: \(tostring)"
        elif ((keys_unsorted | sort) != ["command", "key"]) then "unexpected fields: \(keys_unsorted | tostring)"
        else "ok" end' "$KEYBINDINGS")
}

test_keybindings_contain_exactly_the_required_native_exceptions() {
    local actual count
    actual="$(jq -r '.[] | "\(.key)=\(.command)"' "$KEYBINDINGS")"
    assert_set_equal 'native keybindings' "$actual" "$NATIVE_EXCEPTION_BINDING"

    count="$(jq -r 'length' "$KEYBINDINGS")"
    [[ "$count" -eq 1 ]] || fail "keybindings must contain exactly 1 native exception, found $count"
}

test_native_exception_and_vim_exclusion_stay_coordinated() {
    local excluded bound
    excluded="$(jq -r '."vim.handleKeys" | to_entries | map(select(.value == false) | .key) | .[]' "$SETTINGS")"
    bound="$(jq -r '.[].key' "$KEYBINDINGS")"

    # '<C-f>' in VSCodeVim notation is 'ctrl+f' in VS Code keybinding notation.
    local translated
    translated="$(printf '%s\n' "$excluded" | sed -e 's/^<C-\(.\)>$/ctrl+\1/')"
    assert_set_equal 'native exception coordination' "$translated" "$bound"
}

test_keybindings_do_not_duplicate_the_vim_leader_map() {
    local commands managed key command

    commands="$(jq -r '.[].command' "$KEYBINDINGS")"
    managed="$(managed_leader_map | cut -d= -f2-)"
    while IFS= read -r command; do
        if printf '%s\n' "$managed" | grep -Fxq "$command"; then
            fail "keybindings.json duplicates managed leader command: $command"
        fi
    done <<<"$commands"

    while IFS= read -r key; do
        if [[ "$key" == *space* ]]; then
            fail "keybindings.json must not restate the Space leader map: $key"
        fi
    done < <(jq -r '.[].key' "$KEYBINDINGS")
}

# --- Cycle C: snippets unit, exact catalogs, and prohibited content ----------

# A manifest entry is an identity; blank lines and full-line comments are
# organizational only and never resolve to an extension.
parse_extension_catalog() {
    sed -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' "$1" |
        grep -Ev '^(#.*)?$'
}

# Paths that would put mutable editor state, machine identity, or secret
# material under repository ownership.
MUTABLE_STATE_PATTERNS=(
    '(^|/)User(/|$)'
    '(^|/)Machine(/|$)'
    'globalStorage'
    'workspaceStorage'
    '(^|/)History(/|$)'
    '(^|/)profiles(/|$)'
    '(^|/)sync(/|$)'
    '(^|/)argv\.json$'
    '\.vscdb'
    '(^|/)storage\.json$'
    'machineid'
    '\.vsix$'
    '\.log$'
    '(^|/)auth\.json$'
    '(^|/)\.env(\..*)?$'
    '\.(pem|key|pfx|p12)$'
    'id_(rsa|ed25519)'
)

# Credential material, as opposed to security vocabulary. Each pattern
# requires an actual secret value, not merely a secret-sounding word.
CREDENTIAL_PATTERNS=(
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    '(bearer|basic)[[:space:]]+[A-Za-z0-9._~+/=-]{16,}'
    'gh[pousr]_[A-Za-z0-9]{20,}'
    'sk-[A-Za-z0-9]{20,}'
    'AKIA[0-9A-Z]{16}'
    # A secret-sounding name assigned to a literal value. The value must be a
    # bare literal that terminates without further expression syntax, so that
    # code such as `const token = lexer.nextToken();` is not mistaken for a
    # secret while `AUTH_TOKEN=abc123` is.
    '(api[_-]?key|secret|password|passwd|token|credential|authorization|access[_-]?key)"?'"'"'?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9._~+/=-]{6,}([[:space:]]*$|["'"'"',;}]|\])'
)

contains_credential_material() {
    local file="$1"
    local pattern

    for pattern in "${CREDENTIAL_PATTERNS[@]}"; do
        if grep -Eqi -- "$pattern" "$file"; then
            return 0
        fi
    done
    return 1
}

# Everything the repository would own under vscode/, including sources that are
# staged for a first commit but not yet tracked.
managed_tracked_files() {
    git -C "$DOTFILES_DIR" ls-files --cached --others --exclude-standard -- vscode
}

test_snippets_is_a_tracked_target_neutral_managed_unit() {
    [[ -d "$SNIPPETS_DIR" ]] || fail "missing managed snippets directory: $SNIPPETS_DIR"

    local tracked
    tracked="$(managed_tracked_files | grep '^vscode/snippets/' || true)"
    [[ -n "$tracked" ]] || fail "vscode/snippets/ must contain at least one tracked file"

    local file
    while IFS= read -r file; do
        case "$file" in
            *.json | *.code-snippets)
                jq -e . "$DOTFILES_DIR/$file" >/dev/null ||
                    fail "snippet source is not strict JSON: $file"
                ;;
        esac
    done <<<"$tracked"
}

test_tracked_managed_layer_excludes_mutable_editor_state() {
    local file pattern
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        for pattern in "${MUTABLE_STATE_PATTERNS[@]}"; do
            if printf '%s\n' "$file" | grep -Eq -- "$pattern"; then
                fail "managed layer must not track mutable editor state: $file (matched /$pattern/)"
            fi
        done
    done < <(managed_tracked_files)
}

test_credential_detector_separates_real_material_from_security_vocabulary() {
    local tmp
    tmp="$(new_tmp)"

    local benign=(
        'const token = lexer.nextToken();'
        '// Security note: rotate the access token when the session expires'
        '# Never commit credentials or API keys to this repository.'
        '"authorization": "$AUTH_HEADER"'
        '"body": ["password = ${1:placeholder}"]'
        '"prefix": "tokenize"'
        '"description": "Insert a secret-scanning ignore comment"'
        '{"Read token":{"prefix":"tok","body":["const token = lexer.nextToken();"]}}'
        '{"Auth doc":{"prefix":"doc","body":["// send the API key in the authorization header"]}}'
    )
    local malicious=(
        'AUTH_TOKEN=abc123'
        '"password": "hunter2secret"'
        '-----BEGIN RSA PRIVATE KEY-----'
        'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        'aws_access_key_id = AKIAIOSFODNN7EXAMPLE'
        'export GITHUB_TOKEN=ghp_0123456789abcdefghijABCDEFGHIJ'
        '{"Leak":{"prefix":"p","body":["AUTH_TOKEN=abc123"]}}'
        '{"Leak":{"prefix":"p","body":["password: hunter2secret"]}}'
    )

    local line
    for line in "${benign[@]}"; do
        printf '%s\n' "$line" >"$tmp/fixture"
        if contains_credential_material "$tmp/fixture"; then
            fail "credential scan false-positives on benign security vocabulary: $line"
        fi
    done
    for line in "${malicious[@]}"; do
        printf '%s\n' "$line" >"$tmp/fixture"
        if ! contains_credential_material "$tmp/fixture"; then
            fail "credential scan missed real credential material: $line"
        fi
    done
}

test_tracked_managed_sources_contain_no_credential_material() {
    local file
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        if contains_credential_material "$DOTFILES_DIR/$file"; then
            fail "managed source contains credential material: $file"
        fi
    done < <(managed_tracked_files)
}

test_tracked_managed_sources_contain_no_machine_specific_paths() {
    local file
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        if grep -Eq '(/home/[a-z]|/Users/[a-zA-Z]|[A-Za-z]:\\Users\\)' "$DOTFILES_DIR/$file"; then
            fail "managed source contains a machine-specific path: $file"
        fi
    done < <(managed_tracked_files)
}

test_tracked_managed_sources_name_no_private_network_product() {
    local file
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        if grep -Eqi 'tailscale|zerotier|wireguard|ngrok|cloudflare' "$DOTFILES_DIR/$file"; then
            fail "managed source names a private-network product: $file"
        fi
    done < <(managed_tracked_files)
}

test_shared_extension_catalog_membership_is_exact() {
    local expected='EditorConfig.EditorConfig
charliermarsh.ruff
dbaeumer.vscode-eslint
esbenp.prettier-vscode
vscodevim.vim'
    [[ -f "$EXTENSIONS_DIR/shared.txt" ]] || fail "missing shared extension manifest"
    assert_set_equal 'shared catalog' "$(parse_extension_catalog "$EXTENSIONS_DIR/shared.txt")" "$expected"
}

test_desktop_extension_catalog_membership_is_exact() {
    local expected='ms-python.python
ms-python.vscode-pylance
ms-python.debugpy
ms-python.vscode-python-envs
ms-vscode-remote.remote-ssh'
    [[ -f "$EXTENSIONS_DIR/desktop.txt" ]] || fail "missing desktop extension manifest"
    assert_set_equal 'desktop catalog' "$(parse_extension_catalog "$EXTENSIONS_DIR/desktop.txt")" "$expected"
}

test_code_server_extension_catalog_membership_is_exact() {
    local expected='ms-python.python
detachhead.basedpyright
ms-python.debugpy'
    [[ -f "$EXTENSIONS_DIR/code-server.txt" ]] || fail "missing code-server extension manifest"
    assert_set_equal 'code-server catalog' "$(parse_extension_catalog "$EXTENSIONS_DIR/code-server.txt")" "$expected"
}

test_extension_catalog_parser_ignores_comments_and_blank_lines() {
    local tmp
    tmp="$(new_tmp)"
    printf '%s\n' \
        '# Python support' \
        '' \
        '  ms-python.python  ' \
        '   # indented comment' \
        '' \
        'ms-python.debugpy' >"$tmp/fixture.txt"

    assert_set_equal 'catalog comment handling' \
        "$(parse_extension_catalog "$tmp/fixture.txt")" \
        'ms-python.python
ms-python.debugpy'
}

test_extension_catalog_entries_are_unpinned_publisher_names() {
    local manifest entry
    for manifest in shared desktop code-server; do
        while IFS= read -r entry; do
            [[ -n "$entry" ]] || continue
            [[ "$entry" != *@* ]] ||
                fail "$manifest.txt pins a version by default: $entry"
            [[ "$entry" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*\.[A-Za-z0-9][A-Za-z0-9_-]*$ ]] ||
                fail "$manifest.txt entry is not publisher.name form: $entry"
        done < <(parse_extension_catalog "$EXTENSIONS_DIR/$manifest.txt")
    done
}

test_extension_catalogs_exclude_embedded_neovim() {
    local manifest entry
    for manifest in shared desktop code-server; do
        while IFS= read -r entry; do
            if printf '%s\n' "$entry" | grep -Eqi 'neovim|nvim'; then
                fail "$manifest.txt must not include an embedded-Neovim extension: $entry"
            fi
        done < <(parse_extension_catalog "$EXTENSIONS_DIR/$manifest.txt")
    done
}

test_vscodevim_is_shared_by_both_editor_targets() {
    parse_extension_catalog "$EXTENSIONS_DIR/shared.txt" | grep -Fxq 'vscodevim.vim' ||
        fail "VSCodeVim must be a shared managed extension"
}

run_tests "vscode managed layer"
