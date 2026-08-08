# VS Code Configuration Specification

> **Version**: 1.0.0
> **Last Updated**: 2026-07-31
> **Implementation Status**: Approved desired behavior; not yet implemented
> **Depends On**: [Parameters](parameters.md), [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md), [Design Language](DESIGN_LANGUAGE.md), [Symlink Manager](symlink-manager.md), [Tool Provisioning](tool-provisioning.md)
> **Depended By**: Install Orchestrator

---

## Overview

The VS Code configuration system provides one repository-authoritative **VS Code managed layer** for two editor targets:

1. Official stable Visual Studio Code Desktop on macOS
2. `code-server` on Ubuntu/Debian as an explicitly selected **private-network browser endpoint**

The managed layer preserves user settings, keybindings, snippets, and a curated extension catalog without taking ownership of mutable editor state, credentials, profiles, certificates, or machine-specific network values. Both targets share editor behavior where their extension marketplaces permit it, while target-specific extension manifests absorb marketplace and licensing differences.

Desktop Visual Studio Code is included in the macOS `full` and `work` installation profiles. `code-server` is custom-only because selecting it installs and enables a persistent authenticated network service. Desktop Visual Studio Code on Linux, `code-server` on macOS, Windows, GitHub Codespaces, and Microsoft Remote Tunnels are outside this specification.

---

## Dependencies

### Technology Dependencies

| Dependency | Target | Purpose |
|------------|--------|---------|
| Official Visual Studio Code | macOS only | Desktop editor and extension CLI |
| Homebrew Cask | macOS only | Desktop installation and stable updates |
| code-server | Ubuntu/Debian only | Browser-accessible editor service |
| Service manager | Ubuntu/Debian only | Enable and run the per-user code-server service |
| HTTPS-capable client | code-server | Access the generated-certificate endpoint |
| Git | Both | Review write-through changes to managed settings |
| Python 3.10+ | Optional, both | Execute Python projects; provisioned independently |
| Node.js | Optional, both | Execute Node.js projects; provisioned independently |

### Spec Dependencies

| Spec | Reason |
|------|--------|
| [Parameters](parameters.md) | Authoritative editor distribution, Python version, bind address, port, paths, and extension catalog values |
| [Ubiquitous Language](../UBIQUITOUS-LANGUAGE.md) | Canonical editor, extension, managed-layer, and private-network terms |
| [Design Language](DESIGN_LANGUAGE.md) | VS Code command, Vim leader command, and browser endpoint interface vocabulary |
| [Symlink Manager](symlink-manager.md) | Individual managed-file deployment, directory backup, and idempotency |
| [Tool Provisioning](tool-provisioning.md) | Visual Studio Code, code-server, and Python installation/update behavior |

---

## Parameters

All values are defined and rationalized in [Parameters](parameters.md).

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `VSCODE_DESKTOP_PLATFORM` | macOS | Only supported desktop target |
| `VSCODE_DESKTOP_DISTRIBUTION` | Official stable Visual Studio Code | Retains Microsoft Marketplace and Remote SSH compatibility |
| `VSCODE_MACOS_CASK` | visual-studio-code | Homebrew Cask identity |
| `VSCODE_SETTINGS_SYNC` | manual-off | Repository remains authoritative without unsupported internal mutation |
| `CODE_SERVER_PLATFORM` | Ubuntu/Debian | Only supported browser-server target |
| `CODE_SERVER_BIND_DEFAULT` | 0.0.0.0:8080 | Private-network accessibility with a conventional development port |
| `CODE_SERVER_AUTH` | password | Application authentication remains required regardless of network transport |
| `CODE_SERVER_CERT` | generated HTTPS certificate | Encrypts browser traffic without tracked certificate material |
| `PYTHON_REQUIRED_VERSION` | 3.10 | Baseline compatible with native packages on supported Ubuntu releases |
| `VSCODE_VIM_LEADER` | Space | Matches the Neovim leader key |
| `VSCODE_EXTENSION_VERSION_MODE` | unpinned by default | Permits compatible updates while retaining exceptional pins |
| `VSCODE_EXTENSION_RECONCILIATION` | install/update, no prune | Enforces managed presence without removing experimentation |

