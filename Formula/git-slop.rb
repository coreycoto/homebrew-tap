class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.16.3.crate"
  sha256 "154d2d14463ee0ab89d1fbbfe29d1e44999fb455d663d639c22e9fe0ab1197b3"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-v0.16.3"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "04ca909f1fb1cbf763cc060039d426db77da5e5384db256d18c678861234bef1"
    sha256 cellar: :any,                 x86_64_linux: "5db19c1de39140e3530bc1887c4f57190077141b6d4aa24de4c05581e7361ac3"
  end

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
