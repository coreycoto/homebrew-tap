# frozen_string_literal: true

# Run with `brew ruby --`. Use Homebrew's consumer API, not the local archive
# basename, as the authority for release asset names and download URLs.
require "formulary"
require "bottle"
require "json"
require "pathname"
require "uri"

module BottleConsumers
  TAGS = %i[arm64_tahoe x86_64_linux].freeze

  def self.load(path, version, root_url)
    raise "invalid release version" unless version.match?(/\A(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\z/)

    # Keep the installed tap's lexical path: CI links that path to the
    # workspace, while Homebrew rejects arbitrary realpaths outside Taps.
    tap_path = Tap.fetch("coreycoto/tap").path
    relative = Pathname.new(path).realpath.relative_path_from(tap_path.realpath)
    raise "formula must belong to the installed coreycoto/tap" if relative.each_filename.include?("..")

    formula = Formulary.factory(tap_path/relative)
    spec = formula.bottle_specification
    raise "unexpected formula identity" unless formula.name == "git-slop" && formula.pkg_version.to_s == version
    raise "unexpected bottle root URL" unless spec.root_url == root_url
    raise "unexpected bottle platforms" unless spec.collector.tags.map(&:to_sym).sort == TAGS.sort
    raise "bottle rebuild requires an explicit publication change" unless spec.rebuild.zero?

    TAGS.map do |symbol|
      tag = Utils::Bottles::Tag.from_symbol(symbol)
      bottle = Bottle.new(formula, spec, tag)
      filename = Bottle::Filename.create(formula, tag, spec.rebuild)
      # Detect overrides or changed Homebrew URL semantics before any upload.
      raise "unexpected consumer URL" unless bottle.url == "#{root_url}/#{filename.url_encode}"

      record = {
        "tag" => symbol.to_s,
        "local_name" => filename.to_s,
        "name" => filename.url_encode,
        "url" => bottle.url,
        "sha256" => bottle.resource.checksum.hexdigest,
      }
      [record, bottle]
    end
  end

  def self.fetch(entries, timeout: 300)
    entries.each do |record, bottle|
      # There is deliberately no source-build fallback at this boundary.
      bottle.fetch(verify_download_integrity: true, timeout: timeout)
      bottle.verify_download_integrity
      warn "Verified public bottle: #{record.fetch('url')}"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  mode, path, version, root_url = ARGV
  abort "usage: bottle-consumers.rb manifest|fetch FORMULA VERSION ROOT_URL" unless
    ARGV.length == 4 && %w[manifest fetch].include?(mode)

  entries = BottleConsumers.load(path, version, root_url)
  BottleConsumers.fetch(entries) if mode == "fetch"
  puts JSON.pretty_generate(entries.map(&:first))
end
