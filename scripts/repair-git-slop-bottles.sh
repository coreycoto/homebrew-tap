#!/usr/bin/env bash

# One-time migration of the already-tested, immutable 0.16.0 bottle bytes.
# Never rebuild, overwrite assets, or change an upstream release identity.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version=0.16.0
legacy_tag=git-slop-bottles-v2-0.16.0
release_tag=git-slop-v0.16.0
revision=09704a07a7c5213da61b8db2ed4fbf1fd63e066d
repository=coreycoto/homebrew-tap
legacy_root="https://github.com/${repository}/releases/download/${legacy_tag}"
release_root="https://github.com/${repository}/releases/download/${release_tag}"
formula="${repo_root}/Formula/git-slop.rb"

rewrite() {
  local candidate="$1"
  local output
  output="$(mktemp)"
  awk -v old="${legacy_root}" -v new="${release_root}" '
    $0 == "  url \"https://static.crates.io/crates/git-slop/git-slop-0.16.0.crate\"" { version++ }
    $0 == "    root_url \"" old "\"" { roots++; print "    root_url \"" new "\""; next }
    $0 == "    root_url \"" new "\"" { roots++ }
    { print }
    END { if (version != 1 || roots != 1) exit 1 }
  ' "${candidate}" >"${output}" || {
    rm -f "${output}"
    echo "Refusing to migrate a formula outside the exact 0.16.0 legacy/current root contract." >&2
    return 1
  }
  cat "${output}" >"${candidate}"
  rm -f "${output}"
}

verify_public() {
  local cache
  cache="$(mktemp -d)"
  (
    trap 'rm -rf -- "$cache"' EXIT
    unset GH_TOKEN GITHUB_TOKEN HOMEBREW_GITHUB_API_TOKEN
    unset HOMEBREW_BOTTLE_DOMAIN HOMEBREW_ARTIFACT_DOMAIN HOMEBREW_ARTIFACT_DOMAIN_NO_FALLBACK
    HOMEBREW_CACHE="${cache}" HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_FROM_API=1 \
      brew ruby -- "${repo_root}/scripts/bottle-consumers.rb" fetch \
      "${formula}" "${version}" "${release_root}"
  )
}

