# Release

LicensePatrol follows [Semantic Versioning](https://semver.org/). The version
lives in `lib/license_patrol/version.rb` (`LicensePatrol::VERSION`).

Don't change it by hand:
[release-please](https://github.com/googleapis/release-please) does, along
with `.release-please-manifest.json`, `Gemfile.lock` and the
[CHANGELOG](../CHANGELOG.md).

## Pull request titles

Pull requests are squash-merged, so each title becomes the commit on `master`
that release-please reads. Titles follow
[Conventional Commits](https://www.conventionalcommits.org/), and the
required `Conventional Commit title` check enforces it:

| Title                                                              | Release | In the changelog |
| ------------------------------------------------------------------ | ------- | ---------------- |
| `feat: …`                                                          | minor   | Added            |
| `fix: …`                                                           | patch   | Fixed            |
| `perf: …`                                                          | patch   | Changed          |
| `feat!: …`, or a `BREAKING CHANGE:` footer                         | major   | ⚠ BREAKING CHANGES |
| `docs:`, `refactor:`, `test:`, `build:`, `ci:`, `chore:`, `style:` | none    | no               |

The summary after the colon is the changelog line, so write it for the
people who use the gem.

## Releasing

1. Every push to `master` makes the `release-please` workflow open or update
   a release pull request. It bumps the version, pins it in `Gemfile.lock`,
   and adds the release's changelog entry.
2. Review the pull request and merge it when you want to release. To release
   a different version than the one it proposes, merge a commit to `master`
   with a `Release-As: 2.0.0` footer first.
3. Merging it tags the commit `vMAJOR.MINOR.PATCH` and creates the GitHub
   Release. The tag runs the `license_patrol` workflow, which publishes the
   gem to RubyGems.

If publishing fails, publish the gem by hand from the tag:

```sh
git checkout vMAJOR.MINOR.PATCH
bundle exec rake build release:rubygem_push
```

## Credentials

- The `release-please` workflow acts as a GitHub App, because pull requests
  and tags made with the workflow's own `GITHUB_TOKEN` don't start other
  workflows: the release pull request's required checks would never run, and
  the tag would never publish the gem. The app needs read and write access to
  contents, issues and pull requests on this repository.
- The `license_patrol` workflow publishes the gem with the `RUBYGEMS_API_KEY`
  secret.
