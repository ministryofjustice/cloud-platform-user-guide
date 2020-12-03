#!/usr/bin/env ruby

require "nokogiri"
require "date"
require "json"
require "net/http"

# This script spider a url and get all links to other pages,
# subract with the list of files in the docs and give the list 
# of orphaned files which are present in the docs/ folder but not linked
# anywhere in the index or other html pages.

DOCS_PATH = "docs/documentation"
SITE_URL = "https://user-guide.cloud-platform.service.justice.gov.uk/"

def page_urls(root_url)
  get_all_urls(root_url, root_url)
    .select { |_url, url| url.slice!(SITE_URL) }
    .values
end

# Spider a URL looking for links to other pages.
# Return a hash: { unique_page_url => url }
def get_all_urls(url, root_url, hash = {})
  return if hash.has_key?(url)

  doc = get_nokogiri_doc(url)
  hash[url] = url
  get_links(doc).map { |path| get_all_urls([root_url, path].join, root_url, hash) }

  hash
end

def get_links(doc)
  doc.css('a')
    .map { |link| link.attributes.dig("href").value }
    .map { |href| normalise_href(href) }.compact
    .uniq
end

def get_nokogiri_doc(url)
  page = fetch_url(url)
  Nokogiri::HTML(page.body)
end

def fetch_url(url)
  uri = URI.parse(url)
  Net::HTTP.get_response(uri)
end

# Return a normalised href value, or nil if we don't like this href
def normalise_href(href)
  # ignore links which are external, or to in-page anchors
  return nil if href[0] == "#" || ["/", "http", "mail", "/ima"].include?(href[0,4])

  # Remove any trailing anchors, or "/"
  target = href.sub(/\#.*/, "").sub(/\/$/, "")

  # Ignore links which don't point to html files
  target =~ /html$/ ? target : nil
end

############################################################

# DOCUMENTATION_SITES should be something like:
# export DOCUMENTATION_SITES="https://user-guide.cloud-platform.service.justice.gov.uk"
# NB: When this becomes too long for a bash string, we will need to
# use an alternative mechanism for passing the list of URLs
sites = SITE_URL

pages = page_urls(SITE_URL).flatten

files = Dir["#{DOCS_PATH}/**/*.html"].select { |f| f.slice!("docs") }

orphaned_files = files - pages

puts orphaned_files
