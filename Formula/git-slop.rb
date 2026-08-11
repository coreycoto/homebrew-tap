class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.11.8.crate"
  sha256 "0fa4d4be92429cab7b0788a14e1d62817f784b8998d60e2dfa1d10a3c45e34c5"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.11.8"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "79518e6940455841db5508472bf29203b4bf7c8dcfcf2816ebc72abf91098018"
    sha256 cellar: :any,                 x86_64_linux: "ce673b90d6992bd4ddf7c20b427133f76ac5bd9fce34842bc71c8b3c675fc1ba"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.11.8", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"bf86c7f3796af856f76a840d42d5661bc1623f95\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
