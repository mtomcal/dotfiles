#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/harness.sh"

# ---------------------------------------------------------------------------
# Observation seam
#
# Every test drives the public `install_python` entry point with a controlled
# platform, a stubbed package seam, and stub interpreters. The module runs with
# PATH restricted to the stub directory, so any command it reaches for outside
# the native package seam is either recorded or fails loudly.
# ---------------------------------------------------------------------------

# Commands the module is allowed to use for real. Anything else must show up in
# the recorded command log instead of touching the machine.
REAL_TOOLS="mktemp rm"

# Commands that would violate the module's ownership: privilege escalation,
# third-party repositories, project/global Python tooling, and system-link
# changes. They are stubbed so an attempt is recorded rather than executed.
FORBIDDEN_TOOLS="sudo apt apt-get add-apt-repository apt-add-repository pip pip3 pipx pyenv poetry curl wget ln code code-server npm"

absolute_tool() {
    builtin command -v "$1"
}

write_stub() {
    local path="$1"

    cat > "$path"
    chmod +x "$path"
}

# A stub interpreter that records its own invocations, reports a fixed
# `--version` line, and materializes a fake virtual environment whose
# interpreter is a second recording stub.
write_python_stub() {
    local path="$1"
    local label="$2"
    local version="$3"
    local version_status="$4"
    local venv_create="$5"
    local log="$6"
    local venv_python="$7"

    write_stub "$path" <<EOF
#!/bin/sh
printf '%s\n' "$label \$*" >> "$log"
if [ "\$1" = "--version" ]; then
    if [ -n "$version" ]; then
        printf '%s\n' "$version"
    fi
    exit $version_status
fi
if [ "\$1" = "-m" ] && [ "\$2" = "venv" ]; then
    if [ "$venv_create" -ne 0 ]; then
        exit "$venv_create"
    fi
    "$(absolute_tool mkdir)" -p "\$3/bin"
    "$(absolute_tool cp)" "$venv_python" "\$3/bin/python"
    exit 0
fi
exit 0
EOF
}

# Shell state and protected files the module must never touch: the aliases and
# rc files a user's shell loads, plus this repo's own shell configuration.
snapshot_shell_state() {
    local root
    local path

    alias -p 2>/dev/null | LC_ALL=C sort
    for root in "$@"; do
        while IFS= read -r path; do
            if [ -f "$path" ]; then
                printf '%s %s\n' "$path" "$(cksum < "$path")"
            else
                printf '%s\n' "$path"
            fi
        done < <(find "$root" -mindepth 1 | LC_ALL=C sort)
    done
}

