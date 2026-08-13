class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.12.1.crate"
  sha256 "27633b1ce3fb7363f713f64acc47c598bebaf9bdf55562f560b0d964e50bea05"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-bottles-v2-0.12.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "7e7daf68d64d70fd36020eb6caa88b5b58453afb2b158efa96402dc289fb735a"
    sha256 cellar: :any,                 x86_64_linux: "c1ad564b41ce100b1cff9c86632cf1754f6b757133436f12bf534f94155658a1"
  end

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
