class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.16.4.crate"
  sha256 "bffe2752d864781b932b7ab65232b898039969fd3947b32934660a9da63bd14c"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-v0.16.4"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "2dede415cf39b4e3caf43b6497ec4e70b3b50b006c76c3d7eecb1cc270efd413"
    sha256 cellar: :any,                 x86_64_linux: "8fd5c92ce2e4d5badc88d119221da88c231e49c7642160d3c6a08fbbcf0861f7"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.16.4", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"7ce9cfedc590d43321ee09e03a5240ae1538acb2\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