# Drive `install_python` under observation.
#
# Options are key=value pairs:
#   os=ubuntu|macos|<other>        detected platform
#   python=present|missing        whether a python3 exists on PATH
#   version=<text>                first line printed by `python3 --version`
#   version_status=<int>          exit status of `python3 --version`
#   venv_create=<int>             exit status of `python3 -m venv DIR`
#   venv_run=<int>                exit status of the created venv interpreter
#   package_failure=<name>        package name the package seam refuses
#   brew_formula=present|absent   whether `brew list python` succeeds
#   brew_upgrade=<int>            exit status of `brew upgrade python`
#   brew_upgrade_output=<text>    what `brew upgrade python` prints
#   brew_python=<version text>    version reported by Homebrew's own
#                                 interpreter, or "missing" for a prefix that
#                                 provides none (defaults to `version` on macOS)
#
# Sets in the caller's shell:
#   OBSERVED_STATUS      exit status of install_python
#   OBSERVED_COMMANDS    ordered log of package-seam and command invocations
#   OBSERVED_OUTPUT      combined stdout/stderr of the module
#   OBSERVED_LEAKS       temporary paths left behind ("" when nothing leaked)
#   OBSERVED_STATE_DIFF  change in aliases and protected files ("" when none)
run_install_python() {
    local option
    local work
    local tool
    local os="ubuntu"
    local python="present"
    local version="Python 3.12.3"
    local version_status=0
    local venv_create=0
    local venv_run=0
    local package_failure=""
    local brew_formula="absent"
    local brew_upgrade=0
    local brew_upgrade_output=""
    local brew_python=""

    for option in "$@"; do
        case "$option" in
            os=*) os="${option#*=}" ;;
            python=*) python="${option#*=}" ;;
            version=*) version="${option#*=}" ;;
            version_status=*) version_status="${option#*=}" ;;
            venv_create=*) venv_create="${option#*=}" ;;
            venv_run=*) venv_run="${option#*=}" ;;
            package_failure=*) package_failure="${option#*=}" ;;
            brew_formula=*) brew_formula="${option#*=}" ;;
            brew_upgrade=*) brew_upgrade="${option#*=}" ;;
            brew_upgrade_output=*) brew_upgrade_output="${option#*=}" ;;
            brew_python=*) brew_python="${option#*=}" ;;
            *) fail "unknown run_install_python option: $option" ;;
        esac
    done

    # Homebrew provisioning is what macOS runs are about, so its prefix carries
    # an interpreter unless a test says otherwise.
    if [ "$os" == "macos" ] && [ -z "$brew_python" ]; then
        brew_python="$version"
    fi

    new_tmp_var work
    mkdir -p "$work/bin" "$work/tmpdir" "$work/cwd" "$work/brew/opt/python/bin" "$work/home"
    printf 'export EDITOR=nvim\n' > "$work/home/.zshrc"
    printf '# dotfiles customizations\n' > "$work/home/.zshrc.custom"
    printf 'export EDITOR=nvim\n' > "$work/home/.bashrc"
    : > "$work/commands"

    for tool in $REAL_TOOLS; do
        ln -s "$(absolute_tool "$tool")" "$work/bin/$tool"
    done

    for tool in $FORBIDDEN_TOOLS; do
        write_stub "$work/bin/$tool" <<EOF
#!/bin/sh
printf '%s\n' "$tool \$*" >> "$work/commands"
exit 0
EOF
    done

    write_stub "$work/venv-python" <<EOF
#!/bin/sh
printf '%s\n' "venv-interpreter \$*" >> "$work/commands"
exit $venv_run
EOF

    if [ "$python" == "present" ]; then
        write_python_stub "$work/bin/python3" "python3" "$version" "$version_status" \
            "$venv_create" "$work/commands" "$work/venv-python"
    fi

    if [ -n "$brew_python" ] && [ "$brew_python" != "missing" ]; then
        write_python_stub "$work/brew/opt/python/bin/python3" "brew-python3" "$brew_python" 0 \
            "$venv_create" "$work/commands" "$work/venv-python"
    fi

    write_stub "$work/bin/brew" <<EOF
#!/bin/sh
printf '%s\n' "brew \$*" >> "$work/commands"
case "\$1" in
    list)
        [ "$brew_formula" = present ] || exit 1
        ;;
    upgrade)
        [ -z "$brew_upgrade_output" ] || printf '%s\n' "$brew_upgrade_output"
        exit $brew_upgrade
        ;;
    --prefix)
        printf '%s\n' "$work/brew/opt/python"
        ;;
