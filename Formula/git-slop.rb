class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.9.2.crate"
  sha256 "48df3903186deb213dc1515296e6173c930a1430308b59f1b5c237b3f1d96807"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.9.2", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"7dc5e45c526c2f94118a9b496a087fd308362bfe\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