---

## Data Structures

### Managed Layer

| Source | Target on macOS Desktop | Target on Ubuntu/Debian code-server | Ownership |
|--------|-------------------------|-------------------------------------|-----------|
| `vscode/settings.json` | User settings file | User settings file | Repository-owned shared file |
| `vscode/keybindings.json` | User keybindings file | User keybindings file | Repository-owned shared file |
| `vscode/snippets/` | User snippets directory | User snippets directory | Repository-owned shared directory |
| `vscode/extensions/shared.txt` | Reconciled through desktop extension CLI | Reconciled through code-server extension CLI | Repository-owned shared manifest |
| `vscode/extensions/desktop.txt` | Reconciled through desktop extension CLI | Not consumed | Repository-owned desktop manifest |
| `vscode/extensions/code-server.txt` | Not consumed | Reconciled through code-server extension CLI | Repository-owned server manifest |

The managed layer MUST NOT include the entire editor User directory.

### Local Runtime State

| State | Location class | Ownership rule |
|-------|----------------|----------------|
| Authentication and accounts | Editor runtime storage | Local, untracked |
| Settings Sync state | Desktop runtime storage | Local, manually disabled |
| UI layout and extension global state | Editor runtime storage | Local, untracked |
| History and workspace storage | Editor runtime storage | Local, untracked |
| Named profile internals | Editor runtime storage | Local, untracked |
| Runtime arguments | Machine-specific editor file | Local, untracked |
| code-server bind value | Local code-server config | Local, preserved across reruns |
| code-server password | Local code-server config | Local, generated and never logged |
| code-server certificate and key | Local code-server data | Local, generated and untracked |

### Extension Manifest Entry

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| extension_id | string | Required; publisher.name form | Marketplace identity |
| version | string | Optional | Explicit compatibility pin |
| target | enum | shared, desktop, code-server | Manifest containing the entry |

An unpinned entry has the form `publisher.name`. A pinned entry has the form `publisher.name@version`. Blank lines and comments MAY be used for organization and MUST NOT be interpreted as extension identities.

### Required Extension Catalog

| Target | Extension ID | Capability |
|--------|--------------|------------|
| Shared | `EditorConfig.EditorConfig` | Project indentation and editor conventions |
| Shared | `charliermarsh.ruff` | Python linting and formatting |
| Shared | `dbaeumer.vscode-eslint` | JavaScript/TypeScript linting and fix actions |
| Shared | `esbenp.prettier-vscode` | Project-conditioned formatting |
| Shared | `yzhang.markdown-all-in-one` | Markdown authoring and formatting |
| Shared | `tamasfe.even-better-toml` | TOML language support |
| Shared | `MermaidChart.vscode-mermaid-chart` | Mermaid diagram authoring and preview |
| Shared | `GitHub.vscode-github-actions` | Workflow authoring and run visibility |
| Shared | `vscodevim.vim` | Portable Vim emulation |
| Desktop | `ms-python.python` | Python language, environment, and test integration |
| Desktop | `ms-python.vscode-pylance` | Python code intelligence and basic type checking |
| Desktop | `ms-python.debugpy` | Python debugging |
| Desktop | `ms-python.vscode-python-envs` | Python environment discovery and management UI |
| Desktop | `ms-vscode-remote.remote-ssh` | Remote development over generic SSH transport |
| code-server | `ms-python.python` | Python language, environment, and test integration |
| code-server | `detachhead.basedpyright` | Open VSX-compatible Python code intelligence |
| code-server | `ms-python.debugpy` | Python debugging |

### Capture Result

| Field | Type | Description |
|-------|------|-------------|
| settings | file | Copy of current desktop user settings |
| keybindings | file | Copy of current desktop user keybindings |
| snippets | directory | Copy of current desktop snippets |
| captured_extensions | list | Current desktop extension IDs, initially classified as desktop-only |

---

## Behavior

### Authority and Deployment

