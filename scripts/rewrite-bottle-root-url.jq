if (
  type == "object" and
  keys == ["coreycoto/tap/git-slop"] and
  .["coreycoto/tap/git-slop"].formula.name == "git-slop" and
  .["coreycoto/tap/git-slop"].formula.pkg_version == $version and
  .["coreycoto/tap/git-slop"].formula.tap_git_path == "Formula/git-slop.rb" and
  .["coreycoto/tap/git-slop"].formula.tap_git_revision == $revision and
  .["coreycoto/tap/git-slop"].formula.tap_git_remote ==
    "https://github.com/coreycoto/homebrew-tap" and
  (.["coreycoto/tap/git-slop"].bottle.root_url | type) == "string" and
  (.["coreycoto/tap/git-slop"].bottle.tags | type) == "object" and
  (.["coreycoto/tap/git-slop"].bottle.tags | length) == 1
) then
  .["coreycoto/tap/git-slop"].bottle.root_url = $root_url
else
  error("unexpected git-slop bottle metadata")
end
