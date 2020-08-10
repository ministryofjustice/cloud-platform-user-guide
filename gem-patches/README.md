# Patches for gov.uk tech-docs gems

These files represent the patches described in this issue:
https://github.com/alphagov/tech-docs-gem/issues/191

They enable using (a patched version of) the gov.uk tech-docs gem to publish a
documentation site using github pages without requiring the site to be
published at the root docpath ("/") of a dedicated domain.

i.e. this enables publishing a site at:

```
https://username.github.io/my-repo
```

This is the default github pages URL for the repository "my-repo" belonging to
the github user/organisation "username".

As opposed to:

```
https://my.custom.domain/
```

Without these patches, the search function of the site will not work correctly.

The patch files in this directory are used in the Dockerfile to build the
docker image which is used in the publishing process.

This is a nasty hack, but the alternative is to maintain forks of two gems,
`govuk_tech_docs` and `middleman-search-gds`, so this seems a pragmatic
solution until the issue above is resolved in the upstream gems.