1. The repository MUST be authoritative for every managed-layer source.
2. Each managed file MUST be deployed individually; the complete User directory MUST NOT be symlinked.
3. The snippets directory MUST be deployed as one directory-level symlink.
4. Editing a deployed managed file through either editor MUST write through to the repository source.
5. Mutable local runtime state MUST remain outside symlink ownership.
6. Workspace and language-specific workspace settings MAY override managed user defaults according to editor precedence rules.

### Initial Capture

The system MUST provide an explicit capture command under the `vscode/` module for use on the macOS machine containing the existing setup.

```
WHEN capture is explicitly requested:
  Require an available desktop editor command interface
  Read current settings, keybindings, snippets, and installed extension IDs
  Refuse to overwrite an existing managed source unless force was explicitly selected
  Store captured extensions as desktop-only candidates
  Report that credentials and machine-specific paths require review
  Do not deploy configuration
END WHEN
```

Normal installation MUST NOT invoke capture or mutate repository sources. Captured extensions MUST remain desktop-only until deliberately promoted to the shared manifest. Captured versions MUST be omitted by default.

### Desktop Visual Studio Code

1. Desktop support MUST be available only on macOS.
2. The `vscode` module MUST install or request an update of official stable Visual Studio Code through Homebrew Cask.
3. The `vscode_config` module MUST conditionally require `vscode` when the desktop editor command is unavailable.
4. macOS `full` and `work` profiles MUST include `vscode` and `vscode_config`.
5. Explicit desktop-module selection on Ubuntu/Debian MUST fail with an unsupported-platform error.
6. The installer MUST idempotently disable macOS press-and-hold for official Visual Studio Code so held Vim movement keys repeat.

### Settings Sync Boundary

1. Settings Sync MUST NOT be an authority for the managed Default Profile.
2. The user MUST disable Settings Sync manually for settings and extensions.
3. The installer MUST NOT modify undocumented editor databases, patch the application bundle, or invalidate the application signature to enforce this state.
4. The installer MUST report the manual Settings Sync action after desktop configuration.
5. Unexpected cloud-originated writes to symlinked managed files MUST remain visible as repository changes.

This is a supported-platform limitation: manual disablement is required because official Visual Studio Code exposes no supported persistent enforcement interface.

### Extension Reconciliation

For each target, reconcile the shared manifest followed by its target-specific manifest.

```
failures = empty list
FOR EACH valid manifest entry:
  IF entry is absent OR its explicit version is not active:
    Attempt install or update
  ELSE IF entry is unpinned:
    Permit reconciliation to a compatible current release
  END IF
  IF reconciliation failed:
    Append entry to failures
  END IF
END FOR
IF failures is not empty:
  Report every failed entry
  Fail the owning module
END IF
```

Unlisted extensions MUST NOT be removed, disabled, or added to a manifest automatically. Installing an extension through the editor UI does not make it managed. Marketplace availability differences MUST be represented by target-specific manifests rather than silently ignoring failed shared entries.

### Python Editor Support

1. Desktop MUST use the Python extension with Pylance; code-server MUST use the Python extension with BasedPyright.
2. Type checking MUST default to basic mode and diagnostics MUST focus on open files.
3. `.venv`, `venv`, and Poetry environments MUST be discoverable through editor environment support.
4. Ruff MUST provide Python diagnostics and formatting.
5. Python files MUST format on save through Ruff.
6. Debugging MUST use debugpy.
7. Pytest and unittest discovery MUST be available without globally forcing one framework.
8. Python runtime installation and project packages MUST remain outside editor-configuration ownership.

### TypeScript and JavaScript Editor Support

1. The built-in TypeScript/JavaScript language service MUST provide code intelligence.
2. The built-in JavaScript debugger MUST remain the default debugger.
3. Prettier MUST format supported files on save only when the project contains Prettier configuration.
4. ESLint MUST provide diagnostics and safe fix actions only when the project contains ESLint configuration.
5. Prettier MUST remain the formatter when both Prettier and ESLint are configured; ESLint MUST provide fix actions rather than compete as a formatter.
6. TypeScript, ESLint, Prettier, Node.js, and test frameworks MUST NOT be installed globally by editor configuration.
7. No global Jest, Vitest, or Playwright test adapter MUST be selected; projects MAY provide their own.

### Markdown Editor Support

