#!/usr/bin/env bash

set -euo pipefail

ruby_bin_override="${RUBY_BIN:-}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

ruby_command=()
if [[ -n "${ruby_bin_override}" ]]
then
  ruby_command=("${ruby_bin_override}")
elif command -v ruby >/dev/null 2>&1
then
  ruby_command=(ruby)
elif command -v brew >/dev/null 2>&1
then
  ruby_command=(brew ruby --)
else
  die "Ruby or Homebrew's portable Ruby is required"
fi

[[ $# -eq 2 ]] ||
  die "usage: verify-git-slop-formula-state.sh EXPECTED_FORMULA ACTUAL_FORMULA"

expected_formula="$1"
actual_formula="$2"

[[ -f "${expected_formula}" ]] || die "expected formula is missing"
[[ -f "${actual_formula}" ]] || die "actual formula is missing"

"${ruby_command[@]}" - "${expected_formula}" "${actual_formula}" <<'RUBY'
expected_path, actual_path = ARGV
expected = File.binread(expected_path)
actual_lines = File.binread(actual_path).lines

bottle_starts = actual_lines.each_index.select do |index|
  actual_lines[index] == "  bottle do\n"
end
abort "error: formula must contain exactly one canonical bottle block" unless bottle_starts.length == 1

start_index = bottle_starts.fetch(0)
end_index = ((start_index + 1)...actual_lines.length).find do |index|
  actual_lines[index] == "  end\n"
end
abort "error: bottle block is not terminated" unless end_index

bottle_lines = actual_lines[(start_index + 1)...end_index]
abort "error: bottle block must contain at least one checksum" if bottle_lines.empty?

state = :start
checksum_tags = []
bottle_lines.each do |line|
  case line
  when /\A    root_url "https:\/\/[A-Za-z0-9._~:\/\?#\[\]@!$&'()*+,;=%-]+"\n\z/
    abort "error: root_url is out of order or duplicated" unless state == :start
    state = :root_url
  when /\A    rebuild [1-9][0-9]*\n\z/
    abort "error: rebuild is out of order or duplicated" unless %i[start root_url].include?(state)
    state = :rebuild
  when /\A    sha256 cellar: (?:\:[a-z0-9_]+|"[A-Za-z0-9._+\/-]+"), ([a-z0-9_]+): "[0-9a-f]{64}"\n\z/
    state = :checksums
    checksum_tags << Regexp.last_match(1)
  else
    abort "error: bottle block contains an unexpected line"
  end
end
expected_checksum_tags = %w[arm64_tahoe x86_64_linux]
unless checksum_tags.sort == expected_checksum_tags
  abort "error: bottle block must contain exactly one arm64_tahoe and one x86_64_linux checksum"
end

prefix = actual_lines[0...start_index]
suffix = actual_lines[(end_index + 1)..]
prefix.pop while prefix.last == "\n"
suffix.shift while suffix.first == "\n"
normalized = (prefix + ["\n"] + suffix).join

abort "error: formula differs from the release asset outside its bottle block" unless normalized == expected
RUBY
