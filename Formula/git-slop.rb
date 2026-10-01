class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.16.2.crate"
  sha256 "714483a1fad90e5953a1d6e90908063275aec6b74b324a50f6c440304179c834"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-v0.16.2"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "1659ecb5e3157fce3c681f97e7d86194976d448cb590db9ec352fb70c30ff527"
    sha256 cellar: :any,                 x86_64_linux: "44bd13cf73f16242aee08c25bf2b4faf41a29b8901ccf154ef454d895c9f9248"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.16.2", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"587751bc36a27958aa9d2f374df861a0745cf511\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