1. Markdown MUST format through Markdown All in One rather than Prettier, so list numbering, table alignment, and table-of-contents structure are maintained by the extension that owns them.

### VSCodeVim Behavior

1. The shared extension catalog MUST include VSCodeVim and MUST NOT include a competing embedded-Neovim extension.
2. The Vim leader key MUST be Space.
3. System clipboard integration, relative line numbers, incremental search, and highlighted matches MUST be enabled.
4. Emulated surround and EasyMotion behavior MUST be enabled.
5. Managed leader mappings MUST cover formatting, diagnostics, file navigation, Git, testing, and debugging.
6. Browser/editor shortcuts that must take precedence MUST be explicitly excluded from Vim handling.
7. The managed layer MUST NOT load `.vimrc` or couple VSCodeVim to the Lua-based Neovim custom layer.

### code-server Installation and Service Lifecycle

1. `code_server` MUST be selectable only explicitly through custom module selection or `--modules`.
2. It MUST be supported only on Ubuntu/Debian; explicit selection on macOS MUST fail.
3. The module MUST install or update code-server through its official installer.
4. The module MUST reconcile the shared settings, keybindings, snippets, and extension manifests.
5. The service MUST be enabled at boot and left running after successful installation.
6. A configuration or version change MUST cause a service restart before verification.
7. Success requires both an active service and a responding local HTTPS endpoint.
8. Service or health-check failure MUST fail the module.

### Private-Network Browser Endpoint

1. First installation MUST default to `0.0.0.0:8080`.
2. `--code-server-bind <address:port>` MUST override the first-install default or existing local value.
3. A rerun without the flag MUST preserve the existing local bind value.
4. The selected bind value MUST remain in local code-server configuration and MUST NOT be written into tracked files.
5. If the selected port is occupied, installation MUST fail without choosing another port.
6. HTTPS and password authentication MUST remain enabled.
7. Password and certificate material MUST be generated locally, preserved across reruns, and omitted from logs.
8. The completion report MUST identify the local configuration location without printing the password.
9. The installer MUST NOT alter firewall rules.
10. Tracked files and documentation MUST describe generic private-network access without naming, discovering, or configuring a particular network product.
11. Operators remain responsible for restricting listener reachability to trusted networks and accepting or separately trusting the generated certificate.

### Language Runtime Boundary

1. Editor configuration MUST not depend on the independently selectable `python` or `nodejs` modules.
2. Missing Python or Node.js runtimes MUST produce warnings, not editor-configuration failure.
3. Extension, editor installation, service, and endpoint failures retain their normal failure behavior.

---

## Error Handling

| Error Case | Trigger | Detection | Response | Recovery |
|------------|---------|-----------|----------|----------|
| Unsupported desktop platform | `vscode` or `vscode_config` selected outside macOS | Platform identity | Fail selected module with supported-platform message | Select supported target |
| Unsupported server platform | `code_server` selected outside Ubuntu/Debian | Platform identity | Fail selected module with supported-platform message | Select supported target |
| Existing unmanaged setting file | Non-symlink exists at managed target | Filesystem classification | Back up with timestamp, then deploy source | Recover from backup or run capture first |
| Capture destination exists | Capture would overwrite repository source | Source existence check | Refuse unless force was explicit | Review existing source or force intentionally |
| Capture may contain sensitive data | Settings include unknown user values | Capture completion | Warn and require review before commit | Remove credentials and machine-specific paths |
| Required extension unavailable | Marketplace cannot resolve or install entry | Extension command failure | Continue catalog, aggregate failures, fail module | Correct manifest/marketplace or retry |
| Settings Sync remains enabled | User has not disabled it | No supported reliable detection | Report mandatory manual action; do not claim enforcement | Disable through desktop UI |
| Missing Python runtime | No compatible interpreter detected | Runtime lookup | Warn only | Select `python` module or project runtime |
| Missing Node.js runtime | No Node.js executable detected | Runtime lookup | Warn only | Select `nodejs` module or project runtime |
| Bind port occupied | Another process owns selected port | Pre-start bind check or startup failure | Fail without alternate port | Stop conflict or choose explicit bind |
| Service start failure | code-server service is not active | Service manager status | Fail module and retain logs | Inspect service logs, correct config, rerun |
| HTTPS health failure | Local endpoint does not respond after start | HTTPS request accepting generated certificate | Fail module | Inspect listener, certificate, and service logs |
| Existing local code-server config | Config contains password/bind state | Local config parse | Preserve secrets and bind unless explicitly overridden; back up before unsafe replacement | Restore backup if reconciliation fails |
| Generated certificate warning | Browser does not trust local certificate | Browser TLS validation | Document expected warning | Accept warning or establish trust externally |

