# Cloud platform user guide

The documentation for users of the Ministry of Justice cloud platform.
It explains how to deploy and run applications on the cloud platform.

It's built using the [GDS Tech Docs Template][tech-docs], and hosted
using [GitHub Pages][gh-pages].

[tech-docs]: https://tdt-documentation.london.cloudapps.digital/
[gh-pages]: https://pages.github.com/

## Getting started

To preview the site locally, we need to use the terminal.

Install Ruby and [Bundler][bundler], preferably with a [Ruby version
manager][rvm].

[rvm]: https://www.ruby-lang.org/en/documentation/installation/#managers
[bundler]: http://bundler.io/

Once you have Ruby and Bundler set up, you can install this project's
dependencies by running the following in this directory:

```bash
bundle install
```

## Making changes

To make changes, edit the appropriate Markdown and ERB files in the
`source` directory.

GDS Tech Docs (and therefore this site) uses [kramdown][] for its
Markdown processing.

[kramdown]: https://kramdown.gettalong.org/syntax.html

Note: Do not edit the files in the `docs` directory. This is the
'compiled' version of the site, and any changes made in this
directory will be overwritten during the build step.

## Composing & Ordering Pages

Every page of the site needs a `source/[page name].html.md.erb`
file.

This file lists the partials which comprise the page, in the
order in which they should appear. By convention, all such
partials are in the `source/documentation` directory.

These `source/[page name].html.md.erb` files have a 'weight' attribute
which determines the order in which they will appear. Higher weights
are further down in the list.

For more information, see the [Tech Docs Template documentation][tech-docs-multipage]
for a basic multipage site.

## Previewing

We can preview our changes locally by running this command:

```bash
make server
```

This will create a local web server, probably at http://127.0.0.1:4567
This is only accessible on our own computer, and won't be accessible
to anyone else. It's also set up to automatically update when we
make changes to the source files.

## Publishing changes

When you have made your changes, prepare them for publishing by
running:

```bash
make build
```

Then add, commit and push your changes (including the `docs`
directory).

Make your changes in a branch, and issue a pull request
when you want them to be reviewed and published.

We recommend making two separate commits for your changes - the first
for your changes to the `source` directory, and then a separate commit
adding the `docs` directory, after you run `make build`. This makes it
easier for whoever is reviewing your commit, because they can focus on
your 'source' commit (on the assumption that your 'docs' changes are
simply a result of running the build process).

Because we're using GitHub Pages, any changes merged into the `master`
branch will be published automatically. Every change should be reviewed
in a pull request, no matter how minor, and we've enabled [branch
protection][] to enforce this.

[branch protection]: https://help.github.com/articles/about-protected-branches/
[tech-docs-multipage]: https://tdt-documentation.london.cloudapps.digital/multipage.html#repo-folder-structure

