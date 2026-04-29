require "json"
require "net/http"
require "uri"

class GitSlopPrivateReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    @asset_name = meta.delete(:asset_name)
    @github_token = ENV["HOMEBREW_GITHUB_API_TOKEN"] || ENV["GITHUB_TOKEN"] || ENV["GH_TOKEN"]
    if @github_token.blank?
      odie "Set HOMEBREW_GITHUB_API_TOKEN, GITHUB_TOKEN, or GH_TOKEN with access to coreycoto/git-slop."
    end

    meta[:headers] ||= []
    meta[:headers] << "Authorization: Bearer #{@github_token}"
    meta[:headers] << "Accept: application/octet-stream"
    super
  end

  private

  def resolve_url_basename_time_file_size(url, timeout: nil)
    super(resolve_asset_api_url(url), timeout: timeout)
  end

  def _fetch(url:, resolved_url:, timeout:)
    super(url: resolve_asset_api_url(url), resolved_url: resolved_url, timeout: timeout)
  end

  def resolve_asset_api_url(release_api_url)
    return release_api_url if release_api_url.include?("/releases/assets/")

    @resolve_asset_api_url ||= begin
      uri = URI(release_api_url)
      uri.query = nil
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@github_token}"
      request["Accept"] = "application/vnd.github+json"
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
      unless response.is_a?(Net::HTTPSuccess)
        odie "Unable to read git-slop release metadata from #{release_api_url}: HTTP #{response.code}"
      end
      asset = JSON.parse(response.body).fetch("assets").find do |candidate|
        candidate.fetch("name") == @asset_name
      end
      odie "Release asset #{@asset_name} was not found in #{release_api_url}." if asset.nil?
      asset.fetch("url")
    end
  end
end

class GitSlop < Formula
  include Language::Python::Virtualenv

  desc "Local-first hotspot detection for AI-era repositories"
  homepage "https://github.com/coreycoto/git-slop"
  url "https://api.github.com/repos/coreycoto/git-slop/releases/tags/v0.7.2?asset=git_slop-0.7.2.tar.gz",
      using:      GitSlopPrivateReleaseDownloadStrategy,
      asset_name: "git_slop-0.7.2.tar.gz"
  version "0.7.2"
  sha256 "d033fd8ab71f123785d63e5b2aa9e97f1991b7d7ff5c4b18a5bb6b78a3ad7fd1"
  license "MIT"

  depends_on "rust" => :build

  depends_on "libyaml"
  depends_on "python@3.13"

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/af/2d/7bf41579a8986e348fa033a31cdd0e4121114f6bce2457e8876010b092dd/certifi-2026.2.25.tar.gz"
    sha256 "e887ab5cee78ea814d3472169153c2d12cd43b14bd03329a39a9c6e2e80bfba7"
  end

  resource "charset-normalizer" do
    url "https://files.pythonhosted.org/packages/e7/a1/67fe25fac3c7642725500a3f6cfe5821ad557c3abb11c9d20d12c7008d3e/charset_normalizer-3.4.7.tar.gz"
    sha256 "ae89db9e5f98a11a4bf50407d4363e7b09b31e55bc117b4f7d80aab97ba009e5"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/22/12/2948fbe5513d062169bd91f7d7b1cd97bc8894f32946b71fa39f6e63ca0c/idna-3.12.tar.gz"
    sha256 "724e9952cc9e2bd7550ea784adb098d837ab5267ef67a1ab9cf7846bdbdd8254"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/c7/24/5f1b3bdffd70275f6661c76461e25f024d5a38a46f04aaca912426a2b1d3/urllib3-2.6.3.tar.gz"
    sha256 "1b62b6884944a57dbe321509ab94fd4d3b307075e0c2eae991ac71ee15ad38ed"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/5f/a4/98b9c7c6428a668bf7e42ebb7c79d576a1c3c1e3ae2d47e674b468388871/requests-2.33.1.tar.gz"
    sha256 "18817f8c57c6263968bc123d237e3b8b08ac046f5456bd1e307ee8f4250d3517"
  end

  resource "regex" do
    url "https://files.pythonhosted.org/packages/cb/0e/3a246dbf05666918bd3664d9d787f84a9108f6f43cc953a077e4a7dfdb7e/regex-2026.4.4.tar.gz"
    sha256 "e08270659717f6973523ce3afbafa53515c4dc5dcad637dc215b6fd50f689423"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  resource "tiktoken" do
    url "https://files.pythonhosted.org/packages/7d/ab/4d017d0f76ec3171d469d80fc03dfbb4e48a4bcaddaa831b31d526f05edc/tiktoken-0.12.0.tar.gz"
    sha256 "b18ba7ee2b093863978fcb14f74b3707cdc8d4d4d3836853ce7ec60772139931"
  end

  def install
    virtualenv_install_with_resources using: "python3.13"
  end

  test do
    assert_match "git-slop", shell_output("#{bin}/git-slop version")
  end
end
