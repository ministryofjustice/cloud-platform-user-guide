# Cloud platform user guide

The documentation for users of the Ministry of Justice cloud platform. It explains how to deploy and run applications on the Cloud Platform.

This repo is an MOJ documentation site that uses the [GDS Tech Docs Template][tech-docs], and the docs get hosted using [GitHub Pages][gh-pages].

(This repo pre-dates [template-documentation-site](https://github.com/ministryofjustice/template-documentation-site). The latter was abstracted out of this repo and improved. TODO: We should make this repo use that template, with its shared Docker image and no second repo.)

## Editing

The guide is changed by editing `*.html.md.erb` files, found in the [source](source) folder.

The syntax is Markdown. For guidance see: [Tech Docs Template - Write your content](https://tdt-documentation.london.cloudapps.digital/write_docs/content/). [kramdown](https://kramdown.gettalong.org/syntax.html) is what compiles the Markdown. 

While editing the files locally, you can [preview the site](#previewing).

Every change should be reviewed in a pull request, no matter how
minor, and we've enabled [branch protection][] to enforce this.

Merging the changes to the `main` branch are automatically [published](#publishing)

## Previewing

Preview changes locally by running this command:

```bash
make preview
```

This will run a preview web server on http://localhost:4567

This is only accessible on your computer, and won't be accessible
to anyone else.

## Publishing

Any changes you push/merge into the `main` branch should be published
to GitHub Pages site automatically by a GitHub Action: [publish.yml](.github/workflows/publish.yml).

The markdown files in the `source` directory are compiled to HTML, and the
resulting files are pushed to a [second repository] from where they are
published via Github Pages.

The URL for the published site is: <https://user-guide.cloud-platform.service.justice.gov.uk/>

> The publishing process creates files in `/docs` and pushes them to the
> `gh-pages` branch to publish them. You should not edit any files in that
> folder, because your changes will be lost the next time the site is
> published.

## Template configuration

The template can be configured in [config/tech-docs.yml](config/tech-docs.yml)

Key config:

* `host:` - this should be the URL of your published GitHub Pages site, e.g:

   ```
   https://ministryofjustice.github.io/modernisation-platform
   ```

   > Do not include a `/` at the end of this URL

* `service_link:` - This should be the docpath to your site. This is usually
  `/[repo name]`, so if your repository is `ministryofjustice/awesome-docs`
  `service_link` will be `/awesome-docs`

Further configuration options are described here: [Tech Docs Template docs - Global Configuration](https://tdt-documentation.london.cloudapps.digital/configure_project/global_configuration/)

## Link checking

The publishing process automatically checks both internal and external links in
the site. If you want to do the same check locally, run:

```
make check
```

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

## Updating the docker image

If you need to make any changes to the docker image (i.e. if you make any
changes to the Dockerfile or Gemfile), please use the GitHub web interface to
create a new [release]. A github action will build the docker image and push
it to docker hub, tagged with the release number.

After changing the tag, you need to update the reference to the image in
`.github/workflows/publish.yml` and the `makefile`.

[branch protection]: https://help.github.com/articles/about-protected-branches/
[tech-docs-multipage]: https://tdt-documentation.london.cloudapps.digital/multipage.html#repo-folder-structure
[release]: https://github.com/ministryofjustice/cloud-platform-user-guide/releases
[Github Action]: https://github.com/features/actions
[tech-docs]: https://tdt-documentation.london.cloudapps.digital/
[gh-pages]: https://pages.github.com/
[second repository]: https://github.com/ministryofjustice/cloud-platform-user-guide-publish
