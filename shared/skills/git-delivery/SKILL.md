---
name: git-delivery
description: Deliver Git changes through pull requests, CI, and stale-branch refresh with remote-head verification. Use when opening or updating a pull request, following checks to green, refreshing a stale branch, or verifying a pushed PR head.
metadata:
  short-description: Deliver pull requests through green CI
allowed-tools: read,write,edit,bash
---

# Git Delivery

## Language Definitions

- **Delivery scope** — caller-authorized goal, commits and files, base and head, permitted state changes, and acceptance checks for one delivery.
- **Pushed head** — commit OID confirmed to be the local `HEAD`, the selected remote branch head, and the pull request's `headRefOid`.
- **Check requirements** — local and hosted checks required by repository instructions, the caller, classic branch protection, or active branch rules.
- **Stale head** — pull-request head that does not contain the latest fetched base when repository policy or the caller requires freshness.

## Workflow

### 1. Fix the delivery scope and route the mode

Determine whether the caller wants a new pull request, an existing pull request updated, CI followed to green, a stale head refreshed, or a combination. Record the goal, intended commits/files, explicit or repository-selected base, head, permitted push and PR metadata changes, permission to make and commit delivery fixes, history-rewrite policy, required checks, and polling/deadline bound. A request to deliver authorizes only the state changes it states or necessarily identifies; it never authorizes merging, auto-merge, protection bypass, unrelated cleanup, or final human acceptance.

Inspect the current branch, `HEAD`, status, staged and unstaged changes, upstream, and any merge, rebase, cherry-pick, or revert in progress. Require a named branch, committed intended changes, a clean index/worktree, and an accounted-for commit range before remote mutation. Do not stash, reset, clean, switch away from unrelated changes, or absorb them. If an operation has conflicts, invoke `resolving-merge-conflicts`; that skill retains intent decisions, selective staging, and authorization for the exact continuation or abort. If consequential authorization or the intended scope is ambiguous, stop and ask before changing local or remote state.

Completion criterion: the delivery mode and scope are recorded, every local change and active operation is accounted for, the branch is clean, and every planned state change is authorized.

### 2. Discover the repository, topology, and requirements

Do not assume GitHub, `origin`, `main`, the current branch, or one repository for both PR sides. Inspect all fetch/push URLs and branch configuration. Require `git`, `gh`, a GitHub or GitHub Enterprise remote that maps unambiguously to the delivery, and successful `gh auth status --hostname <host>`. Use `gh repo view --json nameWithOwner,defaultBranchRef,url,isFork,parent` and, for an existing PR, `gh pr view <pr> --repo <base-repository> --json number,url,state,isDraft,baseRefName,headRefName,headRefOid,headRepository,headRepositoryOwner,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup`.

For a new PR, use the caller's base or the host-reported default branch and record that choice. Discover the head from the authorized named branch. Select separately:

- the base repository and a remote or URL from which its base can be fetched;
- the head repository and existing remote authorized for pushing the head; and
- the PR repository passed explicitly to `gh --repo`.

The push remote must map to the intended head repository. Do not silently add, delete, or repoint remotes. For an existing PR, its base/head repositories and branch names are authoritative unless the caller explicitly changes PR metadata. If topology is ambiguous, stop with the candidate remotes and missing decision.

Read repository instructions, contribution guidance, PR templates, and test/CI configuration relevant to the changed files. Query both classic protection and active rules for the percent-encoded base branch:

```text
gh api repos/<owner>/<repo>/branches/<base>/protection
gh api repos/<owner>/<repo>/rules/branches/<base>
```

Record required status checks and workflows, strict latest-base policy, reviews, conversation resolution, deployments, signatures, merge queue, and other applicable gates. A 404 from the classic protection endpoint means only that classic protection was not returned; still inspect active branch rules. Authentication, permission, network, parsing, or branch-rules failures mean requirements are unknown and block remote mutation.