esac
exit 0
EOF

    OBSERVED_STATUS=0
    (
        local host_path="$PATH"
        local status=0

        cd "$work/cwd" || exit 99
        HOME="$work/home"
        export HOME
        snapshot_shell_state "$work/home" "$DOTFILES_DIR/zsh" > "$work/state.before"

        PATH="$work/bin"
        TMPDIR="$work/tmpdir"
        export PATH TMPDIR

        OS="$os"
        case "$os" in
            ubuntu) PACKAGE_MANAGER="apt" ;;
            macos) PACKAGE_MANAGER="brew" ;;
            *) PACKAGE_MANAGER="" ;;
        esac

        # The package seam is an integrated dependency; record the exact calls
        # and report the injected failure instead of running a package manager.
        install_package() {
            printf '%s\n' "install_package $*" >> "$work/commands"
            if [ -n "$package_failure" ] && [ "$1" == "$package_failure" ]; then
                return 1
            fi
            return 0
        }

        # `run_module` invokes module functions in a condition context, which
        # suppresses errexit inside them. Call it the same way so the module
        # owns every failure return instead of leaning on `set -e`.
        install_python || status=$?

        PATH="$host_path"
        snapshot_shell_state "$work/home" "$DOTFILES_DIR/zsh" > "$work/state.after"

        exit $status
    ) > "$work/out" 2>&1 || OBSERVED_STATUS=$?

    # The temporary venv path is freshly allocated on every run; collapse it to
    # a placeholder so command logs stay exactly comparable.
    OBSERVED_COMMANDS="$(sed "s|$work/tmpdir/[^ ]*|<tmp>|g" "$work/commands")"
    OBSERVED_OUTPUT="$(cat "$work/out")"
    OBSERVED_LEAKS="$(find "$work/tmpdir" "$work/cwd" -mindepth 1 | LC_ALL=C sort)"
    OBSERVED_STATE_DIFF="$(diff "$work/state.before" "$work/state.after" || true)"
}

assert_commands() {
    local expected="$1"

    [[ "$OBSERVED_COMMANDS" == "$expected" ]] || fail "unexpected command log:
--- expected ---
$expected
--- actual ---
$OBSERVED_COMMANDS"
}

assert_no_leaks() {
    [[ -z "$OBSERVED_LEAKS" ]] || fail "temporary state leaked:
$OBSERVED_LEAKS"
}

assert_output_contains() {
    local needle="$1"

    [[ "$OBSERVED_OUTPUT" == *"$needle"* ]] || fail "expected output to mention '$needle', got:
$OBSERVED_OUTPUT"
}

# No privileged, repository, global-package, editor, or system-link command may
# ever appear, and no alias or protected shell file may change, on any path.
assert_ownership_boundary() {
    local tool

    for tool in $FORBIDDEN_TOOLS; do
        [[ "$OBSERVED_COMMANDS" != *"$tool "* ]] ||
            fail "module reached for '$tool' outside its ownership:
$OBSERVED_COMMANDS"
    done

    [[ -z "$OBSERVED_STATE_DIFF" ]] || fail "module changed aliases or protected shell state:
$OBSERVED_STATE_DIFF"
}

# ---------------------------------------------------------------------------
# Cycle A — native package-manager paths
# ---------------------------------------------------------------------------

test_ubuntu_installs_native_interpreter_and_venv_packages() {
    source_install

    run_install_python os=ubuntu

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected success, got $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    assert_commands "install_package python3
install_package python3-venv
python3 --version
python3 -m venv <tmp>
venv-interpreter --version"
    assert_ownership_boundary
    assert_no_leaks
}

test_macos_installs_homebrew_formula_when_absent() {
    source_install

    run_install_python os=macos brew_formula=absent

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected success, got $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_COMMANDS" == *"install_package python python"* ]] ||
        fail "expected the Homebrew python formula to be installed through the package seam:
$OBSERVED_COMMANDS"
    [[ "$OBSERVED_COMMANDS" != *"brew upgrade"* ]] ||
        fail "expected no upgrade request when the formula is absent:
$OBSERVED_COMMANDS"
    [[ "$OBSERVED_COMMANDS" != *"install_package python3"* ]] ||
        fail "expected no Ubuntu package names on macOS:
$OBSERVED_COMMANDS"
    assert_ownership_boundary
    assert_no_leaks
}

test_macos_upgrades_homebrew_formula_when_present() {
    source_install

    run_install_python os=macos brew_formula=present

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected success, got $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_COMMANDS" == *"brew upgrade python"* ]] ||
        fail "expected 'brew upgrade python' when the formula is present:
$OBSERVED_COMMANDS"
    [[ "$OBSERVED_COMMANDS" != *"install_package"* ]] ||
        fail "expected no fresh install when the formula is present:
$OBSERVED_COMMANDS"
    assert_ownership_boundary
    assert_no_leaks
}

