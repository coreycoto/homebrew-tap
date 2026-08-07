class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.9.5.crate"
  sha256 "54ec92ec65a602591a001cb9c3cc621488f1de6d7d2813ec414752227887b86e"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.9.5"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "64bbd52fd78fc880ba6a7884accd4b2606085e7243362e2c43be336ba76442ed"
    sha256 cellar: :any,                 x86_64_linux: "2b2895f65cd994bc535a9195d722aebd16bf6ac96b79ea8cc5bd311e2f6aa355"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.9.5", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"aebb311bb8f280817dd8150e3a8f1e6f5ac833e9\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
