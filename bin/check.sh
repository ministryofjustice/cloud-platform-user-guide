#!/bin/sh

# This script is called by .github/workflows/check.yml after compiling the
# source documents into HTML files in the `docs` directory.
#
# It runs the link checker, so that PRs can be amended if there are any
# problems, without affecting the published site.

set -euo pipefail

# Check for internal and external broken links
bundle exec htmlproofer ./docs --http-status-ignore 0,429 --allow-hash-href --url-swap "https?\:\/\/user-guide\.cloud-platform\.service\.justice\.gov\.uk:" ./docs

