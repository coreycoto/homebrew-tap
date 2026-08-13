#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
verifier="${repo_root}/scripts/verify-bottle-archive.sh"
fixture_dir="$(mktemp -d)"
trap 'rm -rf -- "$fixture_dir"' EXIT

version="0.12.1"

for tag in arm64_tahoe x86_64_linux; do
  bottle="${fixture_dir}/git-slop--${version}.${tag}.bottle.tar.gz"
  printf 'bottle\n' >"$bottle"
  "$verifier" "$bottle" "$version"
done

for rejected in \
  "git-slop-${version}.arm64_tahoe.bottle.tar.gz" \
  "git-slop--${version}.ventura.bottle.tar.gz" \
  "other--${version}.arm64_tahoe.bottle.tar.gz"; do
  bottle="${fixture_dir}/${rejected}"
  printf 'bottle\n' >"$bottle"
  if "$verifier" "$bottle" "$version" 2>/dev/null; then
    echo "verifier accepted unexpected archive name: ${rejected}" >&2
    exit 1
  fi
done

empty_bottle="${fixture_dir}/git-slop--${version}.arm64_tahoe.bottle.tar.gz"
: >"$empty_bottle"
if "$verifier" "$empty_bottle" "$version" 2>/dev/null; then
  echo "verifier accepted an empty bottle archive" >&2
  exit 1
fi

echo "Bottle archive identity tests passed."
