#!/usr/bin/env ruby

def main(filename)
  content = File.read(filename)
  content = change_heading_levels(content)
  content = convert_header_to_block(content)
  output_file(filename, content)
end

def change_heading_levels(content)
  content.split("\n").inject("") { |acc, line| acc += line.sub(/^#(#*)/, "\\1") + "\n" }
end

def convert_header_to_block(content)
  lines = content.strip.split("\n")

  title = lines.shift.sub(/^#+ /, '')

  header = <<EOF
---
title: #{title}
last_reviewed_on: 2019-12-09
review_in: 3 months
---

# <%= current_page.data.title %>
EOF

  lines.unshift(header).join("\n")
end

def output_file(filename, content)
  newfile = filename.sub(/\.md$/, '.html.md.erb')
  File.write(newfile, content)
end

main ARGV.shift