# Homebrew refuses to upgrade an already-current formula on some versions. That
# is the expected steady state, not a failure worth warning about.
test_macos_already_current_formula_is_not_reported_as_a_failure() {
    source_install

    run_install_python os=macos brew_formula=present brew_upgrade=1 \
        brew_upgrade_output="Warning: python 3.12.3 already installed"

    [[ "$OBSERVED_STATUS" -eq 0 ]] ||
        fail "expected an already-current formula to succeed, got $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    assert_output_contains "already current"
    [[ "$OBSERVED_OUTPUT" != *"[WARNING]"* ]] ||
        fail "expected no warning for an already-current formula:
$OBSERVED_OUTPUT"
    assert_ownership_boundary
    assert_no_leaks
}

# A genuine upgrade error is reported, but the installed formula still decides
# the outcome through verification rather than Homebrew's status.
test_macos_genuine_upgrade_error_warns_and_still_verifies() {
    source_install

    run_install_python os=macos brew_formula=present brew_upgrade=1 \
        brew_upgrade_output="Error: Failed to download resource python"

    [[ "$OBSERVED_STATUS" -eq 0 ]] ||
        fail "expected a failed upgrade to fall through to verification, got $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    assert_output_contains "[WARNING]"
    assert_output_contains "brew upgrade python"
    [[ "$OBSERVED_OUTPUT" != *"already current"* ]] ||
        fail "expected a genuine error not to be reported as an already-current formula:
$OBSERVED_OUTPUT"
    [[ "$OBSERVED_COMMANDS" == *"venv-interpreter "* ]] ||
        fail "expected verification to still run after a failed upgrade:
$OBSERVED_COMMANDS"
    assert_ownership_boundary
    assert_no_leaks
}

# ---------------------------------------------------------------------------
# Package-seam failures
# ---------------------------------------------------------------------------

test_ubuntu_interpreter_package_failure_stops_before_the_venv_package() {
    source_install

    run_install_python os=ubuntu package_failure=python3

    [[ "$OBSERVED_STATUS" -ne 0 ]] ||
        fail "expected a failed python3 package install to fail the module: $OBSERVED_OUTPUT"
    assert_commands "install_package python3"
    assert_output_contains "python3 package"
    assert_native_source_guidance
    assert_ownership_boundary
    assert_no_leaks
}

test_ubuntu_venv_package_failure_stops_before_verification() {
    source_install

    run_install_python os=ubuntu package_failure=python3-venv

    [[ "$OBSERVED_STATUS" -ne 0 ]] ||
        fail "expected a failed python3-venv package install to fail the module: $OBSERVED_OUTPUT"
    assert_commands "install_package python3
install_package python3-venv"
    assert_output_contains "python3-venv package"
    assert_native_source_guidance
    assert_ownership_boundary
    assert_no_leaks
}

test_macos_formula_install_failure_stops_before_verification() {
    source_install

    run_install_python os=macos brew_formula=absent package_failure=python

    [[ "$OBSERVED_STATUS" -ne 0 ]] ||
        fail "expected a failed formula install to fail the module: $OBSERVED_OUTPUT"
    assert_commands "brew list python
install_package python python"
    assert_output_contains "Homebrew python formula"
    assert_native_source_guidance
    assert_ownership_boundary
    assert_no_leaks
}

test_packages_are_installed_before_verification() {
    local package_line
    local verify_line

    source_install

    run_install_python os=ubuntu

    package_line="$(printf '%s\n' "$OBSERVED_COMMANDS" | grep -n '^install_package python3-venv$' | cut -d: -f1 || true)"
    verify_line="$(printf '%s\n' "$OBSERVED_COMMANDS" | grep -n '^python3 ' | cut -d: -f1 | head -n1 || true)"

    [[ -n "$package_line" && -n "$verify_line" ]] ||
        fail "expected both package installation and interpreter verification:
$OBSERVED_COMMANDS"
    [[ "$package_line" -lt "$verify_line" ]] ||
        fail "expected package installation before interpreter verification:
$OBSERVED_COMMANDS"
}

