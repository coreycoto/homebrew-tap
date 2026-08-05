#!/usr/bin/env bash

set -euo pipefail

curl_bin="${CURL_BIN:-curl}"
git_bin="${GIT_BIN:-git}"
ruby_bin_override="${RUBY_BIN:-}"

RELEASE_VERSION="${RELEASE_VERSION:-}"
RELEASE_REVISION="${RELEASE_REVISION:-}"
FORMULA_URL="${FORMULA_URL:-}"
FORMULA_SHA256="${FORMULA_SHA256:-}"
MANIFEST_URL="${MANIFEST_URL:-}"
MANIFEST_SHA256="${MANIFEST_SHA256:-}"
CRATE_URL="${CRATE_URL:-}"
CRATE_SHA256="${CRATE_SHA256:-}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

ruby_command=()
if [[ -n "${ruby_bin_override}" ]]
then
  ruby_command=("${ruby_bin_override}")
elif command -v ruby >/dev/null 2>&1
then
  ruby_command=(ruby)
elif command -v brew >/dev/null 2>&1
then
  ruby_command=(brew ruby --)
else
  die "Ruby or Homebrew's portable Ruby is required"
fi

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || die "${name} is required"
}

sha256_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1
  then
    sha256sum "${path}" | awk '{print $1}'
  else
    shasum -a 256 "${path}" | awk '{print $1}'
  fi
}

download() {
  local url="$1"
  local output="$2"
  "${curl_bin}" --fail --silent --show-error --location \
    --proto '=https' \
    --tlsv1.2 \
    "${url}" \
    --output "${output}"
}

verify_checksum_entry() {
  local checksums_path="$1"
  local expected_digest="$2"
  local expected_name="$3"
  local result
  result="$(
    awk -v digest="${expected_digest}" -v name="${expected_name}" '
      $2 == name {
        names += 1
        matches += ($1 == digest)
      }
      END { printf "%d:%d", names, matches }
    ' "${checksums_path}"
  )"
  [[ "${result}" == "1:1" ]] ||
    die "SHA256SUMS must contain one exact ${expected_name} entry with digest ${expected_digest}"
}

required_env_names=(
  RELEASE_VERSION
  RELEASE_REVISION
  FORMULA_URL
  FORMULA_SHA256
  MANIFEST_URL
  MANIFEST_SHA256
  CRATE_URL
  CRATE_SHA256
)
for name in "${required_env_names[@]}"
do
  require_env "${name}"
done

