#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
jq_filter="${repo_root}/scripts/rewrite-bottle-root-url.jq"

if [[ "$#" != 4 ]]
then
  echo "usage: $0 BOTTLE_JSON ROOT_URL VERSION REVISION" >&2
  exit 64
fi

metadata="$1"
root_url="$2"
version="$3"
revision="$4"

[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "${revision}" =~ ^[0-9a-f]{40}$ ]]
expected_root_url="https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-bottles-v2-${version}"
test "${root_url}" = "${expected_root_url}"
test -f "${metadata}"

rewritten="$(mktemp "${metadata}.root-url.XXXXXX")"
trap 'rm -f -- "$rewritten"' EXIT

jq -e \
  --arg root_url "${root_url}" \
  --arg version "${version}" \
  --arg revision "${revision}" \
  -f "${jq_filter}" \
  "${metadata}" >"${rewritten}"

mv "${rewritten}" "${metadata}"
trap - EXIT
