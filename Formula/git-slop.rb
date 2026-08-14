class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.13.0.crate"
  sha256 "876921816b691ea9f050cbb623fe57b4b9b64b09811d7252d5c7b764eba8e26a"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.13.0", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"142cc5452b60be67b7b55a20ff9488178a5f4dee\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
