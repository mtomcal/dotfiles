# 0002 — Reproducible tool provisioning

**Status:** Accepted

**Later change:** Beads, Herdr, Pi, and agent-sandbox provisioning are superseded by [0014](0014-model-native-agent-environment.md).

**Created:** 2026-08-08

## What shipped

The dotfiles owner can provision a consistent development toolchain on a supported Ubuntu/Debian or macOS machine without learning a separate setup procedure for each platform. The install selects the appropriate package source or official distribution for the host, verifies that required tools are usable, and adds only prerequisites that the current environment lacks.

Provisioning covers the terminal, shell, language runtimes, editors, editor tooling, terminal applications, coding agents, and execution-coordination tooling used by the repository. Existing satisfactory installations are retained when possible. Tools with official idempotent update channels can receive an update request on repeated runs, while version-gated tools change only when they no longer meet the environment’s minimum needs. A completed install leaves commands available through stable user or system locations rather than tying them to an ephemeral language-runtime version.

Platform support is deliberate rather than approximate. Ubuntu/Debian uses its native packages plus architecture-appropriate upstream distributions where repository versions are insufficient. macOS uses Homebrew where it provides the intended distribution. Official Visual Studio Code Desktop belongs to the macOS environment, while code-server is an explicitly selected Ubuntu/Debian service. Unsupported platform selections fail with guidance instead of silently installing a substitute.

Updates preserve ownership boundaries. Python provides a native baseline interpreter and isolated environments but does not take ownership of project dependencies. Installing Beads does not initialize, synchronize, migrate, or delete a command repo. Those operations remain explicit. Generated credentials, editor service state, command-repo data, agent-local settings, and other mutable application data survive provisioning and remain outside repository ownership.

Failures are contained to the selected capability when recovery is possible. Downloads and temporary state are cleaned up, existing operational data is not treated as disposable install state, and warnings distinguish optional editor tooling from required runtime failures. The owner can rerun provisioning after correcting network, package, permission, architecture, or command-discovery problems.

## Why it exists

Before unified provisioning, reproducing this environment meant remembering which tools came from native packages, upstream binaries, language package managers, or direct installers. The correct choice varied by operating system and processor architecture. A machine could appear configured while using an obsolete binary, a shadowed command, or an installation lost during the next Node version switch.

The owner uses the same repository for fresh setup, upgrades, and repair. That requires one repeatable entry point that respects satisfactory existing tools, applies intentional updates, and reports unsupported conditions instead of improvising. Separating ordinary tool installation from stateful bootstrap and cleanup also prevents a routine install from mutating private execution data or deleting migration artifacts.

## Out of scope

- Supporting operating systems other than Ubuntu/Debian and macOS.
- Installing project-specific Python dependencies, environment managers, or global Python packages.
- Substituting unofficial editor distributions for the selected Visual Studio Code targets.
- Configuring firewalls or choosing an alternative port when a selected service cannot bind.
- Creating, synchronizing, migrating, or deleting a command repo during normal provisioning.
- Guaranteeing optional editor packages when their package manager is temporarily unavailable; the install reports a recovery path instead.

## FAQ

**Why are installation channels chosen per tool instead of requiring one package manager?**

Native package managers are used when they provide the intended distribution and update behavior. Official upstream installers or release binaries are used when native packages are unavailable, too old, or would create inconsistent update channels. Requiring one package manager was rejected because it would either omit required tools or install unsuitable versions.

**Revisit if:** Supported native package managers provide every required distribution at acceptable versions with equivalent update and verification behavior.

**Why are only Ubuntu/Debian and macOS supported?**

These are the owner’s actual host families and have explicit package, architecture, and recovery behavior. Best-effort support for other systems was rejected because silent approximations undermine reproducibility.

**Revisit if:** The owner adopts another host family and its complete package, architecture, service, and verification behavior is defined and exercised.

**Why are the editor targets asymmetric across platforms?**

Official Visual Studio Code Desktop is selected for macOS, while code-server is an explicit browser-based role for Ubuntu/Debian. Installing desktop alternatives on Linux or code-server on macOS was rejected because those are not part of the environment the repository intends to reproduce.

**Revisit if:** The owner adopts a supported desktop Linux editor workflow or requires a maintained macOS browser-editor role.

**Why is Python limited to a native baseline runtime?**

Provisioning supplies an interpreter and isolated-environment capability. Project dependencies, Python version managers, and global development packages remain project-owned. A comprehensive global Python environment was rejected because it couples unrelated projects and can interfere with system Python ownership.

**Revisit if:** A repository-wide Python tool becomes necessary across projects and cannot be supplied safely through isolated project or user tooling.

**Why do user-installed agent commands live independently of the active Node version?**

Agent commands must remain available when the owner changes Node versions. Installing them inside a runtime-version-managed global directory was rejected because switching runtimes can make the commands disappear.

**Revisit if:** The Node version manager provides a stable, shared global command location with equivalent isolation and upgrade behavior.

**Why is Pi installed once rather than once per profile?**

One Pi binary serves the environment; runtime configuration and wrapper commands provide behavioral variation. Multiple profile-specific binaries were rejected because they duplicate installation state without creating distinct tool capabilities.

**Revisit if:** Pi introduces incompatible runtime versions that must coexist for supported workflows.

**Why are Beads provisioning, command-repo bootstrap, and legacy cleanup separate operations?**

Normal provisioning installs and verifies the execution-coordination tool without touching operational data. Bootstrap requires an explicit private repository choice, and cleanup requires verified archival before deletion. Combining them with routine install was rejected because reruns could unexpectedly create, synchronize, migrate, or destroy state.

**Revisit if:** Beads provides a transactionally safe, non-destructive lifecycle operation whose authority and effects remain explicit during ordinary provisioning.

**Why does Beads use embedded storage rather than a separate Dolt service?**

The selected Beads distribution carries its storage engine in process and needs one verified executable. Provisioning a separate server, port, or process was rejected because it adds an unnecessary service and a second installation lifecycle.

**Revisit if:** Beads drops embedded storage support or the command repo requires concurrent access that cannot be served safely in process.

**Why are prerequisites resolved from the current environment?**

A selected module adds a prerequisite only when the required command is absent. A fixed installation chain was rejected because it performs redundant work and can replace usable owner-managed tools unnecessarily.

**Revisit if:** Command presence no longer provides enough evidence of compatibility and dependency verification requires a stronger uniform contract.

## Open questions

None
