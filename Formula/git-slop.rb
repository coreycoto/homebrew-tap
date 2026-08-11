class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.11.6.crate"
  sha256 "f4d19ebf8d998b96b199e11c31d343925b0f84427a7d5390e6c9082c9b06c658"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.11.6"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "1f0ef01d2a7b4fc32029ddcf3b9c2102713070926d43531f67b33cdf1015af2c"
    sha256 cellar: :any,                 x86_64_linux: "05e42bd67f9d4112c0a1746a2904729d524d0c0b05b170fdf5a40fd61b8baaa1"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.11.6", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"74068ca8669baa489712b974cbb74a093e0f9cff\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
