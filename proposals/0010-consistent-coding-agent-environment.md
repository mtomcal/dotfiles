# 0010 — Consistent coding-agent environment

**Status:** Superseded by [0014](0014-model-native-agent-environment.md)

**Created:** 2026-08-08

## What shipped

The dotfiles owner can move among Codex, Claude Code, Pi, and GitHub Copilot CLI while retaining one coherent, repository-managed coding-agent environment. Each agent keeps its native runtime and interaction model, while stable commands, agent definitions, model catalogs, extensions, wrappers, Herdr integrations, and shared workflow exposure remain reproducible across supported machines. Work can move to the provider whose subscription allowance, model capability, or availability best fits the moment without rebuilding the surrounding engineering workflow. Herdr operates the providers’ native interactive agents rather than pretending subscription access is a generic programmable model API.

Repository ownership stops where mutable runtime behavior begins. Credentials, authentication, sessions, history, generated settings, project-specific values, and machine-local state remain regular local data. Installer updates and migrations preserve that data instead of replacing it with repository links. Stable tracked resources update through the normal dotfiles deployment flow, making ownership visible and preventing upstream installers from becoming competing configuration authorities.

Every supported agent sees the canonical Skill Library. Claude, Codex, and Copilot expose it directly, while Pi uses a tracked visibility layer that can select shared skills without copying their definitions. Catalog exposure does not give agent configuration ownership of skill content, authoring rules, provenance, or semantic review.

Pi has one runtime configuration rather than profiles with separate binaries, settings, skills, or specialist roles. Its wrapper preserves access to the installed runtime while adding the repository’s launch behavior. Codex and Pi commands live independently of the active Node version so changing projects or runtimes does not make the agents disappear. Retired repository-managed profile and extension links are removed without treating unrelated local files as disposable.

Herdr lifecycle integrations are captured as repository-owned sources and deployed into each agent’s supported configuration surface. Copilot keeps catalog exposure distinct from its mutable runtime and hook state. Pi and Codex can also run in ephemeral Docker sandboxes: the current project and durable session needs receive deliberate writable access, stable agent configuration is mounted read-only, the container uses the host identity, and runtime credentials are forwarded without entering images or version control.

## Why it exists

AI providers offer different subscription allowances, rate limits, included models, and periods of excess capacity. A single-provider environment leaves paid access elsewhere unused and makes temporary limits or model availability operational blockers. The owner wants agentic arbitrage: route work among already-funded providers according to available allowance and task fit while keeping the same skills, coordination, review expectations, and repository context.

Those subscription benefits are generally delivered through providers’ first-party interactive coding agents, not as interchangeable programmatic model access. Noninteractive API use may be separately billed or unsupported by the subscription. Herdr therefore supplies a common way to launch, prompt, observe, and steer native interactive agents while preserving each provider’s supported behavior and access boundary.

That arbitrage is useful only if switching agents does not require maintaining divergent workflow catalogs and integration setups. A universal model wrapper was rejected because it would discard native capabilities and assume an automation entitlement the subscriptions may not provide. The owner instead needs shared intent with native runtimes. One canonical Skill Library prevents workflow drift, per-agent adapters preserve supported configuration shapes, and repository-owned Herdr hooks keep interactive switching practical.

## Out of scope

- Hiding differences between supported agents behind one universal command interface.
- Circumventing provider terms or treating interactive subscription access as an unsupported programmatic API entitlement.
- Tracking credentials, authentication, sessions, history, mutable settings, or project-specific runtime values.
- Giving agent configuration ownership of Skill Library authoring semantics.
- Restoring Pi profiles, profile-specific wrappers, profile-local skills, sub-agent roles, or the retired subagent extension.
- Making sandbox use mandatory for ordinary agent operation.
- Baking API credentials into sandbox images or granting every host directory writable access.
- Removing user-owned files merely because a repository-managed resource was retired.

## FAQ

**Why maintain a consistent environment across multiple AI providers?**

Provider subscriptions bundle different model access, usage allowances, and rate limits. Supporting several providers lets the owner use already-funded capacity and choose a suitable available model without paying the setup cost of changing workflows, skills, coordination, or review conventions. Standardizing on one provider was rejected because it strands other subscription value and turns one provider’s temporary limits or availability into a workflow constraint.

**Revisit if:** One provider consistently covers the required models and capacity at lower total cost than maintaining the other supported integrations, or subscription economics no longer reward switching.

**Why is Herdr necessary for subscription-based agentic arbitrage?**

Most provider subscriptions grant their economic benefit through a first-party interactive coding agent rather than unrestricted command-line piping or API automation. Herdr gives the owner one operational surface for launching, prompting, observing, and steering those native interactive agents while leaving authentication and provider-specific behavior intact. Replacing them with direct model calls or a noninteractive universal CLI was rejected because it may use separate billing, lose native agent capabilities, or fall outside the subscription’s supported access model.

