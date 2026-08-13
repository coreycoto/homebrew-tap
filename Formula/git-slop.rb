class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.12.1.crate"
  sha256 "27633b1ce3fb7363f713f64acc47c598bebaf9bdf55562f560b0d964e50bea05"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
    generate_completions_from_executable(bin/"git-slop", "completions")
  end

  test do
    assert_match "git-slop 0.12.1", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"979cfd9430079a90b5895978daf3b610112f68fb\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
