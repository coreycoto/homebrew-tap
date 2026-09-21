#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_dir="$(mktemp -d)"
trap 'rm -rf -- "$fixture_dir"' EXIT
root_url=https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-v0.16.0
jq -n --arg root "$root_url" '
  ["arm64_tahoe", "x86_64_linux"] | map(
    ("git-slop-0.16.0." + . + ".bottle.tar.gz") as $name |
    {name: $name, url: ($root + "/" + $name), sha256: ("a" * 64)}
  )' > "$fixture_dir/consumers.json"
jq -n --slurpfile expected "$fixture_dir/consumers.json" '{
  id: 42, tag_name: "git-slop-v0.16.0", target_commitish: ("b" * 40),
  prerelease: false, draft: true, immutable: false,
  assets: [$expected[0][] | {
    name, browser_download_url: .url, digest: ("sha256:" + .sha256),
    size: 123, state: "uploaded"
  }]
}' > "$fixture_dir/release.json"

check() {
  jq -e --slurpfile expected "$fixture_dir/consumers.json" \
    --arg tag git-slop-v0.16.0 --arg revision bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb \
    --argjson release_id 42 --argjson require_published "${1:-false}" \
    -f "$repo_root/scripts/verify-bottle-release.jq" "$fixture_dir/check.json" >/dev/null
}
cp "$fixture_dir/release.json" "$fixture_dir/check.json"
check false
if check true; then echo 'draft accepted as public' >&2; exit 1; fi
jq '.draft = false | .immutable = true' "$fixture_dir/release.json" > "$fixture_dir/check.json"
check false
check true

for mutation in \
  '.id = 43' \
  '.tag_name = "git-slop"' \
  '.target_commitish = ("c" * 40)' \
  '.prerelease = true' \
  '.draft = false | .immutable = false' \
  '.draft = true | .immutable = true' \
  '.assets = .assets[:1]' \
  '.assets += [.assets[0]]' \
  '.assets[1] = .assets[0]' \
  '.assets[0].name |= sub("git-slop-"; "git-slop--")' \
  '.assets[0].browser_download_url |= sub("git-slop-0"; "git-slop--0")' \
  '.assets[0].digest = ("sha256:" + ("c" * 64))' \
  '.assets[0].digest = null' \
  '.assets[0].state = "starter"' \
  '.assets[0].size = 0'
do
  jq "$mutation" "$fixture_dir/release.json" > "$fixture_dir/check.json"
  if check false; then
    echo "accepted invalid release: $mutation" >&2
    exit 1
  fi
done

# Exercise the actual workflow state gate, including interrupted publication.
state_gate="$(awk '
  /- name: Require compatible formula and bottle release state/ { found=1; next }
  found && /run: \|/ { body=1; next }
  body && /- name:/ { exit }
  body { sub(/^          /, ""); print }
' "$repo_root/.github/workflows/publish.yml")"
test -n "$state_gate"
for published in false true
do
  for state in absent draft immutable invalid
  do
    if FORMULA_PUBLISHED="$published" BOTTLE_RELEASE_STATE="$state" \
      bash -euo pipefail -c "$state_gate" >/dev/null 2>&1
    then
      case "$published:$state" in
        false:absent|false:draft|false:immutable|true:immutable) ;;
        *) echo "unsafe publication state accepted: $published:$state" >&2; exit 1 ;;
      esac
    else
      case "$published:$state" in
        true:absent|true:draft|*:invalid) ;;
        *) echo "valid publication state rejected: $published:$state" >&2; exit 1 ;;
      esac
    fi
  done
done

echo 'Bottle release verification tests passed (draft/public recovery and 15 negative cases).'
