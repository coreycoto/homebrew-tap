class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.16.0.crate"
  sha256 "041c8a61b3001912082be7d6f8ab23e2ea84ac82e7f9a93636abce8dba285c47"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-bottles-v2-0.16.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "1747aedcc4ee4fd58aaddbb51fd7c98e273b6fdb08282b4ffba11ca27a592187"
    sha256 cellar: :any,                 x86_64_linux: "70b9bf7dc7b9f035e9544576e0e0434951cb04d3f67bc896a7640915573af370"
  end

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
