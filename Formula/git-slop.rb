class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.9.6.crate"
  sha256 "c219daa5570e8ee8f988f352b1eece6f989b4461ba465bef123dce7c6c02187b"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.9.6", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"279a39977c8bf4d01c3a5cb7835822b265dcd613\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
