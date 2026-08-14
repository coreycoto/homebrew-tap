# 🏡🍻 Homebrew Tap

Homebrew tap for tools developed by [Corey Coto](https://github.com/coreycoto)
and [Codex](https://openai.com/codex/).

## git-slop

Supported platforms are Apple Silicon macOS and Linux.

```bash
brew tap coreycoto/tap
brew install coreycoto/tap/git-slop
git-slop version
git slop version
```

The public formula name remains `coreycoto/tap/git-slop`. Releases from 0.9.0
onward install the published crates.io source package and compile the native
Rust executable. The formula does not retain the pre-0.9 Python runtime or
package resources.

## Release Handoff

After crates.io publication, `coreycoto/git-slop` requests a tap update with
the four immutable facts available at that protected release boundary:

- the strict release version
- the exact 40-character source revision embedded in the crate
- the canonical `git-slop-<version>.crate` URL
- the crates.io package SHA-256

The upstream release then dispatches `.github/workflows/update-git-slop.yml`
on this repository's `main` branch with these required inputs:

- `version`
- `revision`
- `crate_url` and `crate_sha256`

The receiver waits up to approximately two hours for the exact public GitHub
Release. After publication it requires one canonical `git-slop.rb`,
`release-manifest.json`, and `SHA256SUMS` asset with GitHub-provided SHA-256
digests, derives their canonical URLs and digests, and then verifies:

- the dispatch ran from the exact current `main` commit
- strict version, revision, and digest formats
- the public tag's exact source revision
- unique matching formula and manifest entries in `SHA256SUMS`
- schema-3 manifest identity and `crate_source`
- the crate digest and clean `.cargo_vcs_info.json`
- valid Ruby syntax and the formula's identity-critical source, dependency,
  install, and provenance-test semantics

The signed release asset and its checksums remain authoritative for additive
formula behavior such as completion generation, so the tap does not duplicate
the entire upstream formula template.

A successful verification force-updates only the automation-owned
`automation/git-slop-v<version>` branch, commits the formula plus
`metadata/git-slop-release.json`, and creates or updates a pull request using
this repository's built-in `github.token`. It then explicitly dispatches
`release-tests.yml` against that branch because pushes and pull requests
created with a workflow token do not recursively start ordinary pull-request
workflows. The final successful release-test job explicitly sends a
`repository_dispatch` containing only its exact run ID because a
`workflow_run` chained from that workflow-token dispatch is suppressed by the
same recursion guard.
An identical rerun reuses the existing exact automation-branch head and PR
instead of creating commit churn. It also reuses the newest exact-head test
dispatch while that run is queued or in progress, or after it succeeds while
both one-day bottle artifacts remain available. A missing, failed, cancelled,
or artifact-expired run is dispatched again. Receiver, release-test, and
publication jobs share one concurrency lock.

If the public release is still unavailable after the bounded wait, publish the
exact GitHub Release and redispatch the same four immutable inputs. The
receiver is idempotent and reuses a matching branch, PR, and successful
unexpired artifacts rather than creating commit churn.

After `brew pr-pull` has merged the formula and bottle block, redispatching the
same release is a no-op when the immutable metadata on `main` matches exactly.
The receiver only reports that release as published after validating exactly
one canonical bottle block with both `arm64_tahoe` and `x86_64_linux`
checksums. It preserves that block rather than replacing it with the
bottle-free release asset. Matching metadata beside a source-only or malformed
formula fails closed instead of skipping the bottle publication gate. The
receiver also rejects different metadata for an already-published version and
rejects release downgrades.

### Dispatch credential

Use a separate fine-grained token scoped only to `coreycoto/homebrew-tap` with
**Actions: read and write** permission to invoke the receiver from
`coreycoto/git-slop`. Store it only in the upstream repository, for example as
`HOMEBREW_TAP_DISPATCH_TOKEN`, and pass it only to the workflow-dispatch step.

This dispatch token is not a bottle-upload credential. Do not rotate, replace,
or expose an existing Homebrew PAT when adding it. The tap receiver, tests, and
bottle publication use only their step-scoped built-in `github.token`.

One one-time tap setting is required under **Settings → Actions → General**:
enable **Allow GitHub Actions to create and approve pull requests**. The
receiver requests only its explicit job-level write permissions; the
repository-wide default can remain read-only. The workflow does not approve
its own PR or add a publication label.

An upstream dispatch is equivalent to:

```bash
GH_TOKEN="$HOMEBREW_TAP_DISPATCH_TOKEN" gh workflow run update-git-slop.yml \
  --repo coreycoto/homebrew-tap \
  --ref main \
  -f version="$version" \
  -f revision="$revision" \
  -f crate_url="$crate_url" \
  -f crate_sha256="$crate_sha256"
```

## Formula And Bottle Tests

`tests.yml` continues to test ordinary pull requests and `main` with read-only
permissions. Release publication does not consume its artifacts.

The dispatch-only `release-tests.yml` accepts the receiver's exact pull
request, trusted head SHA, and derived immutable release inputs. For that
release head it:

- re-verifies the exact release assets, crate, manifest, formula, and changed
  file set
- runs Homebrew syntax/audit checks on macOS and Linux
- uses a digest-pinned official Homebrew Linux runner image
- builds the formula from source, produces bottles, installs and tests it
- checks `git-slop version` and `git-slop build-info --format json` against the
  exact version and clean source revision
- rejects installed Python or libyaml runtime dependencies
- installs the formula currently on `main` from source, then exercises an
  in-place source upgrade on a separate macOS runner so historic bottle URL
  naming changes cannot block release qualification
- sends the exact successful run ID to the trusted-main publisher only after
  every required validation, bottle, and upgrade job succeeds

Bottle artifacts are retained for one day and remain associated with the exact
`release-tests.yml` run and pull-request head tested by `brew pr-pull`. Failed
jobs can still upload diagnostic bottle artifacts because upload runs under
`always()`, but those artifacts are never publishable. Release tests share the
receiver/publisher concurrency lock. This matters because Homebrew resolves the
newest workflow check suite again when `brew pr-pull` starts instead of
accepting a previously selected run ID: no later release test can finish and
supersede the successful artifact set during publication. Ordinary pull-request
and `main` tests retain per-ref concurrency.

## Trusted-main Publication Gate

The final successful job in `Release git-slop bottles` sends a
`repository_dispatch` with its exact run ID, which starts `publish.yml` from
the trusted default branch. There is no label or manual tap-side publication
action in the normal release path. The protected upstream release environment
remains the sole Actions approval. All three workflows share the publication
lock, so the publisher cannot start until the release-test run has released
that lock and reached a terminal state.

The publisher runs only from trusted `main`. It accepts a dispatch from either
`github-actions[bot]` in the normal path or the repository owner for bounded
recovery, but treats the payload only as an exact run-ID pointer. It loads the
canonical `.github/workflows/release-tests.yml` execution from the Actions API,
waits briefly if necessary, and requires a completed, successful
`workflow_dispatch` run created and triggered by `github-actions[bot]` on an
`automation/git-slop-v<version>` branch. It derives and binds the run attempt,
head SHA, branch, and URL from that API record and then:

- resolves exactly one open same-repository pull request created by
  `github-actions[bot]` against `main`
- requires the event head to have the exact current `main` commit as its sole
  parent
- allows exactly `Formula/git-slop.rb` and
  `metadata/git-slop-release.json`, with no rename
- re-verifies the immutable public release, crate provenance, metadata, and
  byte-exact source formula without checking out or executing pull-request code
- requires the triggering run to remain the newest dispatch for the exact head
  and to own exactly two unexpired, SHA-256-digested bottle artifacts with
  matching repository, branch, and head provenance

All handoff workflows share the publication concurrency lock. Homebrew's
`brew pr-pull` does not accept a run ID and resolves the newest matching check
suite itself; the exact-head newest-run check plus that shared lock prevents a
later completed run from superseding the event-bound artifacts during
publication. Homebrew writes the bottle block, pushes the result to `main`, and
the workflow deletes the automation branch only when it still points to the
published head.

The publisher is idempotent. If exact metadata and the canonical two-platform
bottle formula are already on `main`, a repeated successful event verifies that
terminal state and exits without changing the repository. Failed publisher
runs may be recovered by resending `git-slop-bottles-ready` with the same exact
successful run ID; the publisher revalidates the run and all current state
instead of trusting the sender's payload. A changed formula head requires a new
exact-head release-test completion.

### Bottle release immutability

Repository release immutability must remain enabled before dispatching a new
git-slop bottle release. An administrator can run this fail-closed preflight:

```bash
gh api -H 'X-GitHub-Api-Version: 2026-03-10' \
  repos/coreycoto/homebrew-tap/immutable-releases \
  --jq 'select(.enabled == true)'
```

The publisher creates `git-slop-bottles-v2-<version>` as an exact-revision
draft and keeps Homebrew's `pr-pull` upload disabled. Because `brew bottle
--merge` reads the root URL from each bottle JSON file, the workflow validates
the exact qualified tap, formula path, and tested revision in each metadata
file, then rewrites only the root URL to the precreated draft's URL before
merging the bottle block. It then uploads both
exact artifacts to the existing draft, verifies their GitHub digests, publishes
the release, and polls until its API record reports `immutable: true`. A
partial run remains a mutable draft that the same exact trusted handoff can
refresh safely.
`git-slop-0.11.8` predates enablement and remains the only documented
`immutable: false` exception; its assets must not be replaced.
