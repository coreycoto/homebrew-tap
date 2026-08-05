class GitSlop < Formula
  desc "Deterministic repository health analysis for humans and AI agents"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://static.crates.io/crates/git-slop/git-slop-0.9.2.crate"
  sha256 "48df3903186deb213dc1515296e6173c930a1430308b59f1b5c237b3f1d96807"
  license "MIT"

  bottle do
    root_url "https://github.com/coreycoto/homebrew-tap/releases/download/git-slop-0.9.2"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "e24ca6b89193b2b513ac9aac7fa29bd143b54a90fdf711409e81995f3142c419"
    sha256 cellar: :any,                 x86_64_linux: "3504f4571cb2b3be06fc6e24b6091b6ba92a1ed8bdd9f2d50c468c2360e22d7d"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "man/git-slop.1"
  end

  test do
    assert_match "git-slop 0.9.2", shell_output("#{bin}/git-slop version")
    build_info = shell_output("#{bin}/git-slop build-info --format json")
    assert_match "\"source_revision\": \"7dc5e45c526c2f94118a9b496a087fd308362bfe\"", build_info
    assert_match "\"source_dirty\": false", build_info
  end
end
