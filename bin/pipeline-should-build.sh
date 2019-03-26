#!/bin/bash

# Our build pipeline should NOT build the project
# if the only changes are to files in the 'docs'
# folder (because such changes are only made by
# the build pipeline, so we would go into an
# endless loop.
#
# However, empty commits probably come from
# merging PRs, and so those SHOULD be built.

main() {
  local readonly commit=$(git rev-parse HEAD)
  local readonly files=$(files_in ${commit})

  if [ -z "${files// }" ]; then
    echo "Commit changed no files (merge commit?). Proceeding with build."
    return
  else
    # Some files changed by commit. We want to fail out if only docs files were changed
    for f in ${files}; do
      if [[ $f =~ ^docs ]]; then
        true
      else
        echo "Commit changed a file which is not in the docs directory. Proceeding with build."
        return
      fi
    done

    echo "Commit only changed files in the docs directory. Build should not proceed."
    exit 1
  fi
}

files_in() {
  local readonly commit=$1
  git diff-tree --no-commit-id --name-only -r ${commit}
}

main
