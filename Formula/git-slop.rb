class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.9.1.crate"
  version "0.9.1"
  sha256 "07b733e49941eb0e4892ca9d484b93cab5d65b457a5f748a502587127e22ca33"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.9.1", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match %("source_revision": "3b9c3b191d35dc729f3c0d97a903386c1dc76938"), build_info
    assert_match %("source_dirty": false), build_info
  end
end