If `gh` is missing or unusable, authentication fails, the remotes are non-GitHub, or repository/protection/check discovery cannot complete, stop before pushing. Report the local branch/OID/status, discovered remotes and host, commands attempted, exact missing capability, and the safe next action. Do not substitute a partial Git push for PR/CI delivery.

Completion criterion: base/head repositories, branches, fetch and push targets, PR identity or confirmed new-PR mode, authentication, protection/rules, local checks, hosted checks, freshness policy, and external gates are recorded without a hard-coded topology.

### 3. Pin and review a clean change

Fetch the selected base explicitly and immediately resolve the fetched commit to an immutable base OID. Fetch or inspect the current remote head when it exists and record its OID. Then inspect the exact delivery range with commands equivalent to:

```bash
git log --oneline --decorate <base-oid>..HEAD
git diff --stat <base-oid>...HEAD
git diff <base-oid>...HEAD
```

Reject an empty range, unrelated commits/files, unexpected generated artifacts, or history that cannot be explained by the Delivery scope. For a new PR whose branch contains unrelated ancestry, rebuild from the fetched base and cherry-pick only intended commits only when the caller authorized that local branch change; otherwise stop with the contamination evidence. Never rewrite an existing published head merely to make it look clean without explicit rewrite authorization.

Run the repository-required local checks. Invoke `code-review` with the immutable fetched base OID as its fixed point and the caller's originating requirement as the Spec source. Preserve its separate Standards and Spec results. Fix findings only when the Delivery scope authorizes edits and commits; otherwise return them to the caller. After a fix, require a clean tree, rerun affected local checks, and repeat the fixed-point review before publication.

Completion criterion: the immutable base, intended non-empty commit/diff scope, local check results, and separate Standards/Spec outcomes are recorded, with no unexplained change or unresolved in-scope finding.

### 4. Publish or update the pull request

Before creating a PR, successfully search the base repository for an open PR from the exact head owner/branch. Treat an empty successful search as “no PR”; do not treat command, auth, or network failure that way. If a matching PR exists, update it rather than creating a duplicate.

Capture the remote head OID immediately before push. Push the exact ref to the selected head remote:

```bash
git push <push-remote> HEAD:refs/heads/<head-branch>
```

Set upstream only when a new branch needs it and the selected remote/branch are authorized. If a normal update is rejected because the remote advanced, stop, refetch, and reconcile ownership; never escalate to force.

For a new PR, use explicit inputs rather than interactive inference:

```bash
gh pr create --repo <base-repository> --base <base-branch> --head <head-owner>:<head-branch> --title <title> --body-file <file>
```

Capture the resulting number and URL. For an existing PR, push to its exact head and use `gh pr edit` only for caller-requested title, body, base, reviewer, label, or other metadata changes. Do not convert draft state, alter maintainer access, or change the base incidentally.

Completion criterion: exactly one open PR represents the intended base/head, its URL and number are recorded, and every pushed commit and metadata change is within the Delivery scope.

### 5. Prove the pushed head and inspect mergeability

After every push, resolve all three OIDs:

```bash
git rev-parse 'HEAD^{commit}'
git ls-remote --exit-code --heads <push-remote> refs/heads/<head-branch>
gh pr view <pr> --repo <base-repository> --json state,baseRefName,headRefName,headRefOid,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,url
```

Require exactly one remote-head result and equality among local `HEAD`, the remote OID, and `headRefOid`. Poll only within the recorded bound for GitHub propagation. A missing ref, changed remote OID, closed PR, mismatched branch, or failure to converge returns to topology/scope discovery; it is not a successful push.

Only after OID convergence, record `mergeable`, `mergeStateStatus`, review state, and hosted check rollup. Retry a temporarily unknown host result within the same bound. Treat a conflicting result as requiring stale/conflict handling; report review, conversation, deployment, queue, or permission blockers without bypassing them.

Completion criterion: one Pushed head is proven and current mergeability plus external blockers are recorded for that exact OID.

### 6. Follow CI to green

