class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.14.0.crate"
  sha256 "314707f62c24d5608348c82d04342d31487f7cc46b574bc9191dc08550ae1a46"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.14.0", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"52991bca3944391fbdfacbaa7fb568a8645d9f8e\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
