# Development Practices

### Coding Style

We loosely (but not religiously) follow the [bbatsov/ruby-style-guide](https://github.com/bbatsov/ruby-style-guide).

### Change Log

We use an automatic way of generating [CHANGELOG.md](../CHANGELOG.md) using [the github-changelog-generator gem](https://github.com/github-changelog-generator/github-changelog-generator). To regenerate the change log:

1. [Generate a personal access token on GitHub](https://github.com/settings/tokens). You'll need this because the changelog generator makes so many requests to the GitHub API.
2. `gem install github_changelog_generator`
3. `github_changelog_generator --token XXXXXXXX` where XXXXXXXX is the GitHub personal access token.

The change log can be updated with each pull request to master. But it's only actually important to do it with production releases, each of which gets a new version number and git tag.

### Version number

We keep track of version numbers in two places:

- Committed to code in `config/initializers/version.rb`.
- Tags on the git repository, listed at https://github.com/transitland/transitland-datastore/tags