test_unsupported_platform_fails_without_installing_anything() {
    source_install

    run_install_python os=freebsd

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected an unsupported platform to fail"
    assert_commands ""
    assert_no_leaks
}

test_python_module_dispatches_independently() {
    local tmp
    local log

    source_install
    new_tmp_var tmp
    log="$tmp/dispatch.log"

    install_python() { printf 'install_python\n' >> "$log"; }
    install_vscode() { printf 'install_vscode\n' >> "$log"; }
    configure_vscode() { printf 'configure_vscode\n' >> "$log"; }
    install_code_server() { printf 'install_code_server\n' >> "$log"; }
    install_base_tools() { printf 'install_base_tools\n' >> "$log"; }

    FAILED_MODULES=()
    COMPLETED_MODULES=()
    execute_modules python > "$tmp/execute.out"

    [[ "$(cat "$log")" == "install_python" ]] ||
        fail "expected python to dispatch alone, got: $(tr '\n' ' ' < "$log")"
    [[ "${COMPLETED_MODULES[*]}" == "python" ]] ||
        fail "expected python completed, got: ${COMPLETED_MODULES[*]}"

    unset -f install_python install_vscode configure_vscode install_code_server install_base_tools
}

test_python_selection_requires_package_manager_update_without_editor_dependency() {
    source_install

    modules_require_package_manager_update python ||
        fail "expected the python module to require a package-manager update"

    OS="macos"
    [[ "$(resolve_dependencies python | tr '\n' ' ')" == "python " ]] ||
        fail "expected python to resolve with no dependencies, got: $(resolve_dependencies python | tr '\n' ' ')"
}

# ---------------------------------------------------------------------------
# Cycle B — semantic version boundary
# ---------------------------------------------------------------------------

NATIVE_SOURCE_GUIDANCE="native package source that provides Python 3.10 or newer"
NO_REPOSITORY_GUIDANCE="never adds a third-party repository"

assert_native_source_guidance() {
    assert_output_contains "$NATIVE_SOURCE_GUIDANCE"
    assert_output_contains "$NO_REPOSITORY_GUIDANCE"
}

assert_no_venv_attempt() {
    [[ "$OBSERVED_COMMANDS" != *"-m venv"* ]] ||
        fail "expected verification to stop before creating a virtual environment:
$OBSERVED_COMMANDS"
}

test_versions_at_or_above_the_requirement_are_accepted() {
    local reported

    source_install

    for reported in "3.10.0" "3.10" "3.10.14" "3.12.3" "3.100.0" "4.0.1"; do
        run_install_python os=ubuntu "version=Python $reported"
        [[ "$OBSERVED_STATUS" -eq 0 ]] ||
            fail "expected Python $reported to be accepted, got status $OBSERVED_STATUS: $OBSERVED_OUTPUT"
        [[ "$OBSERVED_COMMANDS" == *"venv-interpreter "* ]] ||
            fail "expected Python $reported to reach venv verification:
$OBSERVED_COMMANDS"
    done
}

test_versions_below_the_requirement_are_rejected_with_native_source_guidance() {
    local reported

    source_install

    for reported in "3.9.18" "3.9" "3.2.0" "2.7.18" "0.9.9"; do
        run_install_python os=ubuntu "version=Python $reported"
        [[ "$OBSERVED_STATUS" -ne 0 ]] ||
            fail "expected Python $reported to be rejected: $OBSERVED_OUTPUT"
        assert_output_contains "$reported"
        assert_native_source_guidance
        assert_no_venv_attempt
        assert_ownership_boundary
        assert_no_leaks
    done
}

test_unreadable_version_output_is_rejected_with_native_source_guidance() {
    local reported

    source_install

    for reported in "Python banana" "Python" "" "Python 3" "Python three.ten" "Python 3.x" "Python .10"; do
        run_install_python os=ubuntu "version=$reported"
        [[ "$OBSERVED_STATUS" -ne 0 ]] ||
            fail "expected version output '$reported' to be rejected: $OBSERVED_OUTPUT"
        assert_native_source_guidance
        assert_no_venv_attempt
        assert_no_leaks
    done
}

