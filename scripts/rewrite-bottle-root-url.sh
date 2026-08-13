#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" != 3 ]]; then
  echo "usage: $0 BOTTLE_JSON ROOT_URL VERSION" >&2
  exit 64
fi

metadata="$1"
root_url="$2"
version="$3"

[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
expected_root_url="https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-bottles-v2-${version}"
test "$root_url" = "$expected_root_url"
test -f "$metadata"

rewritten="$(mktemp "${metadata}.root-url.XXXXXX")"
trap 'rm -f -- "$rewritten"' EXIT

jq -e \
  --arg root_url "$root_url" \
  --arg version "$version" '
    if (
      type == "object" and
      keys == ["git-slop"] and
      .["git-slop"].formula.pkg_version == $version and
      .["git-slop"].formula.path == "Formula/git-slop.rb" and
      (.["git-slop"].bottle.root_url | type) == "string" and
      (.["git-slop"].bottle.tags | type) == "object" and
      (.["git-slop"].bottle.tags | length) == 1
    ) then
      .["git-slop"].bottle.root_url = $root_url
    else
      error("unexpected git-slop bottle metadata")
    end
  ' "$metadata" > "$rewritten"

mv "$rewritten" "$metadata"
trap - EXIT
