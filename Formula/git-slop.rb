class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.11.8.crate"
  sha256 "0fa4d4be92429cab7b0788a14e1d62817f784b8998d60e2dfa1d10a3c45e34c5"
  license "MIT"

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
