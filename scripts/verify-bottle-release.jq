# Compare the release with Homebrew-derived consumer URLs and formula digests.
# An immutable release may be reused, never refreshed or overwritten.
def consumer_url_matches($consumer; $draft):
  .browser_download_url == $consumer.url or
  ($draft and
    ((.browser_download_url | split("/")) as $actual |
     ($consumer.url | split("/")) as $wanted |
     ($actual | length) == ($wanted | length) and
     $actual[0:-2] == $wanted[0:-2] and
     ($actual[-2] | test("^untagged-[0-9a-f]+$")) and
     $actual[-1] == $wanted[-1]));

.draft as $draft |
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
(
  if ($ARGS.named.allow_partial // false) then
    .draft == true and (.assets | length) <= 2
  else
    (.assets | length) == 2
  end
) and
([.assets[].name] | unique | length) == (.assets | length) and
all(.assets[]; .state == "uploaded" and (.size | type) == "number" and .size > 0) and
all(.assets[]; . as $asset |
  [$expected[0][] | . as $consumer |
    select($asset.name == .name and $asset.digest == ("sha256:" + .sha256) and
      ($asset | consumer_url_matches($consumer; $draft)))] | length == 1
)
