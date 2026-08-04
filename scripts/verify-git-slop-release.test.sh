#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/git-slop-release-test.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

fixture_root="$test_root/fixtures"
fake_bin="$test_root/bin"
mkdir -p "$fixture_root" "$fake_bin"

version="0.9.0"
revision="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
bad_revision="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
release_base="https://github.com/coreycoto/git-slop/releases/download/v${version}"
formula_url="${release_base}/git-slop.rb"
manifest_url="${release_base}/release-manifest.json"
crate_url="https://static.crates.io/crates/git-slop/git-slop-${version}.crate"

sha256_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  else
    shasum -a 256 "$path" | awk '{print $1}'
  fi
}

write_formula() {
  cat >"$fixture_root/git-slop.rb" <<EOF
class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "${crate_url}"
  version "${version}"
  sha256 "${crate_sha256}"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop ${version}", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match %("source_revision": "${revision}"), build_info
    assert_match %("source_dirty": false), build_info
  end
end
EOF
}

write_manifest() {
  local manifest_revision="$1"
  jq -n \
    --arg version "$version" \
    --arg revision "$manifest_revision" \
    --arg crate_url "$crate_url" \
    --arg crate_sha256 "$crate_sha256" '
      {
        schema_version: 3,
        project: "git-slop",
        repository: "coreycoto/git-slop",
        version: $version,
        tag: ("v" + $version),
        revision: $revision,
        artifacts: [],
        crate_source: {
          registry: "crates.io",
          package: "git-slop",
          version: $version,
          url: $crate_url,
          sha256: $crate_sha256,
          revision: $revision,
          vcs_dirty: false
        }
      }
    ' >"$fixture_root/release-manifest.json"
}

write_checksums() {
  formula_sha256="$(sha256_file "$fixture_root/git-slop.rb")"
  manifest_sha256="$(sha256_file "$fixture_root/release-manifest.json")"
  {
    printf '%s  %s\n' "$formula_sha256" git-slop.rb
    printf '%s  %s\n' "$manifest_sha256" release-manifest.json
  } >"$fixture_root/SHA256SUMS"
}

cat >"$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
url=""
output=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      output="$2"
      shift 2
      ;;
    https://*)
      url="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done
[[ -n "$url" && -n "$output" ]]
cp "${FIXTURE_ROOT}/${url##*/}" "$output"
EOF

cat >"$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == "ls-remote" ]]
printf '%s\trefs/tags/v%s\n' "$FAKE_RELEASE_REVISION" "$FAKE_RELEASE_VERSION"
EOF

chmod +x "$fake_bin/curl" "$fake_bin/git"

crate_tree="$test_root/crate/git-slop-${version}"
mkdir -p "$crate_tree"
cat >"$crate_tree/.cargo_vcs_info.json" <<EOF
{
  "git": {
    "sha1": "${revision}"
  },
  "path_in_vcs": ""
}
EOF
tar -C "$test_root/crate" \
  -czf "$fixture_root/git-slop-${version}.crate" \
  "git-slop-${version}"
crate_sha256="$(sha256_file "$fixture_root/git-slop-${version}.crate")"

write_formula
write_manifest "$revision"
write_checksums

run_verifier() {
  local output_dir="$1"
  FIXTURE_ROOT="$fixture_root" \
  FAKE_RELEASE_REVISION="$revision" \
  FAKE_RELEASE_VERSION="$version" \
  CURL_BIN="$fake_bin/curl" \
  GIT_BIN="$fake_bin/git" \
  RELEASE_VERSION="$version" \
  RELEASE_REVISION="$revision" \
  FORMULA_URL="$formula_url" \
  FORMULA_SHA256="$formula_sha256" \
  MANIFEST_URL="$manifest_url" \
  MANIFEST_SHA256="$manifest_sha256" \
  CRATE_URL="$crate_url" \
  CRATE_SHA256="$crate_sha256" \
    "$repo_root/scripts/verify-git-slop-release.sh" "$output_dir"
}

run_verifier "$test_root/success"

if "$repo_root/scripts/verify-git-slop-formula-state.sh" \
  "$fixture_root/git-slop.rb" \
  "$fixture_root/git-slop.rb"
then
  echo "source-only formula unexpectedly passed terminal-state verification" >&2
  exit 1
fi

formula_with_bottle="$test_root/git-slop-with-bottle.rb"
awk '
  /^  depends_on "rust" => :build$/ && !inserted {
    print "  bottle do"
    print "    root_url \"https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.9.0\""
    print "    sha256 cellar: :any_skip_relocation, arm64_tahoe: \"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef\""
    print "    sha256 cellar: :any_skip_relocation, x86_64_linux: \"abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789\""
    print "  end"
    print ""
    inserted = 1
  }
  { print }
' "$fixture_root/git-slop.rb" > "$formula_with_bottle"
"$repo_root/scripts/verify-git-slop-formula-state.sh" \
  "$fixture_root/git-slop.rb" \
  "$formula_with_bottle"

sed '/x86_64_linux/d' \
  "$formula_with_bottle" > "$test_root/git-slop-one-platform.rb"
if "$repo_root/scripts/verify-git-slop-formula-state.sh" \
  "$fixture_root/git-slop.rb" \
  "$test_root/git-slop-one-platform.rb"
then
  echo "single-platform bottle block unexpectedly passed verification" >&2
  exit 1
fi

sed 's/    sha256 cellar:/    system "unexpected"\n    sha256 cellar:/' \
  "$formula_with_bottle" > "$test_root/git-slop-unsafe-bottle.rb"
if "$repo_root/scripts/verify-git-slop-formula-state.sh" \
  "$fixture_root/git-slop.rb" \
  "$test_root/git-slop-unsafe-bottle.rb"
then
  echo "unsafe bottle block unexpectedly passed verification" >&2
  exit 1
fi

sed 's/  depends_on "rust" => :build/  depends_on "python"/' \
  "$formula_with_bottle" > "$test_root/git-slop-formula-drift.rb"
if "$repo_root/scripts/verify-git-slop-formula-state.sh" \
  "$fixture_root/git-slop.rb" \
  "$test_root/git-slop-formula-drift.rb"
then
  echo "formula drift outside the bottle block unexpectedly passed verification" >&2
  exit 1
fi

printf '\n# unexpected formula code\n' >>"$fixture_root/git-slop.rb"
write_checksums
if run_verifier "$test_root/formula-drift"; then
  echo "formula drift unexpectedly passed verification" >&2
  exit 1
fi

write_formula
write_manifest "$bad_revision"
write_checksums
if run_verifier "$test_root/manifest-drift"; then
  echo "manifest identity drift unexpectedly passed verification" >&2
  exit 1
fi

write_manifest "$revision"
write_checksums
printf '%s  %s\n' "$formula_sha256" git-slop.rb >>"$fixture_root/SHA256SUMS"
if run_verifier "$test_root/duplicate-checksum"; then
  echo "duplicate checksum entry unexpectedly passed verification" >&2
  exit 1
fi

cat >"$crate_tree/.cargo_vcs_info.json" <<EOF
{
  "git": {
    "sha1": "${revision}",
    "dirty": true
  },
  "path_in_vcs": ""
}
EOF
tar -C "$test_root/crate" \
  -czf "$fixture_root/git-slop-${version}.crate" \
  "git-slop-${version}"
crate_sha256="$(sha256_file "$fixture_root/git-slop-${version}.crate")"
write_formula
write_manifest "$revision"
write_checksums
if run_verifier "$test_root/dirty-crate"; then
  echo "dirty crate VCS metadata unexpectedly passed verification" >&2
  exit 1
fi

echo "git-slop release verifier tests passed"
