class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.9.3.crate"
  sha256 "d6b7ba0c90138c13cc5e3da6d04a2e3df08dac3b737f336f384d7ceea4860e8f"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.9.3", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"a133a798f9df7ce1c56d496efba2435ee2b1f039\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
