# frozen_string_literal: true

# Run in CI with `HOMEBREW_CACHE=$(mktemp -d) brew ruby -- ...`.
# These are real Homebrew Bottle/DownloadStrategy calls against a loopback HTTP
# fixture, not a mock implementation of Homebrew's filename rules.
require_relative "bottle-consumers"
require "digest"
require "English"
require "socket"
require "tmpdir"
require "timeout"
require "stringio"
require "zlib"
require "rubygems/package"

VERSION = "0.16.0"

def assert(value, message)
  raise message unless value
end

def rejects(error_class, message)
  begin
    yield
  rescue error_class
    return
  end
  raise message
end

def archive_bytes(tag)
  tar = StringIO.new
  Gem::Package::TarWriter.new(tar) do |writer|
    content = "#!/bin/sh\nprintf 'git-slop #{VERSION} (#{tag})\\n'\n"
    writer.add_file_simple("git-slop/#{VERSION}/bin/git-slop", 0o755, content.bytesize) do |entry|
      entry.write(content)
    end
  end
  gzip = StringIO.new
  Zlib::GzipWriter.wrap(gzip) { |writer| writer.write(tar.string) }
  gzip.string
end

routes = {}
requests = []
server = TCPServer.new("127.0.0.1", 0)
port = server.addr[1]
thread = Thread.new do
  loop do
    client = server.accept
    begin
      Timeout.timeout(5) do
        request = client.gets.to_s.split
        headers = []
        while (line = client.gets) && line != "\r\n"
          headers << line
        end
        requests << [request[1], headers]
        body = routes[request[1]]
        status = body ? "200 OK" : "404 Not Found"
        body ||= "not found"
        client.write("HTTP/1.1 #{status}\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n")
        client.write(body) unless request[0] == "HEAD"
      end
    ensure
      client.close
    end
  end
rescue IOError, Errno::EBADF
  # The ensure block below closes the listening socket after the tests.
end

begin
  Dir.mktmpdir("bottle-consumer-fixtures-") do |dir|
    payloads = BottleConsumers::TAGS.to_h { |tag| [tag, archive_bytes(tag)] }
    fixture = lambda do |name, mutation = nil|
      root = "http://127.0.0.1:#{port}/#{name}"
      path = Pathname.new(dir)/name/"git-slop.rb"
      path.dirname.mkpath
      content = <<~FORMULA
        class GitSlop < Formula
          desc "Consumer test fixture"
          homepage "https://example.invalid"
          url "https://example.invalid/git-slop-#{VERSION}.tar.gz"
          sha256 "#{'b' * 64}"
          bottle do
            root_url "#{root}"
            sha256 cellar: :any_skip_relocation, arm64_tahoe: "#{Digest::SHA256.hexdigest(payloads.fetch(:arm64_tahoe))}"
            sha256 cellar: :any_skip_relocation, x86_64_linux: "#{Digest::SHA256.hexdigest(payloads.fetch(:x86_64_linux))}"
          end
        end
      FORMULA
      content = mutation.call(content) if mutation
      path.write(content)
      [path, root]
    end

    path, root = fixture.call("valid")
    entries = BottleConsumers.load(path, VERSION, root)
    entries.each do |record, _bottle|
      tag = record.fetch("tag")
      assert(record.fetch("name") == "git-slop-#{VERSION}.#{tag}.bottle.tar.gz", "wrong consumer filename")
      assert(record.fetch("local_name") == "git-slop--#{VERSION}.#{tag}.bottle.tar.gz", "wrong local filename")
      routes[URI(record.fetch("url")).path] = payloads.fetch(tag.to_sym)
    end
    BottleConsumers.fetch(entries, timeout: 5)
    entries.each do |_record, bottle|
      listing = IO.popen(["tar", "-tzf", bottle.cached_download.to_s], &:read)
      assert($CHILD_STATUS.success?, "downloaded archive could not be read")
      assert(listing.include?("git-slop/#{VERSION}/bin/git-slop"), "wrong archive downloaded")
    end

    %w[double-hyphen missing-linux corrupt].each do |scenario|
      path, root = fixture.call(scenario)
      entries = BottleConsumers.load(path, VERSION, root)
      entries.each do |record, _bottle|
        next if scenario == "missing-linux" && record.fetch("tag") == "x86_64_linux"

        name = scenario == "double-hyphen" ? record.fetch("local_name") : record.fetch("name")
        body = scenario == "corrupt" ? "wrong bytes" : payloads.fetch(record.fetch("tag").to_sym)
        routes["/#{scenario}/#{name}"] = body
      end
      error = scenario == "corrupt" ? ChecksumMismatchError : DownloadError
      rejects(error, "consumer accepted #{scenario}") { BottleConsumers.fetch(entries, timeout: 5) }
    end

    path, root = fixture.call("identity")
    rejects(RuntimeError, "accepted wrong version") { BottleConsumers.load(path, "0.16.1", root) }
    rejects(RuntimeError, "accepted wrong root") { BottleConsumers.load(path, VERSION, "#{root}/wrong") }
    path, root = fixture.call("platform", ->(text) { text.sub("arm64_tahoe:", "arm64_sonoma:") })
    rejects(RuntimeError, "accepted wrong platform set") { BottleConsumers.load(path, VERSION, root) }
    path, root = fixture.call("rebuild", ->(text) { text.sub("bottle do", "bottle do\n    rebuild 1") })
    rejects(RuntimeError, "accepted an unhandled rebuild") { BottleConsumers.load(path, VERSION, root) }

    if OS.mac?
      path, root = fixture.call("fallback")
      formula = Formulary.factory(path)
      %i[arm64_tahoe arm64_golden_gate].each do |symbol|
        tag = Utils::Bottles::Tag.from_symbol(symbol)
        bottle = Bottle.new(formula, formula.bottle_specification, tag)
        assert(bottle.tag.to_sym == :arm64_tahoe, "#{symbol} did not select the compatible Tahoe bottle")
        assert(bottle.url.end_with?(".arm64_tahoe.bottle.tar.gz"), "fallback changed the consumer URL")
      end
    end
    assert(!requests.empty?, "no actual HTTP requests were made")
    assert(requests.all? { |_, headers| headers.none? { |line| line.match?(/\AAuthorization:/i) } }, "download used credentials")
    assert(requests.all? { |path, _| path.end_with?(".bottle.tar.gz") }, "unexpected source-download fallback")
  end
  puts "Homebrew consumer download, checksum, identity and macOS selection tests passed."
ensure
  server.close
  thread.join(6)
  thread.kill if thread.alive?
end
