#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

input = JSON.parse($stdin.read) rescue {}

cwd = input.dig("workspace", "current_dir") || Dir.pwd
repo = File.basename(cwd)
model = input.dig("model", "display_name") || "unknown"

def humanize(n)
  case n
  when 0...1_000 then n.to_s
  when 1_000...1_000_000 then "%.1fk" % (n / 1_000.0)
  else "%.1fM" % (n / 1_000_000.0)
  end
end

# Worktrees: subdirectories that are git worktrees
stdout, _, _ = Open3.capture3("git", "-C", cwd, "worktree", "list", "--porcelain")
worktree_paths = stdout
  .scan(/^worktree (.+)/)
  .flatten
  .reject { |path| File.basename(path) == ".bare" }

# Detect GitHub URL from remote
github_url = nil
remote_stdout, _, remote_status = Open3.capture3("git", "-C", cwd, "remote", "get-url", "origin")
if remote_status.success?
  remote = remote_stdout.strip
  if remote =~ %r{github\.com[:/](.+?)(?:\.git)?$}
    github_url = "https://github.com/#{$1}"
  end
end

worktrees = worktree_paths.map do |path|
  name = File.basename(path)
  name = name.split("@", 2).last if name.include?("@")

  # Get branch name for GitHub link
  branch_stdout, _, branch_status = Open3.capture3("git", "-C", path, "rev-parse", "--abbrev-ref", "HEAD")
  branch = branch_status.success? ? branch_stdout.strip : nil

  # Check for uncommitted changes
  _, _, status = Open3.capture3("git", "-C", path, "diff", "--quiet", "HEAD")
  dirty = !status.success?

  display = name.length > 18 ? "\u2026#{name[-18..]}" : name
  display = "#{display}*" if dirty

  # Wrap in OSC 8 hyperlink if we have a GitHub URL and branch
  if github_url && branch
    url = "#{github_url}/tree/#{branch}"
    "\e]8;;#{url}\e\\#{display}\e]8;;\e\\"
  else
    display
  end
end

worktrees.sort_by! { |name| clean = name.gsub(/\e[^\\]*\\/, ""); %w[main main* master master*].include?(clean) ? 0 : 1 }

# Context usage
used = (input.dig("context_window", "used_percentage") || 0).to_f
total_in = input.dig("context_window", "total_input_tokens") || 0
total_out = input.dig("context_window", "total_output_tokens") || 0

# Progress bar
bar_width = 10
filled = (used * bar_width / 100).round.clamp(0, bar_width)
bar = "\u2588" * filled + "\u2591" * (bar_width - filled)

# Colors (ANSI)
cyan  = "\e[36m"
dim   = "\e[2m"
reset = "\e[0m"
bar_color = if used < 60 then "\e[32m"
            elsif used < 85 then "\e[33m"
            else "\e[31m"
            end

line1 = "#{cyan}[#{repo}]#{reset} #{bar_color}#{bar}#{reset} #{dim}#{"%.1f" % used}%#{reset} \u2502 #{dim}#{humanize(total_in)} in / #{humanize(total_out)} out#{reset} \u2502 #{dim}#{model}#{reset}"
line2 = "#{dim}#{worktrees.join("  ")}#{reset}"

begin
  print "#{line1}\n#{line2}"
rescue Errno::EPIPE
  exit 0
end