**Revisit if:** The supported providers include equivalent programmatic agent access in their subscriptions, or their native agents adopt a common supported noninteractive orchestration interface.

**Why support four native agent runtimes instead of one universal wrapper?**

Each agent provides distinct models, interaction behavior, and supported configuration surfaces. A universal abstraction was rejected because it would either expose only the lowest common denominator or become a second runtime that continually chases upstream differences.

**Revisit if:** The owner standardizes on one agent or the supported tools adopt a stable common runtime and configuration contract.

**Why separate repository-owned resources from mutable runtime state?**

Commands, shared workflows, extensions, and integration sources are stable and reproducible. Credentials, sessions, history, generated settings, and project values change locally and may be sensitive. Tracking or symlinking both categories was rejected because application writes could leak private state or create cross-machine conflicts.

**Revisit if:** An agent exposes a documented immutable managed layer that cleanly separates every portable setting from local and secret state.

**Why preserve local Claude and Pi settings during installation and migration?**

Those agents and their installers legitimately update local settings. Replacing the files was rejected because it can erase user choices, authentication-adjacent state, or installer-generated values. Legacy repository links are converted without discarding their resolved content.

**Revisit if:** The agents provide lossless supported import and export for a strictly portable settings subset.

**Why is writable Codex configuration copied from a template?**

Codex stores machine- and project-specific values in its configuration. A repository symlink was rejected because local writes would flow back into version control. A template establishes defaults while allowing the resulting file to remain locally owned.

**Revisit if:** Codex separates immutable shared defaults from all writable local configuration through a supported interface.

**Why does every agent expose the same canonical Skill Library?**

Shared workflow behavior should not depend on which agent happens to execute it. Agent-specific copies were rejected because fixes, provenance, and semantics would drift. Agent configuration exposes the catalog but does not rewrite it.

**Revisit if:** An agent requires fundamentally incompatible skill semantics that cannot be handled through portable metadata or a bounded adapter.

**Why does Pi retain a visibility layer?**

Pi needs a tracked place to select which canonical shared skills it exposes while retaining room for Pi-specific composition. Linking it directly to the entire shared catalog was rejected because it removes that deliberate visibility boundary; copying skills was rejected because it creates another authority.

**Revisit if:** Pi supports equivalent catalog selection natively or no longer needs agent-specific composition.

**Why does Pi use one runtime configuration instead of profiles?**

One runtime, settings area, model catalog, and skill surface cover the owner’s Pi workflows. Profiles and specialist wrappers were rejected because they duplicated state, made migration harder, and obscured which configuration was active.

**Revisit if:** Pi introduces incompatible workflows that genuinely require simultaneously isolated runtime configurations and cannot be represented by models, skills, or launch options.

**Why do agent commands remain independent of the active Node version?**

Changing a project’s Node runtime should not remove or shadow the coding agents. Installing commands inside version-managed globals was rejected because agent availability would vary with the current project.

**Revisit if:** The Node version manager provides a stable shared global-command layer with equivalent update and isolation guarantees.

**Why are Herdr integrations repository-owned?**

The integrations are part of the reproducible agent environment and should update through the dotfiles flow. Allowing an upstream integration installer to mutate live configuration directly was rejected because it creates untracked state and a competing owner.

**Revisit if:** Herdr provides a declarative integration interface that is fully reproducible from repository-owned configuration.

**Why are Copilot catalog exposure and runtime state separate?**

Copilot discovers repository-managed commands, agents, and skills through one surface while storing current settings and hooks in another. Conflating them was rejected because deploying catalog content could overwrite or capture mutable runtime state.

**Revisit if:** Copilot adopts one documented directory with explicit immutable and mutable sub-boundaries that the deployment system can enforce safely.

**Why are agent sandboxes ephemeral with selective mounts?**

A sandbox should constrain side effects without preventing useful work or durable agent sessions. Mounting the entire host writable was rejected because it defeats isolation; making all configuration writable was rejected because sandboxed agents could mutate repository-managed runtime inputs.

**Revisit if:** The agents provide a stronger native sandbox with equivalent project access, host identity, credential forwarding, and persistent-session behavior.

**Why are runtime credentials forwarded rather than stored in sandbox images?**

Credentials are needed at execution time but must remain local and replaceable. Baking them into an image or tracked configuration was rejected because image layers and repositories can retain secrets beyond the session.

**Revisit if:** A supported short-lived secret broker supplies credentials directly to sandboxed processes without environment forwarding.

**Why are only stale repository-managed links pruned?**

The repository may remove a wrapper or extension it previously owned, but unrelated local state still belongs to the user. Broad cleanup was rejected because it can destroy files merely located near managed resources.

**Revisit if:** An agent provides an authoritative ownership manifest that can prove a broader resource set is repository-generated and safe to remove.

## Open questions

None
