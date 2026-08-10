class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.11.5.crate"
  sha256 "ad1b01112a1afe4ad9af09e2a28d8032be114433f65512d784a5f993f85fc9d4"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.11.5", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"6b7ec9033066691d7b0faca7b29d5aa4c1c667f1\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
