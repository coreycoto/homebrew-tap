class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.15.0.crate"
  sha256 "140a8232ba75fcf0bbb03e406dd1d4ce9a7034a4913728faf547595126dfe190"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.15.0", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"ad5cdc08768f68a870807aa52c8f32f6512353ad\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
