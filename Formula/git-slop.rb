class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.16.5.crate"
  sha256 "e69436c6b43d71cb93201e6d5ac017356fe1e0e8400ed0b8dc5c2ba1c098712b"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.16.5", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"d0d0aadd7b7975a9e4407d0dba2bd749b21b26f2\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