test_failing_version_query_is_rejected_with_native_source_guidance() {
    source_install

    run_install_python os=ubuntu version="" version_status=1

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected a failing version query to be rejected"
    assert_native_source_guidance
    assert_no_venv_attempt
    assert_no_leaks
}

test_missing_interpreter_is_rejected_with_native_source_guidance() {
    source_install

    run_install_python os=ubuntu python=missing

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected a missing interpreter to be rejected"
    assert_native_source_guidance
    assert_ownership_boundary
    assert_no_leaks
}

# Fresh macOS: the formula must be installed first, and only Homebrew's own
# prefix may supply the interpreter that is verified.
test_macos_fresh_install_installs_the_formula_before_its_own_interpreter() {
    source_install

    run_install_python os=macos brew_formula=absent version="Python 3.9.6" brew_python="Python 3.12.3"

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected success, got $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    assert_commands "brew list python
install_package python python
brew --prefix python
brew-python3 --version
brew-python3 -m venv <tmp>
venv-interpreter --version"
    assert_ownership_boundary
    assert_no_leaks
}

# Without an interpreter under Homebrew's prefix there is nothing this module
# provisioned, so a python3 on PATH must not stand in for it.
test_macos_without_a_homebrew_interpreter_does_not_use_path_python() {
    source_install

    run_install_python os=macos brew_formula=present brew_python=missing version="Python 3.12.3"

    [[ "$OBSERVED_STATUS" -ne 0 ]] ||
        fail "expected a missing Homebrew interpreter to fail the module: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_COMMANDS" != *"python3 --version"* ]] ||
        fail "expected no PATH python3 to be consulted on macOS:
$OBSERVED_COMMANDS"
    assert_native_source_guidance
    assert_no_venv_attempt
    assert_ownership_boundary
    assert_no_leaks
}

test_macos_verifies_the_homebrew_interpreter_rather_than_system_python() {
    source_install

    run_install_python os=macos brew_formula=present version="Python 3.9.6" brew_python="Python 3.12.3"

    [[ "$OBSERVED_STATUS" -eq 0 ]] ||
        fail "expected the Homebrew interpreter to be verified, got $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    printf '%s\n' "$OBSERVED_COMMANDS" | grep -qx 'brew-python3 --version' ||
        fail "expected the Homebrew interpreter to be queried:
$OBSERVED_COMMANDS"
    ! printf '%s\n' "$OBSERVED_COMMANDS" | grep -qx 'python3 --version' ||
        fail "expected the system interpreter on PATH not to decide the outcome:
$OBSERVED_COMMANDS"
    assert_ownership_boundary
    assert_no_leaks
}

# ---------------------------------------------------------------------------
# Cycle C — virtual-environment execution and cleanup
# ---------------------------------------------------------------------------

test_verification_runs_the_temporary_venv_interpreter_and_removes_it() {
    source_install

    run_install_python os=ubuntu

    [[ "$OBSERVED_STATUS" -eq 0 ]] || fail "expected success, got $OBSERVED_STATUS: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_COMMANDS" == *"python3 -m venv <tmp>"* ]] ||
        fail "expected a temporary virtual environment to be created:
$OBSERVED_COMMANDS"
    [[ "$OBSERVED_COMMANDS" == *"venv-interpreter "* ]] ||
        fail "expected the temporary environment's own interpreter to run:
$OBSERVED_COMMANDS"
    assert_no_leaks
}

test_failed_venv_creation_fails_the_module_and_removes_temporary_state() {
    source_install

    run_install_python os=ubuntu venv_create=1

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected failed venv creation to fail the module: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_COMMANDS" != *"venv-interpreter "* ]] ||
        fail "expected no interpreter run after a failed creation:
$OBSERVED_COMMANDS"
    assert_output_contains "virtual environment"
    assert_ownership_boundary
    assert_no_leaks
}

