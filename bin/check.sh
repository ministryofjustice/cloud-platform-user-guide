#!/bin/sh

# This script is called by .github/workflows/check.yml after compiling the
# source documents into HTML files in the `docs` directory.
#
# It runs the link checker, so that PRs can be amended if there are any
# problems, without affecting the published site.

set -euo pipefail

# There are a couple of cases where links will appear to be broken:
#
# 1. There is a `View source` link on every page, which will be broken for any
#    files that have not yet been merged into the default branch of the
#    documentation repo.
# 2. If the documentation includes a link to any private repositories, those
#    links will seem to be broken, from the link-checker's POV.
#
# To avoid these problems, we tell the link-checker to ignore any links that
# point to MoJ GitHub entities.
MOJ_GITHUB=/https...github.com.ministryofjustice.*/

CHROME_USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36"

# Check for internal and external broken links The 'grep -v' suppresses
# annoying warnings due to some of the gem dependencies using functions that
# have been deprecated in current versions of ruby.
bundle exec htmlproofer 2>&1 \
  --http-status-ignore 0,429,403,400 \
  --allow-hash-href \
  --url-ignore "${MOJ_GITHUB}" \
  --url-swap "https?\:\/\/user-guide\.cloud-platform\.service\.justice\.gov\.uk:" \
  --typhoeus-config "{\"headers\":{\"User-Agent\":\"${CHROME_USER_AGENT}\"}}" \
  ./docs | grep -v "warning: URI.*escape is obsolete"


