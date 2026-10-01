class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.16.3.crate"
  sha256 "154d2d14463ee0ab89d1fbbfe29d1e44999fb455d663d639c22e9fe0ab1197b3"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.16.3", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"9ba860d04ae83f02ebaf5356261d5624e8647dfa\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
