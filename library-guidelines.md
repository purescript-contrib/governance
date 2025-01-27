# PureScript Contributors Library Guidelines

This short handbook outlines the mimimum expectations for libraries in the PureScript Contributors organization. Libraries must meet these requirements to be eligible to be included in the organization, and libraries that don't meet these requirements for an extended period may be transferred out of the organization or archived. This helps ensure we can maintain a high level of quality across the organization and remain accessible and welcoming to new contributors.

## Expectations for Libraries

Libraries in the Contributors organization are expected to:

1. Have at least one (and preferably more) assigned maintainers, as indicated by badges in the project README.
1. Depend only on PureScript [core packages](https://github.com/orgs/purescript/repositories) or other **contrib** packages.
1. Have adequate documentation in the form of module documentation published to Pursuit, a README containing a library summary, installation instructions, and more, and a `docs` directory containing at least a short tutorial (see [the documentation section below](#documentation)).
1. Have a CHANGELOG.md in the root directory.
1. Have an adequate test suite which is exercised by continuous integration (see [the tests section below](#tests))
1. Use the standard Contributors repository structure, which can be generated with the [contrib-updater](./updater) tool (see [the repository structure section below](#repository-structure)).
1. Use a default branch of `main` for the repository.
2. Package name registered with the [registry](https://github.com/purescript/registry). No `bower.json`.

Libraries in this organization should be useful, tested, and well-documented. These are great things to shoot for in any library, but Contributors libraries are held to a particular standard to encourage new contributions and to serve as an example for other libraries in the community.

### Documentation

Contributors libraries are expected to have adequate documentation. To accomplish that goal, we expect each repository to have:

1. A repository README containing badges for the build status, latest release, and maintainers, a short summary of the library's purpose, installation instructions, a quick start with a minimal usage example, and links to the documentation and contributing guide
1. Expanded documentation like how-tos, tutorials, and concept overviews in the docs directory (at minimum a short tutorial that expands on the quick start).
1. Documentation comments for the majority and preferably all publicly-exported types and functions in the library modules, which should should be uploaded to Pursuit.

If you are migrating a library to the Contributors organization (or creating an new one), the [contrib-updater](./updater) tool can generate templates on your behalf to help you get started with documentation.

### Tests

Contributors libraries are expected to have tests which exercise tricky parts of the code and serve as usage examples. These tests should help maintainers merge pull requests which pass CI with confidence. We expect each repository to have:

1. One or more tests in a `test` directory
1. Continuous integration via GitHub Actions which exercises this test on pull requests and the main branch

### Repository Structure

Contributors libraries share a standard structure and set of configuration files which helps ensure that contributors know where to find things and how to get set up when they use a new library. Each library includes some standard files, such as:

- A `.gitignore` file which ignores common dotfiles and compiler artifacts
- An `.editorconfig` file which editors can use to set spacing, trailing newlines, and other configuration

Some of these files can be customized per-repository, but most of them are standardized across the organization (for example, the `.editorconfig` file). In addition, libraries which use the FFI are expected to include additional files such as:

- The standard `.eslintrc.json` configuration for `eslint`, which should be run on pull requests
- A `package.json` file which installs `eslint` and can be used for scripts

Each library also contains some standard directories, including:

- A `docs` directory containing expanded documentation for the library such as tutorials and walkthroughs.
- A `.github` directory containing issue templates, pull request templates, contributing guide, and workflows for tests in continuous integration and automatically labeling stale issues and pull requests.

#### Standard Labels

Labels are a big part of curating the issue tracker in a Contributors library. Labels are regularly and automatically synced via the [contrib-updater](./updater) CLI tool, which will set labels, colors, and descriptions across repositories. We use several standard labels for issues of various types. They can be found on [this repository's issue labels page](https://github.com/purescript-contrib/governance/issues/labels). For instructions on how to update labels across all Contributor libraries see the [Sync Labels documentation](./updater/docs/02-Sync-Labels.md).

## Expectations for Maintainers

Maintainers are expected to ensure that libraries they maintain meet the minimum library requirements. The [contrib-updater CLI tool](./updater) can help you make sure the library you maintain has all the necessary scaffolding for these requirements.

In addition, maintainers are expected to:

1. Interact with users of the library promptly and respectfully. Maintainers should respond to issues and pull requests quickly -- even if that response is a simple request for more information or to add a 'help wanted' label. Contributors should feel respected, heard, and motivated to contribute more.
1. Merge contributions of that are of sufficient quality. Pull requests should pass CI and should include adequate tests, documentation, and be reflected in the changelog. Pull requests that meet these criteria and are beneficial to the library should be merged.
1. Curate the issue tracker and repository contents. Maintainers should apply labels to issues, close old issues, and ensure that documentation adequately helps users get started with new contributions. If you notice a way to make the repository more accessible to newcomers, open and label an issue that describes how the project could be improved!

Maintainers aren't necessarily expected to actively contribute code to the projects they maintain. They _are_ expected to keep the repository up to date, to respond quickly to issues and pull requests, and to curate issues in the issue tracker.

## Resources for Maintainers

It can be daunting becoming a maintainer for the first time! Fortunately, many of the maintainers in the Contributors organization are (or were recently) in the same situation. Feel free to participate in the internal project management boards to get help with various maintenance tasks.

You can also ping other maintainers on the PureScript Discourse or the functional programming Slack channel.

## FAQ

### Can my library become part of the Contributors organization?

Yes! We regularly accept new libraries to become a part of `purescript-contrib`. Libraries in the organization benefit from shared maintenance and greater visibility to new contributors. However, so that we don't become overwhelmed with projects to maintain, we do have some ground rules for new libraries.

1. Your library must have at least one person committed to maintaining it. Others will help once it's in the organization, but we don't have the bandwidth to totally take over maintenance of new projects.
1. Your library should meet the minimum requirements as outlined for all Contributors libraries in this post. If you need help updating your library to meet these requirements, we can help you.
