class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.16.0.crate"
  sha256 "041c8a61b3001912082be7d6f8ab23e2ea84ac82e7f9a93636abce8dba285c47"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.16.0", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"a28f73e97887184c05252c6947bb3fbcd324feae\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