[[ $# -eq 1 ]] || die "usage: verify-git-slop-release.sh OUTPUT_DIRECTORY"
output_dir="$1"
mkdir -p "${output_dir}"

[[ "${RELEASE_VERSION}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] ||
  die "release version must be strict X.Y.Z semver"
[[ "${RELEASE_REVISION}" =~ ^[0-9a-f]{40}$ ]] ||
  die "release revision must be a lowercase 40-character commit SHA"

for digest_name in FORMULA_SHA256 MANIFEST_SHA256 CRATE_SHA256
do
  digest="${!digest_name}"
  [[ "${digest}" =~ ^[0-9a-f]{64}$ ]] ||
    die "${digest_name} must be a lowercase SHA-256 digest"
done

release_tag="v${RELEASE_VERSION}"
release_base="https://github.com/coreycoto/git-slop/releases/download/${release_tag}"
expected_formula_url="${release_base}/git-slop.rb"
expected_manifest_url="${release_base}/release-manifest.json"
expected_crate_url="https://static.crates.io/crates/git-slop/git-slop-${RELEASE_VERSION}.crate"
checksum_url="${release_base}/SHA256SUMS"

[[ "${FORMULA_URL}" == "${expected_formula_url}" ]] ||
  die "formula URL must be ${expected_formula_url}"
[[ "${MANIFEST_URL}" == "${expected_manifest_url}" ]] ||
  die "manifest URL must be ${expected_manifest_url}"
[[ "${CRATE_URL}" == "${expected_crate_url}" ]] ||
  die "crate URL must be ${expected_crate_url}"

formula_path="${output_dir}/git-slop.rb"
manifest_path="${output_dir}/release-manifest.json"
checksums_path="${output_dir}/SHA256SUMS"
crate_path="${output_dir}/git-slop-${RELEASE_VERSION}.crate"
expected_formula_path="${output_dir}/expected-git-slop.rb"

download "${FORMULA_URL}" "${formula_path}"
download "${MANIFEST_URL}" "${manifest_path}"
download "${checksum_url}" "${checksums_path}"
download "${CRATE_URL}" "${crate_path}"

downloaded_formula_sha256="$(sha256_file "${formula_path}")"
downloaded_manifest_sha256="$(sha256_file "${manifest_path}")"
downloaded_crate_sha256="$(sha256_file "${crate_path}")"

[[ "${downloaded_formula_sha256}" == "${FORMULA_SHA256}" ]] ||
  die "downloaded formula digest does not match FORMULA_SHA256"
[[ "${downloaded_manifest_sha256}" == "${MANIFEST_SHA256}" ]] ||
  die "downloaded manifest digest does not match MANIFEST_SHA256"
[[ "${downloaded_crate_sha256}" == "${CRATE_SHA256}" ]] ||
  die "downloaded crate digest does not match CRATE_SHA256"

verify_checksum_entry "${checksums_path}" "${FORMULA_SHA256}" git-slop.rb
verify_checksum_entry \
  "${checksums_path}" \
  "${MANIFEST_SHA256}" \
  release-manifest.json

jq -e \
  --arg version "${RELEASE_VERSION}" \
  --arg tag "${release_tag}" \
  --arg revision "${RELEASE_REVISION}" \
  --arg crate_url "${CRATE_URL}" \
  --arg crate_sha256 "${CRATE_SHA256}" '
    .schema_version == 3 and
    .project == "git-slop" and
    .repository == "coreycoto/git-slop" and
    .version == $version and
    .tag == $tag and
    .revision == $revision and
    .crate_source.registry == "crates.io" and
    .crate_source.package == "git-slop" and
    .crate_source.version == $version and
    .crate_source.url == $crate_url and
    .crate_source.sha256 == $crate_sha256 and
    .crate_source.revision == $revision and
    .crate_source.vcs_dirty == false
  ' "${manifest_path}" >/dev/null ||
  die "release manifest identity or crate_source does not match dispatch inputs"

tag_lines="$(
  "${git_bin}" ls-remote \
    https://github.com/coreycoto/git-slop.git \
    "refs/tags/${release_tag}" \
    "refs/tags/${release_tag}^{}"
)"
tag_revision="$(
  awk -v peeled="refs/tags/${release_tag}^{}" '$2 == peeled { print $1 }' <<<"${tag_lines}"
)"
if [[ -z "${tag_revision}" ]]
then
  tag_revision="$(
    awk -v direct="refs/tags/${release_tag}" '$2 == direct { print $1 }' <<<"${tag_lines}"
  )"
fi
[[ "${tag_revision}" == "${RELEASE_REVISION}" ]] ||
  die "public ${release_tag} resolves to ${tag_revision:-missing}, not ${RELEASE_REVISION}"

crate_root="git-slop-${RELEASE_VERSION}"
vcs_info_member="${crate_root}/.cargo_vcs_info.json"
tar -tzf "${crate_path}" | grep -Fx "${vcs_info_member}" >/dev/null ||
  die "crate is missing ${vcs_info_member}"
tar -xOzf "${crate_path}" "${vcs_info_member}" |
  jq -e --arg revision "${RELEASE_REVISION}" '
    .git.sha1 == $revision and
    ((.git | has("dirty") | not) or .git.dirty == false) and
    .path_in_vcs == ""
  ' >/dev/null ||
  die "crate VCS metadata does not match release revision"

cat >"${expected_formula_path}" <<EOF
class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "${CRATE_URL}"
  sha256 "${CRATE_SHA256}"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop ${RELEASE_VERSION}", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"${RELEASE_REVISION}\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
EOF

cmp "${expected_formula_path}" "${formula_path}" ||
  die "formula asset does not exactly match the trusted crates-first template"
"${ruby_command[@]}" -c "${formula_path}" >/dev/null ||
  die "formula asset is not valid Ruby syntax"

printf 'Verified git-slop %s at %s.\n' "${RELEASE_VERSION}" "${RELEASE_REVISION}"
