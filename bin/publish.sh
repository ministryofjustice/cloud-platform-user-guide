#!/bin/sh

# PUBLISHING_GIT_TOKEN is a secret in the source repository. It should contain a github personal access token
# with `public_repo` scope, and MoJ SSO enabled.
REPOSITORY_PATH="https://${PUBLISHING_GIT_TOKEN}@github.com/$GITHUB_PAGES_REPO_OWNER/$GITHUB_PAGES_REPO_NAME.git"

echo "Checkout the publish repo"
git clone $REPOSITORY_PATH

echo "Add compiled files"
cp -R docs/* $GITHUB_PAGES_REPO_NAME

cd $GITHUB_PAGES_REPO_NAME

echo "Push the changes"
git config --global user.email "${GITHUB_PAGES_REPO_AUTHOR_EMAIL}"
git config --global user.name "${GITHUB_PAGES_REPO_AUTHOR}"
git add .
git commit -m "Published at $(date)"
git push

echo "Publishing complete"