case "${1:-}" in
  rewrite)
    [[ $# == 2 ]]
    rewrite "$2"
    exit 0
    ;;
  verify)
    [[ $# == 1 ]]
    verify_public
    exit 0
    ;;
  publish)
    [[ $# == 1 ]]
    : "${GITHUB_REPOSITORY:?}" "${GITHUB_REF:?}" "${GITHUB_SHA:?}" "${GH_TOKEN:?}"
    test "${GITHUB_REPOSITORY}" = "${repository}"
    test "${GITHUB_REF}" = refs/heads/main
    head_sha="$(git rev-parse HEAD)"
    live_main="$(git ls-remote origin refs/heads/main)"
    live_main="${live_main%%$'\t'*}"
    test "${head_sha}" = "${GITHUB_SHA}"
    test "${live_main}" = "${GITHUB_SHA}"
    ;;
  *)
    echo "usage: repair-git-slop-bottles.sh rewrite FORMULA | publish | verify" >&2
    exit 1
    ;;
esac

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
# Bind the migration to the formula and metadata from the original successful
# release-test head, including the source revision asserted by brew test.
git show "${revision}:Formula/git-slop.rb" >"${work}/source.rb"
git show "${revision}:metadata/git-slop-release.json" >"${work}/metadata.json"
cmp "${work}/metadata.json" "${repo_root}/metadata/git-slop-release.json"
"${repo_root}/scripts/verify-git-slop-formula-state.sh" "${work}/source.rb" "${formula}"
rewrite "${formula}"
brew ruby -- "${repo_root}/scripts/bottle-consumers.rb" manifest \
  "${formula}" "${version}" "${release_root}" >"${work}/expected.json"

gh api "repos/${repository}/releases/tags/${legacy_tag}" >"${work}/legacy.json"
legacy_id="$(jq -er .id "${work}/legacy.json")"
jq --arg root "${legacy_root}" \
  'map(.name = .local_name | .url = ($root + "/" + .local_name))' \
  "${work}/expected.json" >"${work}/legacy-expected.json"
jq -e --slurpfile expected "${work}/legacy-expected.json" \
  --arg tag "${legacy_tag}" --arg revision "${revision}" \
  --argjson release_id "${legacy_id}" --argjson require_published true \
  -f "${repo_root}/scripts/verify-bottle-release.jq" "${work}/legacy.json" >/dev/null

# Download anonymously and verify the original bytes before creating a draft.
jq -c '.[]' "${work}/expected.json" >"${work}/records.jsonl"
while IFS= read -r record
do
  name="$(jq -er .local_name <<<"${record}")"
  sha256="$(jq -er .sha256 <<<"${record}")"
  curl --fail --location --silent --show-error --connect-timeout 15 --max-time 300 \
    "${legacy_root}/${name}" --output "${work}/${name}"
  printf '%s  %s\n' "${sha256}" "${work}/${name}" | sha256sum --check --status
  "${repo_root}/scripts/verify-bottle-archive.sh" "${work}/${name}" "${version}"
done <"${work}/records.jsonl"

gh api --paginate --slurp "repos/${repository}/releases?per_page=100" >"${work}/releases.json"
jq --arg tag "${release_tag}" '[.[][] | select(.tag_name == $tag)]' \
  "${work}/releases.json" >"${work}/matches.json"
jq -e 'length <= 1' "${work}/matches.json" >/dev/null
match_count="$(jq length "${work}/matches.json")"
if test "${match_count}" = 0
then
  gh api --method POST "repos/${repository}/releases" \
    -f tag_name="${release_tag}" -f target_commitish="${revision}" \
    -f name="git-slop ${version} bottles" \
    -f body="Verified byte-for-byte copies of the immutable ${legacy_tag} bottles, published under Homebrew consumer filenames." \
    -F draft=true -F prerelease=false >"${work}/release.json"
else
  jq '.[0]' "${work}/matches.json" >"${work}/release.json"
fi
release_id="$(jq -er .id "${work}/release.json")"
# A retry may only add missing assets to the exact draft. Published assets are
# immutable and must already be the complete expected set.
jq -e --arg tag "${release_tag}" --arg revision "${revision}" '
  .tag_name == $tag and .target_commitish == $revision and .prerelease == false and
  ((.draft == true and .immutable == false) or (.draft == false and .immutable == true))
' "${work}/release.json" >/dev/null
draft="$(jq -r .draft "${work}/release.json")"
if test "${draft}" = true
then
  jq -e --slurpfile expected "${work}/expected.json" '
    all(.assets[]; . as $asset |
      [$expected[0][] | select(.name == $asset.name and .url == $asset.browser_download_url and
        ("sha256:" + .sha256) == $asset.digest and $asset.state == "uploaded" and $asset.size > 0)] | length == 1)
  ' "${work}/release.json" >/dev/null
  while IFS= read -r record
  do
    name="$(jq -er .name <<<"${record}")"
    local_name="$(jq -er .local_name <<<"${record}")"
    if jq -e --arg name "${name}" 'any(.assets[]; .name == $name)' "${work}/release.json" >/dev/null
    then
      continue
    fi
    curl --fail-with-body --silent --show-error --connect-timeout 15 --max-time 300 \
      --request POST -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GH_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Content-Type: application/octet-stream" --data-binary "@${work}/${local_name}" \
      "https://uploads.github.com/repos/${repository}/releases/${release_id}/assets?name=${name}" >/dev/null
  done <"${work}/records.jsonl"
fi
gh api "repos/${repository}/releases/${release_id}" >"${work}/release.json"
jq -e --slurpfile expected "${work}/expected.json" \
  --arg tag "${release_tag}" --arg revision "${revision}" \
  --argjson release_id "${release_id}" --argjson require_published false \
  -f "${repo_root}/scripts/verify-bottle-release.jq" "${work}/release.json" >/dev/null
draft="$(jq -r .draft "${work}/release.json")"
if test "${draft}" = true
then
  gh api --method PATCH "repos/${repository}/releases/${release_id}" -F draft=false >/dev/null
fi
for attempt in $(seq 1 30)
do
  gh api "repos/${repository}/releases/${release_id}" >"${work}/release.json"
  if jq -e --slurpfile expected "${work}/expected.json" \
     --arg tag "${release_tag}" --arg revision "${revision}" \
     --argjson release_id "${release_id}" --argjson require_published true \
        -f "${repo_root}/scripts/verify-bottle-release.jq" "${work}/release.json" >/dev/null
  then
    verify_public
    exit 0
  fi
  if [[ "${attempt}" -lt 30 ]]
  then
    sleep 2
  fi
done
echo "The repaired release did not become immutable." >&2
exit 1
