class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.11.1.crate"
  sha256 "f3f0de939d101b7ca68309d03c5bac3fdf110074dbfd8a510bc73496bbdb50ab"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.11.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "eaff76c1bae1a02dcf8231c9f4d48606ebf4315e8345850e0befb2d82f9d7f88"
    sha256 cellar: :any,                 x86_64_linux: "8d578f63f9b9434e905788e805890cbfc48a2238f734b759d40349d34bbf406a"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.11.1", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"532f82ba1a5e20944f2584ca5cd1f30582f188cc\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
