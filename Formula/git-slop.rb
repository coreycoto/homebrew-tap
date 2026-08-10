class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.11.1.crate"
  sha256 "f3f0de939d101b7ca68309d03c5bac3fdf110074dbfd8a510bc73496bbdb50ab"
  license "MIT"

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
