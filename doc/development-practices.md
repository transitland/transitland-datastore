# Development Practices

### Coding Style

We loosely (but not religiously) follow the [bbatsov/ruby-style-guide](https://github.com/bbatsov/ruby-style-guide).

**style checking on pull requests** When you open a pull request against the Datastore repository on GitHub, [HoundCI](https://houndci.com/) will check your code edits against the style guide. It will automatically add comments to the pull request with suggestions for improvements. Take these as advice, not orders.

**style checking locally** If you want to check your style before you push to GitHub and open a pull request, you can use [the RuboCop gem](https://github.com/bbatsov/rubocop) locally. (This is what HoundCI is running on a server.) We've tweaked the RuboCop config slightly in [./.rubocop.yml](../rubocop.yml). To run Rubocop locally: `bundle exec rubocop`

**style checking in editor** If you're using Atom for your text editing, [the linter-rubocop package](https://atom.io/packages/linter-rubocop) will check style as you type.

### Change Log

We're testing out an automatic way of generating [CHANGELOG.md](../CHANGELOG.md) using [the github-changelog-generator gem](https://skywinder.github.io/github-changelog-generator/). To regenerate the change log:

1. [Generate a personal access token on GitHub](https://github.com/settings/tokens). You'll need this because the changelog generator makes so many requests to the GitHub API.
2. `bundle exec github_changelog_generator -t XXXXXXXX` where XXXXXXXX is the GitHub personal access token.

The change log can be updated with each pull request to master. But it's only actually important to do it with production releases, each of which gets a new version number and git tag.
