# Cloud platform user guide

The documentation for users of the Ministry of Justice cloud platform.
It explains how to deploy and run applications on the cloud platform.

It's built using the [GDS Tech Docs Template][tech-docs], and hosted
using [GitHub Pages][gh-pages].

[tech-docs]: https://tdt-documentation.london.cloudapps.digital/
[gh-pages]: https://pages.github.com/

## Pre-requisites

You will need [Docker][] on your development machine.

[Docker]: https://www.docker.com/

## Previewing

Preview changes locally by running this command:

```bash
make server
```

This will build the docker image, if required, so the first time you
run it, it will take some time. Subsequent invocations should be much
faster.

This will run a preview web server on http://127.0.0.1:4567

This is only accessible on your computer, and won't be accessible
to anyone else. It's also set up to automatically update when we
make changes to the source files.

## Making changes

To make changes, edit the appropriate Markdown and ERB files in the
`source` directory.

GDS Tech Docs (and therefore this site) uses [kramdown][] for its
Markdown processing.

[kramdown]: https://kramdown.gettalong.org/syntax.html

**Note: Do not edit the files in the `docs` directory.** This is the
'compiled' version of the site, and any changes made in this
directory will be overwritten during the build step.

## Composing & Ordering Pages

Every page of the site needs a `source/[page name].html.md.erb`
file.

This file lists the partials which comprise the page, in the
order in which they should appear. By convention, all such
partials are in the `source/documentation` directory.

## Publishing changes

When you have made your changes, prepare them for publishing by
running:

```bash
make build
```

Then add, commit and push your changes (including the `docs`
directory).

Make sure to make changes in a branch, and issue a pull request
when you want them to be reviewed and published.

Because we're using GitHub Pages, any changes merged into the `master`
branch will be published automatically. Every change should be reviewed
in a pull request, no matter how minor, and we've enabled [branch
protection][] to enforce this.

[branch protection]: https://help.github.com/articles/about-protected-branches/

