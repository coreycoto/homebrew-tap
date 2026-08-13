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
