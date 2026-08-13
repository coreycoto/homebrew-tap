#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rewriter="${repo_root}/scripts/rewrite-bottle-root-url.sh"
fixture_dir="$(mktemp -d)"
trap 'rm -rf -- "$fixture_dir"' EXIT

version="0.12.1"
root_url="https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-bottles-v2-${version}"
metadata="${fixture_dir}/git-slop.bottle.json"

write_valid_fixture() {
  cat > "$metadata" <<'JSON'
{
  "git-slop": {
    "formula": {
      "pkg_version": "0.12.1",
      "path": "Formula/git-slop.rb"
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
"$rewriter" "$metadata" "$root_url" "$version"
jq -e \
  --arg root_url "$root_url" '
    .["git-slop"].bottle.root_url == $root_url and
    .["git-slop"].bottle.tags.arm64_tahoe.sha256 ==
      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  ' "$metadata" >/dev/null

write_valid_fixture
jq '.unexpected = true' "$metadata" > "${metadata}.invalid"
mv "${metadata}.invalid" "$metadata"
cp "$metadata" "${metadata}.before"
if "$rewriter" "$metadata" "$root_url" "$version" 2>/dev/null; then
  echo "rewriter accepted bottle metadata with an unexpected top-level key" >&2
  exit 1
fi
cmp "$metadata" "${metadata}.before"

write_valid_fixture
cp "$metadata" "${metadata}.before"
if "$rewriter" "$metadata" "https://example.invalid/bottles" "$version" 2>/dev/null; then
  echo "rewriter accepted an unexpected bottle root URL" >&2
  exit 1
fi
cmp "$metadata" "${metadata}.before"

echo "Bottle root URL rewrite tests passed."