Use `gh pr checks <pr> --repo <base-repository> --watch --fail-fast` to watch reported checks. When required-check filtering is supported and requirements were discovered, also inspect `gh pr checks <pr> --repo <base-repository> --required`. This installed command does not provide portable JSON output; use `gh pr view --json statusCheckRollup` for structured final evidence.

Do not stop at “PR created” or “fix pushed.” For a failing check, identify its run or details URL, inspect failed output (using `gh run view <run-id> --repo <base-repository> --log-failed` when it is a GitHub Actions run), reproduce locally when possible, and distinguish a change-induced failure from flaky infrastructure, missing secrets/permissions, or an external service. Make and commit only authorized Delivery-scope fixes. Then require a clean tree, rerun focused and repository-required local checks, repeat `code-review` against the current fixed base, push, prove the new head, and watch checks again.

“No checks reported” is successful only when repository guidance, caller requirements, classic protection, active rules, and PR rollup were all discovered successfully and establish that no hosted check is expected. Otherwise it is an unmet or unknown requirement. A skipped or neutral check is acceptable only when GitHub and the discovered policy classify it as satisfying the requirement; do not relabel red, cancelled, or missing checks as green.

Continue until all Check requirements for the proven head are passing, or until the caller's bound or an external blocker is reached. On a blocker, preserve the branch/PR state and report the failing check, URL/log evidence, local reproduction, attempts, required external action, and last proven head.

Completion criterion: all discovered check requirements are green for the proven PR head, or an evidenced external/bounded failure is reported without a false completion claim.

### 7. Refresh a stale head safely

Fetch the base again and record its new OID. Use `git merge-base --is-ancestor <latest-base-oid> HEAD` to test whether the head contains it. Refresh when strict protection/rules, repository policy, host conflict state, or the caller requires freshness. Do not refresh solely because an assumed `main` moved.

Choose merge or rebase from repository history policy and the caller's rewrite authorization. Before changing history, record the current remote head OID. If Git reports conflicts, invoke `resolving-merge-conflicts`; do not choose `ours`/`theirs`, continue, skip, commit, or abort outside that skill's intent and exact-action authorization. Even when Git integrates without markers, inspect the complete resulting diff and semantic neighbors for silent drift, especially shared adapters, publication/transport, and event-routing behavior.

Rerun local checks and `code-review` against the latest base OID. Push a merge normally. For an authorized rebase of a published branch, never use raw `--force`; use the exact observed lease:

```bash
git push --force-with-lease=refs/heads/<head-branch>:<observed-remote-oid> <push-remote> HEAD:refs/heads/<head-branch>
```

A lease failure means someone else changed the remote: stop and rediscover rather than overwriting it. After a successful push, repeat Pushed head proof, mergeability inspection, and CI follow-through. If strict freshness applies, fetch the base once more before completion; repeat within the caller's bound if it moved again.

Completion criterion: the latest required base is contained in the proven head, semantic drift and conflicts were reviewed through their owners, the remote was updated without overwriting concurrent work, and mergeability/check evidence belongs to the refreshed OID.

### 8. Report delivery without merging

Report:

- base and head repositories/branches plus selected fetch and push remotes;
- PR number/URL/state and whether it was created or updated;
- fixed base OID and final local, remote, and PR head OIDs;
- delivered commits/files and any CI or refresh fixes;
- separate Standards and Spec outcomes;
- local checks, hosted checks, protection/rules, and freshness evidence;
- mergeability, review decision, and every remaining external gate;
- failed attempts, limitations, residual risks, and exact next owner/action.

Confirm the final worktree/index are clean and no Git operation remains unintentionally active. Never run `gh pr merge`, enable auto-merge, delete the branch, claim human acceptance, or report “ready” when head OIDs diverge, required checks are not green, freshness policy is unmet, or conflicts remain. Delivery ends at a verified open PR or an evidenced blocker; merge authorization belongs to the caller and is outside this skill.

Completion criterion: every report field is present, claims match the final proven OIDs and check state, and the PR remains unmerged unless it had already been merged before invocation and the caller requested verification only.