test_failed_venv_interpreter_fails_the_module_and_removes_temporary_state() {
    source_install

    run_install_python os=ubuntu venv_run=1

    [[ "$OBSERVED_STATUS" -ne 0 ]] || fail "expected a failing venv interpreter to fail the module: $OBSERVED_OUTPUT"
    [[ "$OBSERVED_COMMANDS" == *"venv-interpreter "* ]] ||
        fail "expected the venv interpreter to have been attempted:
$OBSERVED_COMMANDS"
    assert_output_contains "virtual environment"
    assert_ownership_boundary
    assert_no_leaks
}

test_venv_failures_report_repair_guidance_without_a_repository() {
    local injection

    source_install

    for injection in venv_create=1 venv_run=1; do
        run_install_python os=ubuntu "$injection"
        assert_output_contains "$NO_REPOSITORY_GUIDANCE"
        assert_ownership_boundary
    done
}

# Stub interpreters can only show that the module asked for a virtual
# environment. This drives the real host python3 so a genuine venv is built,
# its own interpreter runs from inside it, and the temporary tree is removed.
test_verify_python_venv_builds_runs_and_removes_a_real_virtual_environment() {
    local host_python
    local tmp
    local removed
    local venv
    local reported_prefix

    source_install

    host_python="$(builtin command -v python3)" ||
        fail "the real virtual-environment contract requires a host python3"

    new_tmp_var tmp
    mkdir -p "$tmp/inspect" "$tmp/cleanup"

    # Defer the module's own removal so the genuine environment can be
    # inspected exactly as it was built; every other path still really deletes.
    rm() {
        local target="${!#}"

        case "$target" in
            "$tmp"/*)
                printf '%s\n' "$target" >> "$tmp/removals"
                return 0
                ;;
        esac

        command rm "$@"
    }

    TMPDIR="$tmp/inspect" verify_python_venv "$host_python" ||
        fail "expected the host interpreter to pass virtual-environment verification"

    unset -f rm

    removed="$(cat "$tmp/removals")"
    [[ "$removed" == "$tmp/inspect/"* ]] ||
        fail "expected the temporary directory to be removed, got: $removed"

    venv="$removed/venv"
    [[ -f "$venv/pyvenv.cfg" && -x "$venv/bin/python" ]] ||
        fail "expected a genuine virtual environment at $venv"

    reported_prefix="$("$venv/bin/python" -c 'import sys; print(sys.prefix)')"
    [[ "$reported_prefix" == "$venv" ]] ||
        fail "expected the venv interpreter to run from inside $venv, got $reported_prefix"
    [[ "$("$venv/bin/python" -c 'import sys; print(sys.prefix != sys.base_prefix)')" == "True" ]] ||
        fail "expected an isolated environment, not the base interpreter"

    command rm -rf "$tmp/inspect"

    # Now with removal left to the module itself: nothing may survive.
    TMPDIR="$tmp/cleanup" verify_python_venv "$host_python" ||
        fail "expected the host interpreter to pass verification again"
    [[ -z "$(find "$tmp/cleanup" -mindepth 1)" ]] ||
        fail "real verification left temporary state behind:
$(find "$tmp/cleanup" -mindepth 1)"
}

# ---------------------------------------------------------------------------
# Ownership boundary — shell state and protected files
# ---------------------------------------------------------------------------

# Provisioning an interpreter never edits shell configuration or defines an
# alias, on the success path or any failure path.
test_module_leaves_aliases_and_protected_shell_files_unchanged() {
    local scenario

    source_install

    for scenario in "os=ubuntu" "os=macos brew_formula=present" "os=ubuntu venv_create=1" \
        "os=ubuntu package_failure=python3" "os=ubuntu python=missing"; do
        # shellcheck disable=SC2086
        run_install_python $scenario
        [[ -z "$OBSERVED_STATE_DIFF" ]] ||
            fail "scenario '$scenario' changed aliases or protected shell files:
$OBSERVED_STATE_DIFF"
    done
}

run_tests "install python"
