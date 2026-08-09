class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.10.1.crate"
  sha256 "a13327ce132372bfd196fd64d892d8ce9b073f40cb07ae6964e72d65b11819d2"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.10.1", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"9753ca3d571b2ad74d0608049eac7c0bb2664de5\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
