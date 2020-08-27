#!/bin/sh

# This script is called in .github/workflows/*.yml to compile
# source documents into HTML files in the `docs` directory.

set -euo pipefail

# Check for internal and external broken links The 'grep -v' suppresses
# annoying warnings due to some of the gem dependencies using functions that
# have been deprecated in current versions of ruby.
bundle exec middleman build 2>&1 \
  --verbose \
  --build-dir docs \
  | grep -v "warning: URI.*escape is obsolete"

