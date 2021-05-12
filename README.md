# whitehall

whitehall is a Ruby on Rails content management application for content published by government departments and agencies.

## Running the Application

Startup [using govuk-docker](https://github.com/alphagov/govuk-docker). 

There are two different views within this App, a *Publishing view* and a *Site view*. Once running, whitehall does not have an index, some suggested starting pages are below:

Publishing view:
- <http://whitehall-admin.dev.gov.uk/government/admin/news/new>

Site view:
- <http://whitehall-frontend.dev.gov.uk/government/get-involved>

Some pages will need data locally to display, whitehall uses mySQL. You'll need to gain relevant permissions to access data from AWS

- [Get setup with AWS access](https://docs.publishing.service.gov.uk/manual/get-started.html)

- Once completed [a guide to install local data on whitehall can be found here](https://github.com/alphagov/govuk-docker/blob/master/docs/how-tos.md#how-to-replicate-data-locally)

## Nomenclature

- *Govspeak* A variation of [Markdown](https://daringfireball.net/projects/markdown) used throughout whitehall as the general publishing format

## Technical documentation

whitehall is a Ruby on Rails app built on a MySQL database. It is deployed in two modes: 'admin' for publishers to create and manage content and 'frontend' for rendering some content under https://www.gov.uk/government and https://www.gov.uk/world. whitehall also sends most content to the publishing-api and rummager.

## Dependencies

### Local development dependencies

This application uses Ruby dependencies installed via [Bundler][] and [npm
dependencies][npm] installed via [Yarn][].

These can be installed with:

```
bundle install
yarn install
```

[Bundler]: https://classic.yarnpkg.com/en/docs/install/
[npm]: https://www.npmjs.com/
[Yarn]: https://classic.yarnpkg.com/en/docs/install/

## Troubleshooting

Should you run into this error below:
```
Mysql2::Error: Access denied for user 'whitehall'@'localhost' (using password: YES)
```

Login, create user, give access & quit

```
mysql -u root -p
CREATE USER whitehall@localhost IDENTIFIED BY 'whitehall';
grant all privileges on *.* to whitehall@localhost with grant option;
\q
```

### Dependent GOV.UK apps

- [alphagov/asset-manager](http://github.com/alphagov/asset-manager): provides uploading for static files
- [alphagov/publishing-api](http://github.com/alphagov/publishing-api): documents are sent here, persisted and then requested
- [alphagov/search-api](http://github.com/alphagov/search-api): allows documents to be indexed for searching in both finders and site search
- [alphagov/link-checker-api](https://github.com/alphagov/link-checker-api): checks all the links in an edition on request from the edition show page.

## Other documentation

- [Contributing guide](CONTRIBUTING.md)
- [CSS](docs/css.md)
- [Edition workflow](docs/edition_workflow.md)
- [How to publish a finder in whitehall](docs/finders.md)
- [Internationalisation](docs/internationalisation_guide.md)
- [JavaScript](docs/javascript.md)
- [Search setup guide](docs/search_setup_guide.md)
- [Testing guide](docs/testing_guide.md)
- [Timestamps](docs/timestamps.md)

## Generating technical documentation

We use [YARD](https://github.com/lsegal/yard) for the technical documentation. You can generate a local copy with:

    yard server --reload

You can also read the docs on [rdoc.info](http://rdoc.info/github/alphagov/whitehall/frames).

## Licence

[MIT License](LICENCE)
