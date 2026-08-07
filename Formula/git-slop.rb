class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.9.4.crate"
  sha256 "124295547afdffee4db8c849ab613b4f27515a9ae191f8d491df28d0968818db"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.9.4", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"82b8cb1223e914ac0c4c79be7602734bbf1254fb\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
