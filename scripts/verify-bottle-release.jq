# Compare the release with Homebrew-derived consumer URLs and formula digests.
# An immutable release may be reused, never refreshed or overwritten.
.id == $release_id and
.tag_name == $tag and
.target_commitish == $revision and
.prerelease == false and
(
  (.draft == false and .immutable == true) or
  ($require_published == false and .draft == true and .immutable == false)
) and
($expected | length) == 1 and
($expected[0] | length) == 2 and
(.assets | length) == 2 and
all(.assets[]; .state == "uploaded" and (.size | type) == "number" and .size > 0) and
(
  [.assets[] | {name, url: .browser_download_url, digest}] | sort_by(.name)
) == (
  [$expected[0][] | {name, url, digest: ("sha256:" + .sha256)}] | sort_by(.name)
)
