#!/usr/bin/env ruby

# Script to build the user guide doc/ files, and push to github to publish
# changes. This script is invoked via github actions (see
# .github/workflows/publish-site.yml)

require "bundler/setup"
require File.join(".", File.dirname(__FILE__), "github")

DOMAIN = "user-guide.cloud-platform.service.justice.gov.uk"

def main
  if should_rebuild?
    compile_docs_folder
    if passes_html_proofer?
      execute "touch docs/.nojekyll"
      execute "echo #{DOMAIN} > docs/CNAME"
      commit_and_push_docs
    end
  end
end

# This script was previously invoked in response to a 'git push', but
# publishing also does a git push. So, we check here whether the current change
# only affects compiled doc/ files. If that's true, we don't want to do
# anything else.
#
# The logic here may not be needed, since the github action will only trigger
# when a PR is closed. Since publishing the site pushes straight to the master
# branch, without generating a PR, that should be enough to avoid an infinite
# loop, even without this test. Still, it doesn't do any harm, so I'm leaving
# it in.
def should_rebuild?
  files = GithubClient.new.files_in_pr

  rtn = false

  if files.any?
    rtn = files.reject { |f| f =~ /^docs/ }.any?
  else
    puts "Commit changed no files (merge commit?). Proceeding with build."
  end

  rtn
end

def this_commit
  commit, _stderr, _status = execute %[git rev-parse HEAD]
  commit
end

def files_in(commit)
  files, _stderr, _status = execute %[git diff-tree --no-commit-id --name-only -r #{commit}]
  files.split("\n")
end

def compile_docs_folder
  execute "bundle exec middleman build --build-dir docs"
end

def passes_html_proofer?
  _stdout, _stderr, status = execute %[bundle exec htmlproofer ./docs --allow-hash-href --url-swap "https?\\:\\/\\/user-guide\\.cloud-platform\\.service\\.justice\\.gov\\.uk:" ./docs]
  status.success?
end

def commit_and_push_docs
  set_git_credentials

  execute %[git add docs -f]
  execute %[git commit -m 'Publish compiled site via github action']

  token = ENV.fetch("GITHUB_TOKEN")
  actor = ENV.fetch("GITHUB_ACTOR")
  repo = ENV.fetch("GITHUB_REPOSITORY")

  execute %[git push "#{remote_repo}" HEAD:master --force]
end

def set_git_credentials
	execute %[git config credential.helper cache]
	execute %[git config user.email "platforms+githubuser@digital.justice.gov.uk"]
	execute %[git config user.name "MoJ Cloud Platform Team Machine User"]
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
