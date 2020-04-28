#!/usr/bin/env ruby

# Script to build the user guide doc/ files, and push to github to publish
# changes. This script is invoked via github actions (see
# .github/workflows/publish-site.yml)

require "bundler/setup"
require File.join(".", File.dirname(__FILE__), "github")

DOMAIN = "user-guide.cloud-platform.service.justice.gov.uk"

def main
  compile_docs_folder
  if passes_html_proofer?
    execute "touch docs/.nojekyll"
    execute "echo #{DOMAIN} > docs/CNAME"
    GithubClient.new.commit_changes("Commit compiled docs files")
  end
end

def compile_docs_folder
  execute "bundle exec middleman build --build-dir docs"
end

def passes_html_proofer?
  _stdout, _stderr, status = execute %[bundle exec htmlproofer ./docs --http-status-ignore 429 --allow-hash-href --url-swap "https?\\:\\/\\/user-guide\\.cloud-platform\\.service\\.justice\\.gov\\.uk:" ./docs]
  status.success?
end

def execute(cmd)
  stdout, stderr, status = Executor.new.execute(cmd)
  log "blue", stdout
  unless status.success?
    log("red", stderr)
    exit 1
  end
  [stdout, stderr, status]
end

def log(colour, message)
  colour_code = case colour
  when "red"
    31
  when "blue"
    34
  when "green"
    32
  else
    raise "Unknown colour #{colour} passed to 'log' method"
  end

  puts "\e[#{colour_code}m#{message}\e[0m"
end

############################################################

main
