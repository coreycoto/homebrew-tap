class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.10.0.crate"
  sha256 "92d8b56754f12442979bc350c57baf8ef0119f5c7629dda08bbe72a57ed90067"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.10.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "5ff873aa04586110ddff09b8f39fced58fb85470a33a095aeeb6133550afc24f"
    sha256 cellar: :any,                 x86_64_linux: "0417b3b60b2650fe9d96fd705bd6c9218670555c91df343e155851b1e00a95ed"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.10.0", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"c21e1acfb3cd302f3147aec4635f1d1feb0817de\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