---

## Implementation Notes

1. **Desired versus implemented:** Every behavior in this specification is approved desired behavior until corresponding implementation and tests are added.
2. **Individual symlinks:** Settings and keybindings are file symlinks; snippets is one directory symlink. Never symlink the whole User directory.
3. **Shared settings constraint:** Both targets consume the same settings and keybindings sources. Target-specific marketplace differences belong in extension manifests, not duplicated settings files.
4. **Local secret preservation:** code-server configuration is local mutable state. Reconciliation may enforce non-secret invariants but must preserve generated secrets and existing bind values.
5. **No security by obscurity:** Generic private-network wording prevents disclosure of private infrastructure, but HTTPS, password authentication, and operator firewall responsibility remain mandatory.
6. **No pruning:** The manifest is a required-presence declaration, not an exact inventory. This permits extension experimentation without accidental removal.
7. **Project configuration wins:** Prettier and ESLint activation depends on project configuration to avoid silently reformatting projects that do not use those tools.
8. **Marketplace validation:** Shared entries must be verified against both target marketplaces during implementation. Required-entry failure is intentionally blocking.
9. **Capture separation:** Capture writes repository sources; deployment writes system targets. They are separate operations and must not be conflated.
10. **Default Profile only:** Named VS Code profiles and profile associations remain unmanaged.

---

## Test Scenarios

TS-VSCODE-001: Capture existing desktop configuration
Category: Integration
Priority: Critical
Preconditions: macOS desktop configuration exists; managed sources do not
Input: Explicit capture command
Expected Output: Settings, keybindings, snippets, and extension IDs are captured; extensions are desktop-only; no deployment occurs

TS-VSCODE-002: Capture refuses overwrite
Category: Unit
Priority: High
Preconditions: Managed settings source already exists
Input: Capture without force
Expected Output: Capture fails before overwriting any managed source

TS-VSCODE-003: Desktop managed files deploy individually
Category: Integration
Priority: Critical
Preconditions: macOS; managed sources exist
Input: `vscode_config`
Expected Output: Settings and keybindings are file symlinks and snippets is one directory symlink; the complete User directory is not a symlink

TS-VSCODE-004: code-server consumes shared managed files
Category: Integration
Priority: Critical
Preconditions: Ubuntu/Debian; code-server installed
Input: `code_server`
Expected Output: code-server user settings, keybindings, and snippets resolve to the same repository sources as desktop

TS-VSCODE-005: Existing desktop settings are backed up
Category: Integration
Priority: Critical
Preconditions: Unmanaged settings file contains user data
Input: `vscode_config`
Expected Output: Existing file is timestamp-backed up before the managed symlink is deployed

TS-VSCODE-006: Extension reconciliation preserves extras
Category: Integration
Priority: High
Preconditions: All managed extensions plus one unmanaged extension are installed
Input: Reconcile extensions
Expected Output: Managed extensions remain installed and the unmanaged extension is untouched

TS-VSCODE-007: Extension failures aggregate
Category: Unit
Priority: Critical
Preconditions: Two required entries cannot be installed
Input: Reconcile extension catalog
Expected Output: Remaining entries are attempted; both failures are reported; owning module fails

TS-VSCODE-008: Optional version pin is respected
Category: Unit
Priority: High
Preconditions: Manifest contains one pinned extension
Input: Reconcile extension catalog
Expected Output: Requested version is active or the owning module fails with that entry reported

