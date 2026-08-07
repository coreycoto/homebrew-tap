class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.9.6.crate"
  sha256 "c219daa5570e8ee8f988f352b1eece6f989b4461ba465bef123dce7c6c02187b"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.9.6"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "d3ff3f8461c1345ce0dce684fb895eae0618c7185ce409e077033dd1e8edb600"
    sha256 cellar: :any,                 x86_64_linux: "8429fc0ee165958af29361de904a60a69e52868581a1b0fb88f83fb6c51d3521"
  end

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
