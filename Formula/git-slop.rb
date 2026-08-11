class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.11.7.crate"
  sha256 "b4c7e1d61c8dbddca70c982a0b6df57a17a047974036420aeab55804a4d4c1a3"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.11.7"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "408ed2512ac4922e722dd6ddcc7cfe845714ec21c3a11eb9d59721a33c531377"
    sha256 cellar: :any,                 x86_64_linux: "878377202f7c76a3af7eda327c440c64314cedf1a6399b76985c81640e23db0c"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.11.7", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"6682545d413a4e43747b5316b78b7ab612588000\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
