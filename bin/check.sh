#!/bin/sh

# This script is called by .github/workflows/check.yml after compiling the
# source documents into HTML files in the `docs` directory.
#
# It runs the link checker, so that PRs can be amended if there are any
# problems, without affecting the published site.

set -euo pipefail

# Check for internal and external broken links The 'grep -v' suppresses
# annoying warnings due to some of the gem dependencies using functions that
# have been deprecated in current versions of ruby.
bundle exec htmlproofer 2>&1 \
  --http-status-ignore 0,429 \
  --allow-hash-href \
  --url-swap "https?\:\/\/user-guide\.cloud-platform\.service\.justice\.gov\.uk:" \
  ./docs | grep -v "warning: URI.unescape is obsolete"


