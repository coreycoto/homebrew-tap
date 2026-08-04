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

`coreycoto/git-slop` publishes these immutable inputs before requesting a tap
update:

- `git-slop.rb`
- schema-3 `release-manifest.json`
- `SHA256SUMS`
- the canonical `git-slop-<version>.crate` URL and SHA-256 from crates.io
- the exact 40-character source revision embedded in the crate

The upstream release then dispatches `.github/workflows/update-git-slop.yml`
on this repository's `main` branch with these required inputs:

- `version`
- `revision`
- `formula_url` and `formula_sha256`
- `manifest_url` and `manifest_sha256`
- `crate_url` and `crate_sha256`

The receiver accepts only canonical `coreycoto/git-slop` GitHub Release URLs
and the canonical static.crates.io URL. Before writing a branch, it verifies:

- the dispatch ran from the exact current `main` commit
- strict version, revision, and digest formats
- the public tag's exact source revision
- unique matching formula and manifest entries in `SHA256SUMS`
- schema-3 manifest identity and `crate_source`
- the crate digest and clean `.cargo_vcs_info.json`
- byte-for-byte equality with the allowlisted native Rust formula template

A successful verification force-updates only the automation-owned
`automation/git-slop-v<version>` branch, commits the formula plus
`metadata/git-slop-release.json`, and creates or updates a pull request using
this repository's built-in `github.token`. It then explicitly dispatches
`tests.yml` against that branch because pushes and pull requests created with a
workflow token do not recursively start ordinary pull-request workflows.
An identical rerun reuses the existing exact automation-branch head and PR
instead of creating commit churn. It also reuses the newest exact-head test
dispatch while that run is queued or in progress, or after it succeeds while
both one-day bottle artifacts remain available. A missing, failed, cancelled,
or artifact-expired run is dispatched again. Receiver and publication jobs are
serialized, and the receiver refuses to rewrite a formula PR while its human
`pr-pull` gate is present.

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
its own PR and never adds the `pr-pull` label.

An upstream dispatch is equivalent to:

```bash
GH_TOKEN="$HOMEBREW_TAP_DISPATCH_TOKEN" gh workflow run update-git-slop.yml \
  --repo coreycoto/homebrew-tap \
  --ref main \
  -f version="$version" \
  -f revision="$revision" \
  -f formula_url="$formula_url" \
  -f formula_sha256="$formula_sha256" \
  -f manifest_url="$manifest_url" \
  -f manifest_sha256="$manifest_sha256" \
  -f crate_url="$crate_url" \
  -f crate_sha256="$crate_sha256"
```

## Formula And Bottle Tests

`tests.yml` continues to test ordinary pull requests and `main`, and also
accepts the receiver's explicit trusted head SHA and release inputs. For the
dispatched release head it:

- re-verifies the exact release assets, crate, manifest, formula, and changed
  file set
- runs Homebrew syntax/audit checks on macOS and Linux
- uses a digest-pinned official Homebrew Linux runner image
- builds the formula from source, produces bottles, installs and tests it
- checks `git-slop version` and `git-slop build-info --format json` against the
  exact version and clean source revision
- rejects installed Python or libyaml runtime dependencies
- exercises an in-place upgrade from the formula currently on `main` on a
  separate macOS runner

Bottle artifacts are retained for one day and remain associated with the exact
pull-request head tested by `brew pr-pull`. Failed jobs can still upload
diagnostic bottle artifacts because upload runs under `always()`, but those
artifacts are never publishable. Release-only `tests.yml` dispatches share the
receiver/publisher concurrency lock. This matters because Homebrew resolves the
newest workflow check suite again when `brew pr-pull` starts instead of
accepting a previously selected run ID: no later release test can finish and
supersede the successful artifact set during publication. Ordinary pull-request
and `main` tests retain per-ref concurrency.

## Human Publication Gate

Automation stops at a tested pull request. After every required exact-head test
is green, a human reviews the formula and provenance and applies the
`pr-pull` label. That label is the only normal bottle/merge gate.

`publish.yml` re-reads the current PR head, requires the `pr-pull` label, allows
only the formula and release-metadata files, and re-verifies every release
input. Immediately before `brew pr-pull`, it also requires the newest
`tests.yml` workflow-dispatch run for the exact trusted head to be completed
successfully with both expected, unexpired bottle artifacts. Artifacts uploaded
by a failed run are rejected. This binds the human authorization and bottle
inputs to the label event's exact commit before calling
`brew pr-pull --head-sha=<exact SHA>`. Homebrew then writes the bottle block,
pushes the resulting commit to `main`, and removes the automation branch only
when it still points to the published head. A failed job may be rerun as the
same trusted label event. If the formula head changes, a human must remove and
reapply `pr-pull`; there is no privileged manual-dispatch path.
