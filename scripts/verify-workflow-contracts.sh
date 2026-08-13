#!/usr/bin/env bash
# shellcheck disable=SC2016 # Contract literals must not expand in this process.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
publisher="${repo_root}/.github/workflows/publish.yml"
receiver="${repo_root}/.github/workflows/update-git-slop.yml"
release_tests="${repo_root}/.github/workflows/release-tests.yml"
readme="${repo_root}/README.md"

die() {
  printf 'error: %s\n' "${*}" >&2
  exit 1
}

require_text() {
  local path="${1}"
  local expected="${2}"
  grep -F -- "${expected}" "${path}" >/dev/null ||
    die "${path#"${repo_root}/"} is missing required contract text: ${expected}"
}

reject_text() {
  local path="${1}"
  local rejected="${2}"
  if grep -F -- "${rejected}" "${path}" >/dev/null
  then
    die "${path#"${repo_root}/"} retains forbidden legacy contract text: ${rejected}"
  fi
}

require_text "${release_tests}" "Dispatch trusted-main publication"
require_text "${release_tests}" "repos/\${GITHUB_REPOSITORY}/dispatches"
require_text "${release_tests}" 'event_type: "git-slop-bottles-ready"'
require_text "${release_tests}" 'client_payload: {run_id: $run_id}'
require_text "${release_tests}" '.status == "in_progress"'
require_text "${release_tests}" '.actor.login == "github-actions[bot]"'
require_text "${release_tests}" '.triggering_actor.login == "github-actions[bot]"'
require_text "${publisher}" "repository_dispatch:"
require_text "${publisher}" "- git-slop-bottles-ready"
require_text "${publisher}" "EVENT_RUN_ID: \${{ github.event.client_payload.run_id }}"
require_text "${publisher}" '.action == "git-slop-bottles-ready"'
require_text "${publisher}" '(.client_payload | keys) == ["run_id"]'
require_text "${publisher}" '.client_payload.run_id == $run_id'
require_text "${publisher}" '.sender.login == "github-actions[bot]"'
require_text "${publisher}" '.sender.login == $owner'
require_text "${publisher}" ".github/workflows/publish.yml@refs/heads/main"
require_text "${publisher}" "actions/workflows/release-tests.yml"
require_text "${publisher}" 'test "$(jq -r .state "$workflow_json")" = "active"'
require_text "${publisher}" '.workflow_id == $workflow_id'
require_text "${publisher}" '.path == ".github/workflows/release-tests.yml"'
require_text "${publisher}" 'repos/${GITHUB_REPOSITORY}/releases?per_page=100'
require_text "${publisher}" '[.[][] | select(.tag_name == $tag)]'
require_text "${publisher}" 'release_tag="git-slop-bottles-${RELEASE_VERSION}"'
require_text "${publisher}" "Prepare exact draft bottle release"
require_text "${publisher}" 'target_commitish: $revision'
require_text "${publisher}" 'draft: true'
require_text "${publisher}" '(.assets | length) == 0'
require_text "${publisher}" '--root-url="$BOTTLE_ROOT_URL"'
require_text "${publisher}" "Publish the complete draft and verify immutability"
require_text "${publisher}" '(.assets | length) == 2'
require_text "${publisher}" '-F draft=false'
require_text "${publisher}" '.immutable == true'
require_text "${publisher}" 'Bottle release ${BOTTLE_RELEASE_TAG} did not become immutable after publication.'
require_text "${publisher}" '.status == "completed"'
require_text "${publisher}" '.conclusion == "success"'
require_text "${publisher}" '.actor.login == "github-actions[bot]"'
require_text "${publisher}" '.triggering_actor.login == "github-actions[bot]"'
require_text "${publisher}" '.parents[0].sha == $base_sha'
require_text "${publisher}" 'length == 1 and'
require_text "${publisher}" '.[0].user.login == "github-actions[bot]"'
require_text "${publisher}" "length == 2 and"
require_text "${publisher}" "expected_files=\$'Formula/git-slop.rb\\nmetadata/git-slop-release.json'"
require_text "${publisher}" '.id == $event_run_id'
require_text "${publisher}" '.total_count == 2 and'
require_text "${publisher}" '.digest | test("^sha256:[0-9a-f]{64}$")'
require_text "${publisher}" '.workflow_run.id == $run_id'
require_text "${publisher}" '.workflow_run.repository_id | tostring'
require_text "${publisher}" '.workflow_run.head_repository_id | tostring'
require_text "${publisher}" '.workflow_run.head_sha == $head_sha'
require_text "${publisher}" '.workflow_run.head_branch == $branch'
require_text "${publisher}" "Recheck current parent, exact head, pull request, and allowlist"
require_text "${publisher}" "brew pr-pull"
require_text "${publisher}" '--head-sha="$EVENT_HEAD_SHA"'
require_text "${publisher}" "steps.publication.outputs.published != 'true'"

recheck_line="$(
  grep -nF "Recheck current parent, exact head, pull request, and allowlist" \
    "${publisher}" |
    cut -d: -f1
)"
publish_line="$(
  grep -nF "Pull the event-bound exact-head bottles" "${publisher}" |
    cut -d: -f1
)"
[[ -n "${recheck_line}" && -n "${publish_line}" && "${recheck_line}" -lt "${publish_line}" ]] ||
  die "the final current-parent and allowlist recheck must run immediately before bottle publication"

reject_text "${publisher}" "pull_request_target:"
reject_text "${publisher}" "github.event.workflow_run"
reject_text "${publisher}" "github.event.label"
reject_text "${publisher}" "pr-pull'"
reject_text "${receiver}" "human pr-pull gate"
reject_text "${receiver}" 'any(.labels'
reject_text "${receiver}" 'apply the `pr-pull` label'
reject_text "${receiver}" "have a human apply"
reject_text "${readme}" "## Human Publication Gate"
reject_text "${readme}" 'human `pr-pull` gate'
reject_text "${readme}" 'applies the `pr-pull` label'

for workflow in "${publisher}" "${receiver}" "${release_tests}"
do
  require_text "${workflow}" "group: git-slop-formula-publication"
  require_text "${workflow}" "cancel-in-progress: false"
done

require_text "${readme}" "## Trusted-main Publication Gate"
require_text "${readme}" "There is no label or"
require_text "${readme}" "sole Actions approval"
require_text "${readme}" "does not accept a run ID"
require_text "${readme}" "repository_dispatch"
require_text "${readme}" "exact successful run ID"

echo "trusted git-slop publication workflow contracts passed"
