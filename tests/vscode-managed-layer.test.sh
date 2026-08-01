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
    'settingsSync'
    '[Cc]ache'
    '(^|/)state(/|$)'
    '\.vsix$'
    '\.log$'
    '(^|/)auth\.json$'
    '(^|/)\.env(\..*)?$'
    '\.(pem|key|pfx|p12)$'
    'id_(rsa|ed25519)'
)

# Signatures that are credential material on sight, independent of naming.
CREDENTIAL_SIGNATURES=(
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    '(bearer|basic)[[:space:]]+[A-Za-z0-9._~+/=-]{16,}'
    'gh[pousr]_[A-Za-z0-9]{20,}'
    'sk-[A-Za-z0-9]{20,}'
    'AKIA[0-9A-Z]{16}'
    # Credentials embedded in a URL, e.g. https://admin:s3cr3t@host/
    '://[^/[:space:]@"]+:[^/[:space:]@"]+@'
)

# Names that introduce a secret when they are assigned a literal value.
SECRET_NAME='(api[_-]?key|secret|password|passwd|token|credential|authorization|access[_-]?key)'

# Distinguishes a literal secret from an identifier or a reference. Real
# secrets carry entropy markers -- a digit, strong punctuation, or unusual
# length -- while `lexer.nextToken()`, `buildAuth(user)`, `$AUTH_HEADER`, and
# `${1:placeholder}` do not.
value_is_secret_like() {
    local value="$1"
    local quoted="$2"

    [[ ${#value} -ge 6 ]] || return 1
    # Environment-variable and snippet-placeholder references are not literals.
    case "$value" in
        '$'* | '%'* | *'${'*) return 1 ;;
        *'('*) return 1 ;;      # a call expression, not a literal
        *'<'* | *'>'*) return 1 ;; # a documentation placeholder such as <token>
    esac

    # A quoted literal assigned to a secret name is a secret, including
    # passphrases that contain spaces.
    [[ "$quoted" == "quoted" ]] && return 0

    # Unquoted prose is not a credential, so a multi-word bare value must carry
    # an entropy marker before it counts.
    if [[ "$value" =~ [[:space:]] ]]; then
        [[ "$value" =~ [0-9] ]] && return 0
        [[ "$value" =~ [\&\!\#\%\^\*\?\@\|\+/=] ]] && return 0
        return 1
    fi

    [[ ${#value} -ge 20 ]] && return 0
    [[ "$value" =~ [0-9] ]] && return 0
    [[ "$value" =~ [\&\!\#\%\^\*\?\@\|\+/=] ]] && return 0
    return 1
}

# Structural companion to the textual scan: a JSON member whose key names a
# secret and whose value is a literal string is a credential regardless of the
# value's entropy.
json_declares_secret_literal() {
    local file="$1"

    jq -e --arg re "^${SECRET_NAME}$" '
        [paths(scalars) as $p | {k: ($p[-1] | tostring), v: getpath($p)}]
        | map(select(
            (.k | ascii_downcase | test($re))
            and (.v | type == "string")
            and (.v | length > 0)
            and ((.v | startswith("$")) | not)))
        | length > 0' "$file" >/dev/null 2>&1
}

contains_credential_material() {
    local file="$1"
    local pattern candidate value quoted scan

    case "$file" in
        *.json | *.code-snippets)
            if json_declares_secret_literal "$file"; then
                return 0
            fi
            # Scan the decoded string contents as well: a secret written inside
            # a JSON string arrives escaped, so the raw bytes alone hide it.
            scan="$(mktemp "$SUITE_TMP_ROOT/credscan.XXXXXX")"
            cat "$file" >"$scan"
            jq -r '[.. | strings] | .[]' "$file" >>"$scan" 2>/dev/null || true
            ;;
        *)
            scan="$file"
            ;;
    esac

    for pattern in "${CREDENTIAL_SIGNATURES[@]}"; do
        if grep -Eqi -- "$pattern" "$scan"; then
            [[ "$scan" != "$file" ]] && rm -f "$scan"
            return 0
        fi
    done

    while IFS= read -r candidate; do
        [[ -n "$candidate" ]] || continue
        value="${candidate#*[:=]}"
        # Trim surrounding whitespace, then a matched pair of quotes.
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        quoted="bare"
        if [[ ${#value} -ge 2 && "${value:0:1}" == "\"" && "${value: -1}" == "\"" ]]; then
            value="${value:1:${#value}-2}"
            quoted="quoted"
        elif [[ ${#value} -ge 2 && "${value:0:1}" == "'" && "${value: -1}" == "'" ]]; then
            value="${value:1:${#value}-2}"
            quoted="quoted"
        fi
        if value_is_secret_like "$value" "$quoted"; then
            [[ "$scan" != "$file" ]] && rm -f "$scan"
            return 0
        fi
    done < <(grep -oEi -- "${SECRET_NAME}\"?'?[[:space:]]*[:=][[:space:]]*(\"[^\"]{1,200}\"|'[^']{1,200}'|[^[:space:]\"',;][^\"',;]{0,200})" "$scan" || true)

    if [[ "$scan" != "$file" ]]; then
        rm -f "$scan"
    fi
    return 1
}

# --- neutrality vocabulary ----------------------------------------------------

# Private-network products, kept in one place so every scan shares it.
NETWORK_PRODUCT_PATTERN='tailscale|headscale|zerotier|wireguard|wg-quick|ngrok|cloudflared|cloudflare tunnel|netbird|twingate|openvpn|nebula|zrok|localtunnel|pagekite|\.ts\.net'

# Private endpoints and host identities that would tie managed data to one
# machine or network.
PRIVATE_ENDPOINT_PATTERNS=(
    '([0-9]{1,3}\.){3}[0-9]{1,3}'
    '\.(local|internal|lan|intranet|corp|home\.arpa)([^A-Za-z0-9]|$)'
    '://[A-Za-z0-9._-]+:[0-9]{2,5}'
)

# Behavior that only works on one operating system. Shared managed data must
# stay usable on both the macOS desktop target and Linux code-server.
OS_SPECIFIC_PATTERNS=(
    'open -a '
    'osascript'
    'pbcopy|pbpaste'
    'defaults write'
    '/Applications/'
    '~/Library/|/Library/Application Support'
    'xdg-open|wslview|gnome-open'
    'powershell|cmd\.exe|explorer\.exe'
    '%USERPROFILE%|%APPDATA%'
    '[A-Za-z]:\\\\'
)

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
    new_tmp_var tmp

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
        '{"Env":{"prefix":"env","body":["export API_KEY=$API_KEY"]}}'
        '{"Env":{"prefix":"env","body":["password = ${PASSWORD}"]}}'
        '{"Choice":{"prefix":"p","body":["password: ${1|admin,operator|}"]}}'
        'const { token } = await getSession();'
        'password = hashPassword(input123);'
        'headers.authorization = buildAuth(user);'
        'let accessToken = response.token;'
        '{"Doc":{"prefix":"d","body":["Authorization: Bearer <token>"]}}'
        '{"Doc":{"prefix":"d","body":["// password: see the team handbook"]}}'
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
        'password: Tr0ub4dor&3'
        '{"Leak":{"prefix":"p","body":["password: Tr0ub4dor&3"]}}'
        'password: "correct horse battery staple"'
        'client_secret=abc!def#123'
        'https://admin:s3cr3tPass@example.org:8443/path'
        '{"api_key": "letmein"}'
        '{"config":{"password":"plainword"}}'
        "db_password = 'p@ssw0rd!'"
        '{"Leak":{"prefix":"p","body":["password: \"correct horse battery staple\""]}}'
        '{"Leak":{"prefix":"p","body":["password: hunter two 99!"]}}'
    )

    # JSON-shaped fixtures are written with a JSON name so the structural
    # inspection path is exercised alongside the textual scan.
    fixture_path() {
        case "$1" in
            '{'*) printf '%s\n' "$tmp/fixture.json" ;;
            *) printf '%s\n' "$tmp/fixture.txt" ;;
        esac
    }

    local line file
    for line in "${benign[@]}"; do
        file="$(fixture_path "$line")"
        printf '%s\n' "$line" >"$file"
        if contains_credential_material "$file"; then
            fail "credential scan false-positives on benign security vocabulary: $line"
        fi
        rm -f "$file"
    done
    for line in "${malicious[@]}"; do
        file="$(fixture_path "$line")"
        printf '%s\n' "$line" >"$file"
        if ! contains_credential_material "$file"; then
            fail "credential scan missed real credential material: $line"
        fi
        rm -f "$file"
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
        if grep -Eqi -- "$NETWORK_PRODUCT_PATTERN" "$DOTFILES_DIR/$file"; then
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
    new_tmp_var tmp
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

# --- Approved managed-data contract ------------------------------------------

# The complete set of approved managed settings identities and their approved
# values. Any identity absent from this table is unapproved by construction, so
# new editor behavior must be reviewed here before it can enter managed data.
# The leader map's value is delegated to the dedicated leader-map contract.
approved_settings_contract() {
    cat <<'EOF'
[css]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
[html]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
[javascript]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
[javascriptreact]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
[json]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
[jsonc]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
[markdown]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
[python]	{"editor.codeActionsOnSave":{"source.fixAll.ruff":"explicit","source.organizeImports.ruff":"explicit"},"editor.defaultFormatter":"charliermarsh.ruff","editor.formatOnSave":true}
[typescript]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
[typescriptreact]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
[yaml]	{"editor.defaultFormatter":"esbenp.prettier-vscode"}
basedpyright.analysis.diagnosticMode	"openFilesOnly"
basedpyright.analysis.typeCheckingMode	"basic"
editor.codeActionsOnSave	{"source.fixAll.eslint":"explicit"}
editor.formatOnSave	true
editor.lineNumbers	"relative"
eslint.format.enable	false
files.insertFinalNewline	true
files.trimTrailingWhitespace	true
prettier.requireConfig	true
python.analysis.diagnosticMode	"openFilesOnly"
python.analysis.typeCheckingMode	"basic"
vim.easymotion	true
vim.handleKeys	{"<C-f>":false}
vim.hlsearch	true
vim.incsearch	true
vim.leader	" "
vim.normalModeKeyBindingsNonRecursive	<leader-map:12>
vim.surround	true
vim.useSystemClipboard	true
vim.vimrc.enable	false
EOF
}

actual_settings_contract() {
    jq -r '
        def canon:
            if type == "object"
            then to_entries | sort_by(.key) | map({key: .key, value: (.value | canon)}) | from_entries
            else . end;
        to_entries | sort_by(.key)[]
        | if .key == "vim.normalModeKeyBindingsNonRecursive"
          then "\(.key)\t<leader-map:\(.value | length)>"
          else "\(.key)\t\(.value | canon | tojson)"
          end' "$SETTINGS"
}

test_settings_match_the_approved_identity_and_value_contract() {
    assert_set_equal 'approved settings contract' \
        "$(actual_settings_contract)" "$(approved_settings_contract)"
}

test_settings_authorize_no_global_runtime_or_tool_installation() {
    local prohibited=(
        '(^|\.)globalModuleInstallation$'
        '(^|\.)nodeExecutable$'
        'autoDownload'
        'autoInstall'
        '(^|\.)condaPath$'
        '(^|\.)poetryPath$'
        '(^|\.)pipenvPath$'
        '(^|\.)venvPath$'
    )
    local paths pattern
    paths="$(settings_paths)"

    for pattern in "${prohibited[@]}"; do
        if printf '%s\n' "$paths" | grep -Eq -- "$pattern"; then
            fail "managed settings must not enable global runtime or tool installation (matched /$pattern/)"
        fi
    done
}

test_settings_carry_no_host_or_remote_machine_identity() {
    local paths
    paths="$(settings_paths)"

    if printf '%s\n' "$paths" | grep -Eq '^remote\.'; then
        fail "managed settings must not bind shared data to a specific remote host"
    fi
}

# --- Target neutrality of shared managed data --------------------------------

# Settings, keybindings, and snippets are consumed verbatim by both targets.
# The extension manifests are deliberately target-scoped and excluded here.
shared_managed_files() {
    managed_tracked_files | grep -Ev '^vscode/extensions/' || true
}

test_shared_managed_data_encodes_no_os_specific_behavior() {
    local file pattern
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        for pattern in "${OS_SPECIFIC_PATTERNS[@]}"; do
            if grep -Eq -- "$pattern" "$DOTFILES_DIR/$file"; then
                fail "shared managed data must work on both targets: $file (matched /$pattern/)"
            fi
        done
    done < <(shared_managed_files)
}

test_tracked_managed_sources_declare_no_private_endpoint_or_host() {
    local file pattern
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        for pattern in "${PRIVATE_ENDPOINT_PATTERNS[@]}"; do
            if grep -Eq -- "$pattern" "$DOTFILES_DIR/$file"; then
                fail "managed source declares a private endpoint or host identity: $file (matched /$pattern/)"
            fi
        done
    done < <(managed_tracked_files)
}

# --- Authorized managed path set ---------------------------------------------

# Exactly the managed files this slice owns. Later slices extend this list
# deliberately; nothing is pre-authorized on their behalf.
AUTHORIZED_MANAGED_FILES=(
    vscode/settings.json
    vscode/keybindings.json
    vscode/extensions/shared.txt
    vscode/extensions/desktop.txt
    vscode/extensions/code-server.txt
)
AUTHORIZED_SNIPPET_PATTERN='^vscode/snippets/[A-Za-z0-9][A-Za-z0-9._-]*\.(code-snippets|json)$'

test_tracked_managed_paths_are_exactly_the_authorized_set() {
    local file authorized known
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        known=0
        for authorized in "${AUTHORIZED_MANAGED_FILES[@]}"; do
            [[ "$file" == "$authorized" ]] && known=1 && break
        done
        if [[ $known -eq 0 ]] && [[ "$file" =~ $AUTHORIZED_SNIPPET_PATTERN ]]; then
            known=1
        fi
        [[ $known -eq 1 ]] || fail "unauthorized tracked managed path: $file"
    done < <(managed_tracked_files)

    for authorized in "${AUTHORIZED_MANAGED_FILES[@]}"; do
        managed_tracked_files | grep -Fxq "$authorized" ||
            fail "missing authorized managed file: $authorized"
    done
}

test_managed_files_are_regular_repository_content() {
    local file authorized
    for authorized in "${AUTHORIZED_MANAGED_FILES[@]}"; do
        [[ ! -L "$DOTFILES_DIR/$authorized" ]] || fail "managed file must not be a symlink: $authorized"
        [[ -f "$DOTFILES_DIR/$authorized" ]] || fail "managed file must be a regular file: $authorized"
    done

    local dir
    for dir in vscode vscode/snippets vscode/extensions; do
        [[ ! -L "$DOTFILES_DIR/$dir" ]] || fail "managed directory must not be a symlink: $dir"
        [[ -d "$DOTFILES_DIR/$dir" ]] || fail "managed directory must be a real directory: $dir"
    done

    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        [[ ! -L "$DOTFILES_DIR/$file" ]] ||
            fail "managed layer must not link to external data: $file"
        [[ -f "$DOTFILES_DIR/$file" ]] ||
            fail "managed layer must track regular files only: $file"
    done < <(managed_tracked_files)

    local links
    links="$(find "$VSCODE_DIR" -type l 2>/dev/null || true)"
    [[ -z "$links" ]] || fail "managed layer contains symlinks: $links"
}

test_later_slice_artifacts_are_not_pre_authorized() {
    local authorized
    for authorized in "${AUTHORIZED_MANAGED_FILES[@]}"; do
        [[ "$authorized" != "vscode/capture.sh" ]] ||
            fail "Slice 004's capture command must not be pre-authorized by this slice"
    done
}

# --- Test-harness hygiene ----------------------------------------------------

test_test_harness_removes_every_temporary_directory() {
    local workspace sandbox probe output leftover directory
    new_tmp_var workspace
    sandbox="$workspace/tmpdir"
    probe="$workspace/probe.sh"
    mkdir -p "$sandbox"

    cat >"$probe" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "$TEST_DIR/lib/harness.sh"
new_tmp_var first
new_tmp_var second
[[ -d "\$first" && -d "\$second" ]] || exit 1
printf '%s\n%s\n' "\$first" "\$second"
EOF

    output="$(TMPDIR="$sandbox" bash "$probe")" || fail "harness temporary-directory probe failed"
    [[ "$(printf '%s\n' "$output" | wc -l)" -eq 2 ]] || fail "probe did not create two temporary directories"

    while IFS= read -r directory; do
        [[ ! -e "$directory" ]] || fail "harness leaked a temporary directory: $directory"
    done <<<"$output"

    leftover="$(find "$sandbox" -mindepth 1 2>/dev/null | wc -l)"
    [[ "$leftover" -eq 0 ]] || fail "harness left $leftover entries in an isolated TMPDIR"
}

run_tests "vscode managed layer"
