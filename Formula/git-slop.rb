class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.15.0.crate"
  sha256 "140a8232ba75fcf0bbb03e406dd1d4ce9a7034a4913728faf547595126dfe190"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-bottles-v2-0.15.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "1dc64f60e5b9a3b7d4776bfe2338761059baf705cc18b4d876c923bcc5bd3318"
    sha256 cellar: :any,                 x86_64_linux: "957a8f90f000347b720da6ab92cbc1d1b87fec96f7d7436d428b492571d5ad85"
  end

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
