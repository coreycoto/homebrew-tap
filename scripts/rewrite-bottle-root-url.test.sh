#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rewriter="${repo_root}/scripts/rewrite-bottle-root-url.sh"
fixture_dir="$(mktemp -d)"
trap 'rm -rf -- "$fixture_dir"' EXIT

version="0.12.1"
root_url="https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-bottles-v2-${version}"
metadata="${fixture_dir}/git-slop.bottle.json"
revision="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

write_valid_fixture() {
  cat >"${metadata}" <<'JSON'
{
  "coreycoto/tap/git-slop": {
    "formula": {
      "name": "git-slop",
      "pkg_version": "0.12.1",
      "path": "Library/Taps/coreycoto/homebrew-tap/Formula/git-slop.rb",
      "tap_git_path": "Formula/git-slop.rb",
      "tap_git_revision": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "tap_git_remote": "https://github.com/coreycoto/homebrew-tap"
    },
    "bottle": {
      "root_url": "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.12.1",
      "tags": {
        "arm64_tahoe": {
          "sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        }
      }
    }
  }
}
JSON
}

write_valid_fixture
"${rewriter}" "${metadata}" "${root_url}" "${version}" "${revision}"
jq -e \
  --arg root_url "${root_url}" '
    .["coreycoto/tap/git-slop"].bottle.root_url == $root_url and
    .["coreycoto/tap/git-slop"].bottle.tags.arm64_tahoe.sha256 ==
      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  ' "${metadata}" >/dev/null

write_valid_fixture
jq '.unexpected = true' "${metadata}" >"${metadata}.invalid"
mv "${metadata}.invalid" "${metadata}"
cp "${metadata}" "${metadata}.before"
if "${rewriter}" "${metadata}" "${root_url}" "${version}" "${revision}" 2>/dev/null
then
  echo "rewriter accepted bottle metadata with an unexpected top-level key" >&2
  exit 1
fi
cmp "${metadata}" "${metadata}.before"

write_valid_fixture
cp "${metadata}" "${metadata}.before"
if "${rewriter}" "${metadata}" "https://example.invalid/bottles" "${version}" "${revision}" 2>/dev/null
then
  echo "rewriter accepted an unexpected bottle root URL" >&2
  exit 1
fi
cmp "${metadata}" "${metadata}.before"

write_valid_fixture
cp "${metadata}" "${metadata}.before"
if "${rewriter}" "${metadata}" "${root_url}" "${version}" \
   "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" 2>/dev/null
then
  echo "rewriter accepted metadata from a different formula revision" >&2
  exit 1
fi
cmp "${metadata}" "${metadata}.before"

echo "Bottle root URL rewrite tests passed."