TS-VSCODE-009: Python baseline on desktop
Category: Integration
Priority: High
Preconditions: macOS desktop; Python project with virtual environment
Input: Open Python file, format, test discovery, and debug
Expected Output: Pylance provides basic diagnostics, Ruff formats/lints, environment is discoverable, tests are discoverable, and debugpy starts

TS-VSCODE-010: Python baseline on code-server
Category: Integration
Priority: High
Preconditions: Ubuntu/Debian code-server; Python project with virtual environment
Input: Open Python file, format, and debug
Expected Output: BasedPyright provides diagnostics, Ruff formats/lints, environment is discoverable, and debugpy starts

TS-VSCODE-011: Prettier requires project configuration
Category: Integration
Priority: High
Preconditions: One JS project has Prettier config and another does not
Input: Save a JavaScript file in each project
Expected Output: Prettier formats only the configured project

TS-VSCODE-012: ESLint requires project configuration
Category: Integration
Priority: High
Preconditions: One TS project has ESLint config and another does not
Input: Save a TypeScript file in each project
Expected Output: ESLint diagnostics/fix actions apply only to the configured project

TS-VSCODE-013: VSCodeVim shared behavior
Category: Integration
Priority: High
Preconditions: Either target with VSCodeVim installed
Input: Use Space leader, relative navigation, surround, EasyMotion, and clipboard
Expected Output: Managed Vim behavior works without embedded Neovim or vimrc loading

TS-VSCODE-014: macOS key repeat is enabled
Category: Unit
Priority: Medium
Preconditions: macOS press-and-hold is enabled for Visual Studio Code
Input: Run `vscode_config`
Expected Output: Press-and-hold is disabled idempotently for official Visual Studio Code

TS-VSCODE-015: First code-server install uses default bind
Category: Integration
Priority: Critical
Preconditions: Ubuntu/Debian; no local code-server config
Input: `code_server` without bind override
Expected Output: Local bind is `0.0.0.0:8080`; HTTPS and password authentication are enabled

TS-VSCODE-016: Bind override persists
Category: Integration
Priority: Critical
Preconditions: First install uses explicit non-default bind
Input: Rerun `code_server` without bind flag
Expected Output: Existing local bind remains unchanged

TS-VSCODE-017: Occupied code-server port fails
Category: Integration
Priority: Critical
Preconditions: Selected port is owned by another process
Input: `code_server`
Expected Output: Module fails and does not select another port

TS-VSCODE-018: code-server service lifecycle succeeds
Category: End-to-End
Priority: Critical
Preconditions: Supported Ubuntu/Debian host
Input: Explicitly select `code_server`
Expected Output: Stable code-server is installed/updated, configured, enabled, running, extension-complete, and responsive over local HTTPS

TS-VSCODE-019: code-server health failure blocks success
Category: Integration
Priority: Critical
Preconditions: Service cannot answer HTTPS after startup
Input: `code_server`
Expected Output: Health check fails the module and reports service diagnostics without exposing password

TS-VSCODE-020: Unsupported platform selections fail
Category: Unit
Priority: High
Preconditions: macOS for code-server case; Ubuntu/Debian for desktop case
Input: Explicitly select unsupported target module
Expected Output: Selected module fails with clear supported-platform guidance

TS-VSCODE-021: Settings Sync is not falsely reported as enforced
Category: Unit
Priority: High
Preconditions: Desktop config completes
Input: Completion report
Expected Output: Manual disablement action is reported; no unsupported internal mutation or enforcement claim occurs

TS-VSCODE-022: Missing language runtimes only warn
Category: Unit
Priority: Medium
Preconditions: Editor and extensions exist; Python and Node.js do not
Input: Configure target
Expected Output: Runtime warnings are emitted; editor configuration succeeds

TS-VSCODE-023: Tracked artifacts contain no network-product identity
Category: Integration
Priority: Critical
Preconditions: code-server configuration artifacts exist
Input: Scan tracked VS Code/code-server sources and documentation
Expected Output: No particular private-network product name, address, hostname, or command is present

---

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 1.0.0 | 2026-07-31 | Initial approved specification for macOS Visual Studio Code, Ubuntu/Debian code-server, managed settings and extension manifests, language support, VSCodeVim, capture, private-network service security, and lifecycle behavior. |
