#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
legacy=https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-bottles-v2-0.16.0
current=https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-v0.16.0
cat >"${work}/legacy.rb" <<EOF
class GitSlop < Formula
  url "https://static.crates.io/crates/git-slop/git-slop-0.16.0.crate"
  bottle do
    root_url "${legacy}"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "unchanged"
  end
end
EOF
cp "${work}/legacy.rb" "${work}/actual.rb"
sed "s|${legacy}|${current}|" "${work}/legacy.rb" >"${work}/expected.rb"
"${repo_root}/scripts/repair-git-slop-bottles.sh" rewrite "${work}/actual.rb"
cmp "${work}/expected.rb" "${work}/actual.rb"
"${repo_root}/scripts/repair-git-slop-bottles.sh" rewrite "${work}/actual.rb"
cmp "${work}/expected.rb" "${work}/actual.rb"

for scenario in wrong-version wrong-root duplicate-legacy duplicate-current both-roots
do
  case "${scenario}" in
    wrong-version) sed 's/git-slop-0.16.0.crate/git-slop-0.16.1.crate/' "${work}/legacy.rb" ;;
    wrong-root) sed "s|${legacy}|https://example.invalid|" "${work}/legacy.rb" ;;
    duplicate-legacy) awk '{ print; if (/root_url/) print }' "${work}/legacy.rb" ;;
    duplicate-current) awk '{ print; if (/root_url/) print }' "${work}/expected.rb" ;;
    both-roots) awk -v root="${current}" '{ print; if (/root_url/) print "    root_url \"" root "\"" }' "${work}/legacy.rb" ;;
    *) exit 1 ;;
  esac >"${work}/rejected.rb"
  cp "${work}/rejected.rb" "${work}/before.rb"
  if "${repo_root}/scripts/repair-git-slop-bottles.sh" rewrite "${work}/rejected.rb"
  then
    echo "Migration accepted ${scenario}" >&2
    exit 1
  fi
  cmp "${work}/before.rb" "${work}/rejected.rb"
done
echo "Legacy bottle migration tests passed (exact root-only change, retry, and five rejected inputs)."
