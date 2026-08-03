#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/bash32.sh"

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
[markdown]=yzhang.markdown-all-in-one
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

# Names whose assignment to any literal value is a secret. There is no
# legitimate reason for managed data to assign a literal to one of these.
STRICT_SECRET_NAME='(password|passwd|credential|client[_-]?secret|secret|api[_-]?key|access[_-]?key|private[_-]?key)'

# Names that also occur in ordinary parser, lexer, and protocol code, where
# `token` routinely holds a syntax kind rather than a credential. These need
# entropy, a provider prefix, or an authorization context before they count.
GENERIC_SECRET_NAME='(token|authorization)'

SECRET_NAME="(${STRICT_SECRET_NAME}|${GENERIC_SECRET_NAME})"

# Distinguishes a literal secret from an identifier or a reference. Real
# secrets carry entropy markers -- a digit, strong punctuation, or unusual
# length -- while `lexer.nextToken()`, `buildAuth(user)`, `$AUTH_HEADER`, and
# `${1:placeholder}` do not.
value_is_secret_like() {
    local value="$1"
    local class="$2"

    [[ -n "$value" ]] || return 1

    # References and expressions are never literal secret material.
    case "$value" in
        '$'* | '%'* | *'${'*) return 1 ;; # environment or snippet reference
        *'('*) return 1 ;;                # a call expression
        *'<'* | *'>'*) return 1 ;;        # a documented placeholder, e.g. <token>
        *'{'* | *'}'*) return 1 ;;        # an object or interpolation literal
    esac

    # A name that can only mean a credential is a secret whenever it is given
    # any literal at all, including a spaces-only passphrase.
    [[ "$class" == "strict" ]] && return 0

    # Generic names need evidence beyond the name itself.
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

    jq -e --arg re "^${STRICT_SECRET_NAME}$" '
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
    local pattern candidate value class name_pattern scan

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

    for class in strict generic; do
        if [[ "$class" == "strict" ]]; then
            name_pattern="$STRICT_SECRET_NAME"
        else
            name_pattern="$GENERIC_SECRET_NAME"
        fi
        while IFS= read -r candidate; do
            [[ -n "$candidate" ]] || continue
            value="${candidate#*[:=]}"
            # Trim surrounding whitespace, then a matched pair of quotes.
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"
            if [[ ${#value} -ge 2 && "${value:0:1}" == "\"" && "${value: -1}" == "\"" ]]; then
                value="${value:1:${#value}-2}"
            elif [[ ${#value} -ge 2 && "${value:0:1}" == "'" && "${value: -1}" == "'" ]]; then
                value="${value:1:${#value}-2}"
            fi
            if value_is_secret_like "$value" "$class"; then
                [[ "$scan" != "$file" ]] && rm -f "$scan"
                return 0
            fi
        done < <(grep -oEi -- "${name_pattern}\"?'?[[:space:]]*[:=][[:space:]]*(\"[^\"]{1,200}\"|'[^']{1,200}'|[^[:space:]\"',;][^\"',;]{0,200})" "$scan" || true)
    done

    if [[ "$scan" != "$file" ]]; then
        rm -f "$scan"
    fi
    return 1
}

# --- neutrality vocabulary ----------------------------------------------------

# Private-network products, kept in one place so every scan shares it.
NETWORK_PRODUCT_PATTERN='tailscale|headscale|zerotier|wireguard|wg-quick|ngrok|cloudflared|cloudflare tunnel|netbird|twingate|openvpn|nebula|zrok|localtunnel|pagekite|boringproxy|\bfrps?\b|\bchisel\b|rathole|\bbore\b|teleport|netmaker|innernet|softether|pritunl|\btinc\b|\.ts\.net|\.tailnet'

# Private endpoints and host identities that would tie managed data to one
# machine or network.
PRIVATE_ENDPOINT_PATTERNS=(
    '([0-9]{1,3}\.){3}[0-9]{1,3}'
    '\.(local|internal|lan|intranet|corp|home\.arpa)([^A-Za-z0-9]|$)'
    '://[A-Za-z0-9._-]+:[0-9]{2,5}'
    # A remote-access command carrying a destination names a specific machine,
    # whether that destination is a bare host, user@host, or host:path.
    '(^|[^A-Za-z0-9_-])(ssh|scp|sftp|rsync)[[:space:]]+(-[A-Za-z0-9]+[[:space:]]+)*[A-Za-z0-9_][A-Za-z0-9_.@-]*'
)

# Behavior that only works on one operating system. Shared managed data must
# stay usable on both the macOS desktop target and Linux code-server.
OS_SPECIFIC_PATTERNS=(
    # macOS command families
    'open -a '
    'osascript|automator'
    'pbcopy|pbpaste'
    'defaults write|defaults read'
    '(^|[^A-Za-z0-9_-])(launchctl|diskutil|softwareupdate|sw_vers|plutil|mdfind|mdls|networksetup|scutil|codesign|xcrun|xcode-select|say)([^A-Za-z0-9_-]|$)'
    '(^|[^A-Za-z0-9_-])(brew|port)[[:space:]]+(install|upgrade|list)'
    'security find-generic-password|security add-generic-password'
    '/Applications/'
    '~/Library/|/Library/Application Support'
    # Linux command families
    '(^|[^A-Za-z0-9_-])(systemctl|journalctl|loginctl|udevadm|ldconfig|update-alternatives|dpkg|snap)([^A-Za-z0-9_-]|$)'
    '(^|[^A-Za-z0-9_-])(apt|apt-get|dnf|yum|pacman|zypper)[[:space:]]+(install|update|upgrade|remove)'
    'xdg-open|wslview|gnome-open|kde-open'
    'xclip|xsel|wl-copy|wl-paste'
    '/etc/systemd/|/proc/|/sys/devices/'
    # Windows command families
    'powershell|cmd\.exe|explorer\.exe|reg add|reg query'
    '%USERPROFILE%|%APPDATA%|%LOCALAPPDATA%'
    '[A-Za-z]:\\\\'
)

# One scan combining every neutrality rule, so a single fixture-driven test can
# prove the rules themselves rather than only their current absence.
content_is_target_specific() {
    local file="$1"
    local pattern

    for pattern in "${OS_SPECIFIC_PATTERNS[@]}"; do
        grep -Eqi -- "$pattern" "$file" && return 0
    done
    for pattern in "${PRIVATE_ENDPOINT_PATTERNS[@]}"; do
        grep -Eq -- "$pattern" "$file" && return 0
    done
    grep -Eqi -- "$NETWORK_PRODUCT_PATTERN" "$file" && return 0
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
        '{"token":"identifier"}'
        '{"Parse":{"prefix":"tok","body":["const t = {\"token\":\"identifier\"};"]}}'
        '{"Parse":{"prefix":"tok","body":["if (token == COMMA) next();"]}}'
        'token: keyword'
        'authorization: required'
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
        'password: correct horse battery staple'
        '{"Leak":{"prefix":"p","body":["password: correct horse battery staple"]}}'
        'passwd: opensesame'
        'credential: myplainvalue'
        '{"Leak":{"prefix":"p","body":["token: ghp_0123456789abcdefghijABCDEFGHIJ"]}}'
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
yzhang.markdown-all-in-one
tamasfe.even-better-toml
MermaidChart.vscode-mermaid-chart
GitHub.vscode-github-actions
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
[markdown]	{"editor.defaultFormatter":"yzhang.markdown-all-in-one"}
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
# The extension manifests are deliberately target-scoped, and the capture
# command is a macOS-only operator tool rather than data either editor reads,
# so both are excluded from the shared-data neutrality rule. Every other
# security and content contract still applies to them.
shared_managed_files() {
    managed_tracked_files | grep -Ev '^vscode/(extensions/|capture\.sh$)' || true
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

# Exactly the managed files the repository owns. Each entry is admitted by the
# slice that implements it; nothing is pre-authorized on a later slice's
# behalf. `vscode/capture.sh` was admitted when the capture command landed.
AUTHORIZED_MANAGED_FILES=(
    vscode/settings.json
    vscode/keybindings.json
    vscode/extensions/shared.txt
    vscode/extensions/desktop.txt
    vscode/extensions/code-server.txt
    vscode/capture.sh
)

# The one managed source that is a program rather than editor data.
AUTHORIZED_EXECUTABLE='vscode/capture.sh'
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

# The capture command is the single authorized program in the managed layer.
# Everything else is editor data and must not be executable, so a new script
# cannot enter the module without being reviewed into the authorized set.
test_capture_command_is_the_only_executable_managed_source() {
    local file mode

    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        mode="$(git -C "$DOTFILES_DIR" ls-files --stage -- "$file" | awk '{print $1}')"
        if [[ "$file" == "$AUTHORIZED_EXECUTABLE" ]]; then
            [[ -x "$DOTFILES_DIR/$file" ]] || fail "capture command is not executable: $file"
            [[ -z "$mode" || "$mode" == "100755" ]] ||
                fail "capture command must be tracked with mode 100755, got $mode"
        else
            [[ ! -x "$DOTFILES_DIR/$file" ]] || fail "managed data must not be executable: $file"
            [[ -z "$mode" || "$mode" == "100644" ]] ||
                fail "managed data must be tracked with mode 100644, got $mode for $file"
        fi
    done < <(managed_tracked_files)
}

test_neutrality_scan_rejects_host_product_and_os_specific_content() {
    local tmp
    new_tmp_var tmp

    local target_specific=(
        'ssh buildbox'
        'ssh -p 2222 buildbox'
        'ssh deploy@buildbox'
        'scp file deploybox:/tmp'
        'sftp releases.example.internal'
        'rsync -av src backup-host:/srv'
        'start boringproxy client'
        'chisel client https://relay:9090 R:8080'
        'frp -c frpc.ini'
        'launchctl list'
        'launchctl unload ~/Library/LaunchAgents/x.plist'
        'systemctl --user status code-server'
        'journalctl -u code-server'
        'apt-get install code'
        'brew install --cask visual-studio-code'
        'pbcopy < file'
        'xdg-open README.md'
        'xclip -selection clipboard'
        'osascript -e beep'
        'diskutil list'
        'security find-generic-password -s code'
        'reg add HKCU\Software'
        'curl https://10.42.0.7:8443/healthz'
        'ping desk.local'
    )
    # Target-neutral content that must not be mistaken for machine coupling.
    local neutral=(
        '$CURRENT_YEAR-$CURRENT_MONTH-$CURRENT_DATE'
        '$LINE_COMMENT TODO: $1'
        'const value = compute(input);'
        'def main() -> None:'
        'git commit --amend'
        'npm run build'
        'print("hello world")'
        '// open a new editor tab'
        'SELECT * FROM users WHERE id = 1;'
        'import { useState } from "react";'
    )

    local line
    for line in "${target_specific[@]}"; do
        printf '%s\n' "$line" >"$tmp/neutrality.txt"
        if ! content_is_target_specific "$tmp/neutrality.txt"; then
            fail "neutrality scan missed target-specific content: $line"
        fi
    done
    for line in "${neutral[@]}"; do
        printf '%s\n' "$line" >"$tmp/neutrality.txt"
        if content_is_target_specific "$tmp/neutrality.txt"; then
            fail "neutrality scan false-positives on target-neutral content: $line"
        fi
    done
}

# --- Snippet structure and approved content ----------------------------------

# Problems reported by the VS Code snippet schema, one per line.
snippet_schema_problems() {
    jq -r '
        def is_string_or_string_array:
            type == "string" or (type == "array" and length > 0 and all(.[]; type == "string"));
        if type != "object" then "root is \(type), expected an object"
        else
            to_entries[]
            | .key as $name
            | if (.value | type) != "object" then "\($name): definition is \(.value | type), expected an object"
              elif (.value | has("body") | not) then "\($name): missing required body"
              elif (.value.body | is_string_or_string_array | not) then "\($name): body must be a string or non-empty string array"
              elif (.value | has("prefix")) and (.value.prefix | is_string_or_string_array | not) then "\($name): prefix must be a string or non-empty string array"
              elif (.value | has("description")) and (.value.description | type != "string") then "\($name): description must be a string"
              elif (.value | has("scope")) and (.value.scope | type != "string") then "\($name): scope must be a string"
              else (.value | keys - ["prefix", "body", "description", "scope", "isFileTemplate"])
                   | if length > 0 then "\($name): unsupported fields \(.)" else empty end
              end
        end' "$1" 2>/dev/null || printf 'unparseable snippet document\n'
}

test_snippet_definitions_satisfy_the_vscode_snippet_schema() {
    local file problems
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        problems="$(snippet_schema_problems "$DOTFILES_DIR/$file")"
        [[ -z "$problems" ]] || fail "invalid snippet definition in $file: $problems"
    done < <(managed_tracked_files | grep '^vscode/snippets/' || true)
}

test_snippet_schema_rejects_malformed_definitions() {
    local tmp
    new_tmp_var tmp

    local invalid=(
        '{"Broken":42}'
        '{"Broken":"just a string"}'
        '{"Broken":null}'
        '{"Broken":["a","b"]}'
        '{"NoBody":{"prefix":"x"}}'
        '{"BadBody":{"prefix":"x","body":7}}'
        '{"BadBody":{"prefix":"x","body":[]}}'
        '{"BadBody":{"prefix":"x","body":["ok",5]}}'
        '{"BadPrefix":{"prefix":9,"body":["ok"]}}'
        '{"BadDesc":{"prefix":"x","body":["ok"],"description":5}}'
        '{"BadScope":{"prefix":"x","body":["ok"],"scope":["js"]}}'
        '{"Unknown":{"prefix":"x","body":["ok"],"language":"js"}}'
        '["not","an","object"]'
        '"scalar root"'
    )
    local valid=(
        '{"Ok":{"prefix":"x","body":"one line"}}'
        '{"Ok":{"prefix":"x","body":["a","b"]}}'
        '{"Ok":{"prefix":["x","y"],"body":["a"],"description":"d","scope":"javascript"}}'
        '{"Ok":{"body":["a"]}}'
    )

    local document
    for document in "${invalid[@]}"; do
        printf '%s\n' "$document" >"$tmp/snippet.code-snippets"
        [[ -n "$(snippet_schema_problems "$tmp/snippet.code-snippets")" ]] ||
            fail "snippet schema accepted an invalid definition: $document"
    done
    for document in "${valid[@]}"; do
        printf '%s\n' "$document" >"$tmp/snippet.code-snippets"
        [[ -z "$(snippet_schema_problems "$tmp/snippet.code-snippets")" ]] ||
            fail "snippet schema rejected a valid definition: $document"
    done
}

# The approved snippet unit, as name/prefix/body triples. Locking the content
# makes neutrality a property of reviewed data rather than of pattern coverage.
approved_snippet_contract() {
    cat <<'EOF'
global.code-snippets	Insert ISO 8601 date	isodate	$CURRENT_YEAR-$CURRENT_MONTH-$CURRENT_DATE
global.code-snippets	Insert TODO marker	todo	$LINE_COMMENT TODO: $1
EOF
}

actual_snippet_contract() {
    local file
    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        jq -r --arg f "${file##*/}" '
            to_entries[]
            | "\($f)\t\(.key)\t\(.value.prefix | if type == "array" then join(",") else . end)\t\(.value.body | if type == "array" then join("\\n") else . end)"' \
            "$DOTFILES_DIR/$file"
    done < <(managed_tracked_files | grep '^vscode/snippets/' || true)
}

test_snippets_match_the_approved_snippet_contract() {
    assert_set_equal 'approved snippet contract' \
        "$(actual_snippet_contract)" "$(approved_snippet_contract)"
}

# --- Transactional desktop capture -------------------------------------------

CAPTURE_SH="$VSCODE_DIR/capture.sh"

# macOS Default Profile user-configuration location, relative to HOME.
DESKTOP_USER_REL='Library/Application Support/Code/User'

# What the desktop editor CLI reports, and the desktop-only identities the
# managed manifest must end up holding.
CAPTURE_STUB_EXTENSIONS='vscodevim.vim@1.27.2
ms-python.python@2024.14.1
esbenp.prettier-vscode'
CAPTURE_EXPECTED_DESKTOP_IDS='vscodevim.vim
ms-python.python
esbenp.prettier-vscode'

# An isolated world for the capture command: a temporary repository module, a
# temporary desktop HOME holding the data to capture, a stub PATH, and a
# private TMPDIR whose emptiness afterwards proves cleanup.
new_capture_sandbox() {
    local __capture_sandbox_name="$1"
    local __capture_root __capture_user

    [[ -f "$CAPTURE_SH" ]] || fail "missing capture command: $CAPTURE_SH"

    new_tmp_var __capture_root
    __capture_user="$__capture_root/home/$DESKTOP_USER_REL"
    mkdir -p "$__capture_user/snippets" "$__capture_root/repo/vscode/extensions" \
        "$__capture_root/bin" "$__capture_root/tmp"

    cp "$CAPTURE_SH" "$__capture_root/repo/vscode/capture.sh"
    chmod +x "$__capture_root/repo/vscode/capture.sh"

    printf '%s\n' '{"editor.formatOnSave": true, "vim.leader": " "}' >"$__capture_user/settings.json"
    printf '%s\n' '[{"key": "ctrl+f", "command": "actions.find"}]' >"$__capture_user/keybindings.json"
    printf '%s\n' '{"Desktop":{"prefix":"d","body":["captured"]}}' >"$__capture_user/snippets/global.code-snippets"
    printf '%s\n' '{"Py":{"prefix":"p","body":["captured"]}}' >"$__capture_user/snippets/python.json"

    printf '%s\n' \
        '#!/bin/sh' \
        "echo uname >>\"$__capture_root/commands.log\"" \
        'echo Darwin' >"$__capture_root/bin/uname"
    printf '%s\n' \
        '#!/bin/sh' \
        "echo code >>\"$__capture_root/commands.log\"" \
        'if [ "$1" != "--list-extensions" ]; then echo "unexpected: $*" >&2; exit 64; fi' \
        "cat <<'IDS'" \
        "$CAPTURE_STUB_EXTENSIONS" \
        'IDS' >"$__capture_root/bin/code"
    chmod +x "$__capture_root/bin/uname" "$__capture_root/bin/code"

    # Staging reads the desktop through these two commands; logging them makes
    # "no staging happened" an observation rather than an inference.
    install_logging_command_stub "$__capture_root" cp
    install_logging_command_stub "$__capture_root" mktemp

    : >"$__capture_root/commands.log"
    printf -v "$__capture_sandbox_name" '%s' "$__capture_root"
}

# Replace a command on the sandbox PATH with one that records its own name and
# then behaves normally, so the test can observe which operations a run
# performed rather than trusting the order of the source.
install_logging_command_stub() {
    local root="$1"
    local command_name="$2"
    local real
    real="$(command -v "$command_name")" || fail "cannot stub missing command: $command_name"

    printf '%s\n' \
        '#!/bin/sh' \
        "echo $command_name >>\"$root/commands.log\"" \
        "exec \"$real\" \"\$@\"" >"$root/bin/$command_name"
    chmod +x "$root/bin/$command_name"
}

# The commands a run actually executed, deduplicated in first-use order.
executed_commands() {
    local root="$1"
    awk '!seen[$0]++' "$root/commands.log"
}

assert_executed_commands() {
    local root="$1"
    local expected="$2"
    local label="$3"
    local actual

    actual="$(executed_commands "$root")"
    [[ "$actual" == "$expected" ]] ||
        fail "$label: executed commands mismatch
expected: $(printf '%s' "$expected" | tr '\n' ' ')
actual:   $(printf '%s' "$actual" | tr '\n' ' ')"
}

# Run the command under test and record its status and combined output.
run_capture() {
    local root="$1"
    shift
    local search_path="${CAPTURE_PATH_OVERRIDE:-$root/bin:$PATH}"

    set +e
    CAPTURE_OUTPUT="$(HOME="$root/home" PATH="$search_path" TMPDIR="$root/tmp" \
        "$root/repo/vscode/capture.sh" "$@" 2>&1)"
    CAPTURE_STATUS=$?
    set -e
}

# Everything observable about a directory tree: names, kinds, and content.
directory_state() {
    local root="$1"
    local path

    (
        cd "$root" || exit 1
        find . -mindepth 1 | LC_ALL=C sort | while IFS= read -r path; do
            if [[ -L "$path" ]]; then
                printf 'link %s -> %s\n' "$path" "$(readlink "$path")"
            elif [[ -d "$path" ]]; then
                printf 'dir  %s\n' "$path"
            else
                printf 'file %s %s\n' "$path" "$(cksum <"$path")"
            fi
        done
    )
}

capture_module_state() {
    directory_state "$1/vscode"
}

assert_module_unchanged() {
    local root="$1"
    local before="$2"
    local label="$3"
    local after

    after="$(capture_module_state "$root/repo")"
    [[ "$after" == "$before" ]] ||
        fail "$label: managed destinations changed (< before, > after):
$(diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") || true)"
}

assert_no_temporary_state() {
    local root="$1"
    local label="$2"
    local leftover

    leftover="$(find "$root/tmp" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$leftover" -eq 0 ]] ||
        fail "$label: capture leaked temporary state under TMPDIR:
$(find "$root/tmp" -mindepth 1)"

    leftover="$(find "$root/repo/vscode" -name '*capture*' ! -name 'capture.sh' 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$leftover" -eq 0 ]] ||
        fail "$label: capture left working files inside the managed module:
$(find "$root/repo/vscode" -name '*capture*' ! -name 'capture.sh')"
}

assert_capture_failed() {
    local label="$1"
    [[ "$CAPTURE_STATUS" -ne 0 ]] ||
        fail "$label: capture succeeded but must have failed; output:
$CAPTURE_OUTPUT"
}

assert_output_mentions() {
    local pattern="$1"
    local label="$2"
    printf '%s\n' "$CAPTURE_OUTPUT" | grep -Eqi -- "$pattern" ||
        fail "$label: output does not mention /$pattern/; output:
$CAPTURE_OUTPUT"
}

assert_output_lacks() {
    local pattern="$1"
    local label="$2"
    if printf '%s\n' "$CAPTURE_OUTPUT" | grep -Eqi -- "$pattern"; then
        fail "$label: output mentions /$pattern/ but must not; output:
$CAPTURE_OUTPUT"
    fi
}

# --- Cycle A: platform, CLI, option, and overwrite preflight ------------------

test_capture_refuses_a_non_macos_host() {
    local root before
    new_capture_sandbox root
    printf '%s\n' '#!/bin/sh' 'echo Linux' >"$root/bin/uname"
    chmod +x "$root/bin/uname"
    before="$(capture_module_state "$root/repo")"

    run_capture "$root" --force
    assert_capture_failed 'non-macOS capture'
    assert_output_mentions 'macos' 'non-macOS capture'
    assert_module_unchanged "$root" "$before" 'non-macOS capture'
    assert_no_temporary_state "$root" 'non-macOS capture'
}

test_capture_requires_the_desktop_editor_command() {
    local root before
    new_capture_sandbox root
    rm -f "$root/bin/code"
    before="$(capture_module_state "$root/repo")"

    local restricted="$root/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    PATH="$restricted" command -v code >/dev/null &&
        fail "test precondition: a real 'code' command is visible on the restricted PATH"

    CAPTURE_PATH_OVERRIDE="$restricted" run_capture "$root" --force
    assert_capture_failed 'missing editor CLI'
    assert_output_mentions 'code' 'missing editor CLI'
    assert_module_unchanged "$root" "$before" 'missing editor CLI'
    assert_no_temporary_state "$root" 'missing editor CLI'
}

test_capture_rejects_unknown_options() {
    local root before argument
    new_capture_sandbox root
    before="$(capture_module_state "$root/repo")"

    for argument in --deploy --no-force -f 'extra-operand'; do
        run_capture "$root" "$argument"
        assert_capture_failed "unknown option $argument"
        assert_module_unchanged "$root" "$before" "unknown option $argument"
        assert_no_temporary_state "$root" "unknown option $argument"
    done
}

test_capture_refuses_any_existing_destination_without_force() {
    local root before destination
    local destinations=(
        vscode/settings.json
        vscode/keybindings.json
        vscode/snippets
        vscode/extensions/desktop.txt
    )

    for destination in "${destinations[@]}"; do
        new_capture_sandbox root
        if [[ "$destination" == vscode/snippets ]]; then
            mkdir -p "$root/repo/$destination"
            printf '%s\n' '{"Existing":{"prefix":"e","body":["kept"]}}' \
                >"$root/repo/$destination/existing.code-snippets"
        else
            printf '%s\n' 'existing managed content' >"$root/repo/$destination"
        fi
        before="$(capture_module_state "$root/repo")"

        run_capture "$root"
        assert_capture_failed "existing $destination"
        assert_output_mentions "$(printf '%s' "$destination" | sed -e 's/\./\\./g')" "existing $destination"
        assert_output_mentions 'force' "existing $destination"
        assert_module_unchanged "$root" "$before" "existing $destination"
        assert_no_temporary_state "$root" "existing $destination"
    done
}

# Refusal must happen before the desktop is read at all, and the checks must
# run in order: options, then platform, then the editor CLI, then conflicts.
# Observing the commands each run executed proves the ordering directly.
test_refusal_performs_no_staging_or_source_operation() {
    local root

    # An unknown option is rejected before the platform is even identified.
    new_capture_sandbox root
    run_capture "$root" --deploy
    assert_capture_failed 'option precedence'
    assert_executed_commands "$root" '' 'option precedence'

    # An unsupported platform is rejected before the editor CLI is consulted.
    new_capture_sandbox root
    printf '%s\n' '#!/bin/sh' "echo uname >>\"$root/commands.log\"" 'echo Linux' >"$root/bin/uname"
    chmod +x "$root/bin/uname"
    run_capture "$root" --force
    assert_capture_failed 'platform precedence'
    assert_executed_commands "$root" 'uname' 'platform precedence'

    # A conflicting destination is refused before anything is staged: no
    # temporary root is allocated, nothing is copied, no extension list is run.
    new_capture_sandbox root
    printf '%s\n' 'existing settings' >"$root/repo/vscode/settings.json"
    run_capture "$root"
    assert_capture_failed 'conflict precedence'
    assert_executed_commands "$root" 'uname' 'conflict precedence'

    # Positive control: a run that does stage records exactly those commands,
    # so the assertions above cannot pass because logging is broken.
    new_capture_sandbox root
    run_capture "$root"
    assert_capture_succeeded 'staging control'
    assert_executed_commands "$root" 'uname
mktemp
cp
code' 'staging control'
}

# The conflict text a run must not produce when an earlier validation already
# refused it. The usage banner mentions --force, so absence is asserted against
# the conflict report itself rather than against the word "force".
CAPTURE_CONFLICT_REPORT='would replace existing managed sources|rerun with --force'

# Populate a sandbox module with a destination that would itself be refused, so
# that each validation case below is a genuine combination rather than a
# validation failure in an otherwise clean module.
seed_conflicting_destination() {
    local root="$1"
    printf '%s\n' 'existing settings' >"$root/repo/vscode/settings.json"
}

# Every validation refusal outranks a conflict, even when both are true at
# once. Without the combination, an implementation that preflighted between two
# validation steps would still look correct: each case here is a separate
# ordering claim, and the conflict is present in all of them.
test_validation_outranks_an_existing_destination_conflict() {
    local root before

    # An unknown option is rejected before any destination is inspected.
    new_capture_sandbox root
    seed_conflicting_destination "$root"
    before="$(capture_module_state "$root/repo")"
    run_capture "$root" --deploy
    assert_capture_failed 'conflicting unknown option'
    assert_output_mentions 'unknown argument: --deploy' 'conflicting unknown option'
    assert_output_lacks "$CAPTURE_CONFLICT_REPORT" 'conflicting unknown option'
    assert_executed_commands "$root" '' 'conflicting unknown option'
    assert_module_unchanged "$root" "$before" 'conflicting unknown option'
    assert_no_temporary_state "$root" 'conflicting unknown option'

    # An unsupported platform is rejected before any destination is inspected.
    new_capture_sandbox root
    seed_conflicting_destination "$root"
    printf '%s\n' '#!/bin/sh' "echo uname >>\"$root/commands.log\"" 'echo Linux' >"$root/bin/uname"
    chmod +x "$root/bin/uname"
    before="$(capture_module_state "$root/repo")"
    run_capture "$root"
    assert_capture_failed 'conflicting unsupported platform'
    assert_output_mentions 'macos' 'conflicting unsupported platform'
    assert_output_lacks "$CAPTURE_CONFLICT_REPORT" 'conflicting unsupported platform'
    assert_executed_commands "$root" 'uname' 'conflicting unsupported platform'
    assert_module_unchanged "$root" "$before" 'conflicting unsupported platform'
    assert_no_temporary_state "$root" 'conflicting unsupported platform'

    # A missing editor CLI is rejected before any destination is inspected.
    new_capture_sandbox root
    seed_conflicting_destination "$root"
    rm -f "$root/bin/code"
    before="$(capture_module_state "$root/repo")"

    local restricted="$root/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    PATH="$restricted" command -v code >/dev/null &&
        fail "test precondition: a real 'code' command is visible on the restricted PATH"

    CAPTURE_PATH_OVERRIDE="$restricted" run_capture "$root"
    assert_capture_failed 'conflicting missing editor CLI'
    assert_output_mentions "requires the 'code' command" 'conflicting missing editor CLI'
    assert_output_lacks "$CAPTURE_CONFLICT_REPORT" 'conflicting missing editor CLI'
    assert_executed_commands "$root" 'uname' 'conflicting missing editor CLI'
    assert_module_unchanged "$root" "$before" 'conflicting missing editor CLI'
    assert_no_temporary_state "$root" 'conflicting missing editor CLI'
}

test_capture_reports_every_conflict_before_touching_any_destination() {
    local root before
    new_capture_sandbox root
    printf '%s\n' 'existing settings' >"$root/repo/vscode/settings.json"
    printf '%s\n' 'existing manifest' >"$root/repo/vscode/extensions/desktop.txt"
    before="$(capture_module_state "$root/repo")"

    run_capture "$root"
    assert_capture_failed 'multiple conflicts'
    assert_output_mentions 'vscode/settings\.json' 'multiple conflicts'
    assert_output_mentions 'vscode/extensions/desktop\.txt' 'multiple conflicts'
    assert_module_unchanged "$root" "$before" 'multiple conflicts'
    assert_no_temporary_state "$root" 'multiple conflicts'
}

# --- Cycle B: staged complete capture and unversioned identities -------------

assert_captured_file() {
    local path="$1"
    local expected="$2"
    local label="$3"

    [[ -f "$path" ]] || fail "$label: capture did not publish $path"
    [[ ! -L "$path" ]] || fail "$label: capture published a symlink at $path"

    local actual
    actual="$(cat "$path")"
    [[ "$actual" == "$expected" ]] ||
        fail "$label: published content mismatch at $path
expected: $expected
actual:   $actual"
}

assert_capture_succeeded() {
    local label="$1"
    [[ "$CAPTURE_STATUS" -eq 0 ]] ||
        fail "$label: capture failed with status $CAPTURE_STATUS; output:
$CAPTURE_OUTPUT"
}

# The complete published capture unit, asserted as one set so a missing or
# stale artifact cannot hide behind the others.
assert_complete_capture_published() {
    local root="$1"
    local label="$2"
    local repo="$root/repo"
    local user="$root/home/$DESKTOP_USER_REL"

    assert_captured_file "$repo/vscode/settings.json" "$(cat "$user/settings.json")" "$label"
    assert_captured_file "$repo/vscode/keybindings.json" "$(cat "$user/keybindings.json")" "$label"
    assert_captured_file "$repo/vscode/extensions/desktop.txt" "$CAPTURE_EXPECTED_DESKTOP_IDS" "$label"

    [[ -d "$repo/vscode/snippets" ]] || fail "$label: capture did not publish the snippets directory"
    [[ ! -L "$repo/vscode/snippets" ]] || fail "$label: published snippets must be a real directory"
    assert_set_equal "$label snippet files" \
        "$(cd "$repo/vscode/snippets" && find . -type f | sed -e 's|^\./||' | LC_ALL=C sort)" \
        'global.code-snippets
python.json'
    assert_captured_file "$repo/vscode/snippets/global.code-snippets" \
        "$(cat "$user/snippets/global.code-snippets")" "$label"
    assert_captured_file "$repo/vscode/snippets/python.json" \
        "$(cat "$user/snippets/python.json")" "$label"
}

test_capture_into_a_clean_module_publishes_the_complete_unit() {
    local root
    new_capture_sandbox root

    run_capture "$root"
    assert_capture_succeeded 'clean capture'
    assert_complete_capture_published "$root" 'clean capture'
    assert_no_temporary_state "$root" 'clean capture'
}

test_forced_capture_replaces_every_existing_destination() {
    local root
    new_capture_sandbox root
    printf '%s\n' 'stale settings' >"$root/repo/vscode/settings.json"
    printf '%s\n' 'stale keybindings' >"$root/repo/vscode/keybindings.json"
    printf '%s\n' 'stale manifest' >"$root/repo/vscode/extensions/desktop.txt"
    mkdir -p "$root/repo/vscode/snippets"
    printf '%s\n' 'stale snippet' >"$root/repo/vscode/snippets/stale.code-snippets"

    run_capture "$root" --force
    assert_capture_succeeded 'forced capture'
    assert_complete_capture_published "$root" 'forced capture'
    [[ ! -e "$root/repo/vscode/snippets/stale.code-snippets" ]] ||
        fail "forced capture merged into the old snippets directory instead of replacing it"
    assert_no_temporary_state "$root" 'forced capture'
}

test_capture_writes_only_the_desktop_extension_manifest() {
    local root shared_before server_before
    new_capture_sandbox root
    printf '%s\n' 'vscodevim.vim' >"$root/repo/vscode/extensions/shared.txt"
    printf '%s\n' 'ms-python.python' >"$root/repo/vscode/extensions/code-server.txt"
    shared_before="$(cksum <"$root/repo/vscode/extensions/shared.txt")"
    server_before="$(cksum <"$root/repo/vscode/extensions/code-server.txt")"

    run_capture "$root"
    assert_capture_succeeded 'desktop-only capture'
    [[ "$(cksum <"$root/repo/vscode/extensions/shared.txt")" == "$shared_before" ]] ||
        fail "capture modified the shared extension manifest"
    [[ "$(cksum <"$root/repo/vscode/extensions/code-server.txt")" == "$server_before" ]] ||
        fail "capture modified the code-server extension manifest"
}

test_captured_extension_identities_omit_versions() {
    local root entry
    new_capture_sandbox root

    run_capture "$root"
    assert_capture_succeeded 'unversioned capture'
    [[ -f "$root/repo/vscode/extensions/desktop.txt" ]] ||
        fail "unversioned capture: capture published no desktop extension manifest"

    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        [[ "$entry" != *@* ]] || fail "captured desktop identity pins a version: $entry"
        [[ "$entry" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*\.[A-Za-z0-9][A-Za-z0-9_-]*$ ]] ||
            fail "captured desktop identity is not publisher.name form: $entry"
    done <"$root/repo/vscode/extensions/desktop.txt"
}

test_capture_refuses_an_incomplete_desktop_configuration() {
    local root before source
    for source in settings.json keybindings.json snippets; do
        new_capture_sandbox root
        rm -rf "$root/home/$DESKTOP_USER_REL/$source"
        before="$(capture_module_state "$root/repo")"

        run_capture "$root" --force
        assert_capture_failed "missing desktop $source"
        assert_output_mentions "$(printf '%s' "$source" | sed -e 's/\./\\./g')" "missing desktop $source"
        assert_module_unchanged "$root" "$before" "missing desktop $source"
        assert_no_temporary_state "$root" "missing desktop $source"
    done
}

# --- Cycle C: failure cleanup, warning, and install separation ---------------

# Seed every managed destination with recognizable content, so a later
# comparison proves that a refused or failed capture changed nothing.
seed_all_destinations() {
    local root="$1"
    printf '%s\n' 'existing settings' >"$root/repo/vscode/settings.json"
    printf '%s\n' 'existing keybindings' >"$root/repo/vscode/keybindings.json"
    printf '%s\n' 'existing manifest' >"$root/repo/vscode/extensions/desktop.txt"
    mkdir -p "$root/repo/vscode/snippets"
    printf '%s\n' 'existing snippet' >"$root/repo/vscode/snippets/existing.code-snippets"
}

# Replace a command on the sandbox PATH with one that fails whenever any of its
# arguments matches a pattern, and otherwise behaves normally.
install_failing_command_stub() {
    local root="$1"
    local command_name="$2"
    local pattern="$3"
    local real
    real="$(command -v "$command_name")" || fail "cannot stub missing command: $command_name"

    cat >"$root/bin/$command_name" <<EOF
#!/bin/sh
for argument in "\$@"; do
    case "\$argument" in
        $pattern)
            echo "$command_name: injected failure on \$argument" >&2
            exit 1
            ;;
    esac
done
exec "$real" "\$@"
EOF
    chmod +x "$root/bin/$command_name"
}

test_capture_publishes_nothing_when_the_extension_listing_fails() {
    local root before
    new_capture_sandbox root
    seed_all_destinations "$root"
    printf '%s\n' '#!/bin/sh' 'echo "editor CLI unavailable" >&2' 'exit 1' >"$root/bin/code"
    chmod +x "$root/bin/code"
    before="$(capture_module_state "$root/repo")"

    run_capture "$root" --force
    assert_capture_failed 'extension listing failure'
    assert_output_mentions 'list-extensions' 'extension listing failure'
    assert_module_unchanged "$root" "$before" 'extension listing failure'
    assert_no_temporary_state "$root" 'extension listing failure'
}

test_capture_publishes_nothing_when_staging_a_source_fails() {
    local root before
    new_capture_sandbox root
    seed_all_destinations "$root"
    install_failing_command_stub "$root" cp '*snippets*'
    before="$(capture_module_state "$root/repo")"

    run_capture "$root" --force
    assert_capture_failed 'staging failure'
    assert_output_mentions 'snippets' 'staging failure'
    assert_module_unchanged "$root" "$before" 'staging failure'
    assert_no_temporary_state "$root" 'staging failure'
}

test_capture_rolls_back_when_publication_fails_midway() {
    local root before
    new_capture_sandbox root
    seed_all_destinations "$root"
    # The desktop manifest is published last, so failing only on it proves that
    # destinations replaced earlier in the same run are restored.
    install_failing_command_stub "$root" mv '*desktop.txt'
    before="$(capture_module_state "$root/repo")"

    run_capture "$root" --force
    assert_capture_failed 'publication failure'
    assert_output_mentions 'vscode/extensions/desktop\.txt' 'publication failure'
    assert_module_unchanged "$root" "$before" 'publication failure'
    assert_no_temporary_state "$root" 'publication failure'
}

test_capture_restores_the_original_when_a_destination_cannot_be_filled() {
    local root before
    new_capture_sandbox root
    seed_all_destinations "$root"
    # Fail while moving a prepared artifact into place, after its original has
    # already been displaced: the original must come back.
    install_failing_command_stub "$root" mv '*capture-new*'
    before="$(capture_module_state "$root/repo")"

    run_capture "$root" --force
    assert_capture_failed 'unfillable destination'
    assert_output_mentions 'publish' 'unfillable destination'
    assert_module_unchanged "$root" "$before" 'unfillable destination'
    assert_no_temporary_state "$root" 'unfillable destination'
}

# A first capture into a clean module has nothing to back up, so rollback must
# undo creation rather than restoration: every destination the failed run made
# has to be gone again.
test_capture_leaves_a_clean_module_clean_when_publication_fails_midway() {
    local root before
    new_capture_sandbox root
    install_failing_command_stub "$root" mv '*desktop.txt'
    before="$(capture_module_state "$root/repo")"

    run_capture "$root"
    assert_capture_failed 'clean-module publication failure'
    assert_module_unchanged "$root" "$before" 'clean-module publication failure'
    assert_no_temporary_state "$root" 'clean-module publication failure'

    local created
    created="$(find "$root/repo/vscode" -mindepth 1 ! -name 'capture.sh' ! -name 'extensions' | LC_ALL=C sort)"
    [[ -z "$created" ]] ||
        fail "failed capture left newly created destinations behind:
$created"
}

# The realistic case: some destinations exist and some do not. Rollback has to
# restore the displaced originals and delete the newly created ones in the
# same run.
test_capture_restores_a_mixed_module_when_publication_fails_midway() {
    local root before
    new_capture_sandbox root
    printf '%s\n' 'existing settings' >"$root/repo/vscode/settings.json"
    mkdir -p "$root/repo/vscode/snippets"
    printf '%s\n' 'existing snippet' >"$root/repo/vscode/snippets/existing.code-snippets"
    install_failing_command_stub "$root" mv '*desktop.txt'
    before="$(capture_module_state "$root/repo")"

    run_capture "$root" --force
    assert_capture_failed 'mixed-module publication failure'
    assert_module_unchanged "$root" "$before" 'mixed-module publication failure'
    assert_no_temporary_state "$root" 'mixed-module publication failure'

    [[ ! -e "$root/repo/vscode/keybindings.json" ]] ||
        fail "failed capture kept a destination it created from nothing"
    [[ ! -e "$root/repo/vscode/extensions/desktop.txt" ]] ||
        fail "failed capture kept the destination whose publication failed"
}

test_capture_warns_that_captured_data_needs_review_before_commit() {
    local root
    new_capture_sandbox root

    run_capture "$root"
    assert_capture_succeeded 'review warning'
    assert_output_mentions 'review' 'review warning'
    assert_output_mentions 'credential' 'review warning'
    assert_output_mentions 'machine-specific' 'review warning'
    assert_output_mentions 'commit' 'review warning'
}

test_capture_deploys_nothing_and_leaves_the_desktop_untouched() {
    local root before after
    new_capture_sandbox root
    before="$(directory_state "$root/home")"

    run_capture "$root"
    assert_capture_succeeded 'no deployment'

    after="$(directory_state "$root/home")"
    [[ "$after" == "$before" ]] ||
        fail "capture mutated the desktop configuration (< before, > after):
$(diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") || true)"

    local links
    links="$(find "$root/home" "$root/repo" -type l 2>/dev/null || true)"
    [[ -z "$links" ]] || fail "capture created symlinks: $links"
}

test_capture_command_installs_and_deploys_nothing() {
    local prohibited=(
        'ln[[:space:]]+-s'
        '--install-extension'
        '(^|[^A-Za-z0-9_-])(brew|apt|apt-get|dnf|pacman|npm|pip|pip3|gem|cargo)[[:space:]]'
        '(^|[^A-Za-z0-9_-])(curl|wget|systemctl|launchctl)([^A-Za-z0-9_-]|$)'
        'defaults[[:space:]]+write'
    )
    local executable pattern hits
    # Comments describe intent; only executable lines can act.
    executable="$(grep -v '^[[:space:]]*#' "$CAPTURE_SH")"

    for pattern in "${prohibited[@]}"; do
        hits="$(printf '%s\n' "$executable" | grep -En -- "$pattern" || true)"
        [[ -z "$hits" ]] ||
            fail "capture must not deploy or install anything (matched /$pattern/):
$hits"
    done
}

test_install_never_routes_to_capture() {
    local hits
    hits="$(grep -n -i 'capture' "$DOTFILES_DIR/install.sh" || true)"
    [[ -z "$hits" ]] ||
        fail "install.sh must contain no path that invokes capture:
$hits"
}

test_capture_command_is_valid_bash_32_source() {
    bash -n "$CAPTURE_SH" || fail "capture command is not valid shell source"

    local violations
    violations="$(bash32_violations "$CAPTURE_SH" || true)"
    [[ -z "$violations" ]] ||
        fail "capture command uses post-Bash-3.2 constructs:
$violations"

    head -n 1 "$CAPTURE_SH" | grep -Eq '^#!.*bash' ||
        fail "capture command must declare a bash interpreter"
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
