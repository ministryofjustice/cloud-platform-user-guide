#!/usr/bin/env ruby

INDEXFILE = "source/index.html.md.erb"

def main(pagefile)
  title, url = get_title_and_url(pagefile)
  add_to_index(title, url)
end

def get_title_and_url(pagefile)
  url = pagefile.sub("source/", "").sub(".md.erb", "")
  title = File.read(pagefile).split("\n").grep(/title:/).first.sub("title: ", "")
  [title, url]
end

def add_to_index(title, url)
  line = " - [#{title}](#{url})\n"
  File.write(INDEXFILE, line, mode: "a")
end

main ARGV.shift
