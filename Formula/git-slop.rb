class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.10.1.crate"
  sha256 "a13327ce132372bfd196fd64d892d8ce9b073f40cb07ae6964e72d65b11819d2"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.10.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "5d92793e2e0da4153b3bbcdef08411bb40b010341cccc6ce49a76948a43b37e6"
    sha256 cellar: :any,                 x86_64_linux: "9555e9c9f3be8b44742eb877365537211d072d8fdfbf168559ffc468af82eb69"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.10.1", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"9753ca3d571b2ad74d0608049eac7c0bb2664de5\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
