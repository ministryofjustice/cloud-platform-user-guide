# Cloud Platform user guide

This repository holds the website and documentation for the [Cloud Platform
user guide](https://user-guide.cloud-platform.service.justice.gov.uk/#cloud-platform-user-guide).

This repository utilises the Ministry of Justice's [template-documentation-site](https://github.com/ministryofjustice/template-documentation-site).

>Want to give feedback on the documentation? [Open an issue on this repository](https://github.com/ministryofjustice/cloud-platform-user-guide/issues).

## Running locally

You can run this website locally by running:

```sh
make preview
```

You can then browse to https://localhost:4567 to view the website.

## Updating documentation

You can update the documentation by editing any of the `*.html.md.erb` files in
the [source](source) directory.

The syntax used in `*.html.md.erb` is Markdown, though it also supports some
GOV.UK Design System specifics, as listed on [Tech Docs Template - Write your
content](https://tdt-documentation.london.cloudapps.digital/write_docs/content/).

## Publishing changes

Any changes that are merged into the `main` branch will be published
automatically through the [`publish.yml` GitHub action](.github/workflows/publish.yml).

This website is hosted on [GitHub Pages](https://pages.github.com/).

## Configuring the website

### Global configuration

The [GOV.UK Tech Docs Template global configuration options](https://tdt-documentation.london.cloudapps.digital/configure_project/global_configuration/)
can be used in this repository to configure the Cloud Platform user guide.

### Structuring documentation and page configuration

The [GOV.UK Tech Docs Template "Configure your documentation project"](https://tdt-documentation.london.cloudapps.digital/configure_project/)
offers a range of guidance regarding configuration options to help structure
documentation and configure pages separately.
