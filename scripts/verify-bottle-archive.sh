#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" != 2 ]]
then
  echo "usage: verify-bottle-archive.sh BOTTLE VERSION" >&2
  exit 2
fi

bottle="$1"
version="$2"

[[ "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || {
  echo "error: invalid release version: ${version}" >&2
  exit 1
}

test -f "${bottle}"
test -s "${bottle}"

case "$(basename "${bottle}")" in
  "git-slop--${version}.arm64_tahoe.bottle.tar.gz" | "git-slop--${version}.x86_64_linux.bottle.tar.gz") ;;
  *)
    echo "error: unexpected git-slop bottle archive: $(basename "${bottle}")" >&2
    exit 1
    ;;
esac
