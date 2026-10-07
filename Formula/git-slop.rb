class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.16.5.crate"
  sha256 "e69436c6b43d71cb93201e6d5ac017356fe1e0e8400ed0b8dc5c2ba1c098712b"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-v0.16.5"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "d7c594f9f9541f66797b1181602c9b0146d46ddf5815415ca2bd8ea088b9c7c1"
    sha256 cellar: :any,                 x86_64_linux: "6a0e2c7c03581cedb6e17b171da97d730bfd19089428433cfefdb1e3353ebca9"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.16.5", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"d0d0aadd7b7975a9e4407d0dba2bd749b21b26f2\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
