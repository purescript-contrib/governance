# PureScript Contributors Library Guidelines

This short handbook outlines the mimimum expectations for libraries in the PureScript Contributors organization. Libraries must meet these requirements to be eligible to be included in the organization, and libraries that don't meet these requirements for an extended period may be transferred out of the organization or archived. This helps ensure we can maintain a high level of quality across the organization and remain accessible and welcoming to new contributors.

## Expectations for Libraries

Libraries in the Contributors organization are expected to:

1. Have at least one (and preferably two) assigned maintainers, as indicated by badges in the project README.
2. Use the standard repository configuration, including pull request and issue templates, a `stale.yml` file for stale issues, and the other files included in the [templates](./templates).
3. Have an adequate test suite which is exercised by continuous integration, so that pull requests that pass CI can be merged with confidence.
4. Have adequate documentation in the form of documentation comments (for module documentation to publish to Pursuit), written documentation in a `./docs` directory, and an up-to-date changelog.
5. Have a README which includes the standard badges, a short motivation for the library, installation instructions, a quick start showing a minimal library example, links to relevant documentation, and a link to the contributing guide.

In addition, libraries which use the FFI are expected to include the standard `eslint` configuration and ensure that pull requests pass linting on the FFI files before they are merged.

Libraries in this organization should be useful, tested, and well-documented. These are great things to shoot for in any library, but Contributors libraries are held to a particular standard to encourage new contributions and to serve as an example for other libraries in the community.

## Expectations for Maintainers

Maintainers are expected to ensure that libraries they maintain meet the minimum library requirements. The [templates](./templates) can help you make sure the library you maintain has all the necessary scaffolding for these requirements.

In addition, maintainers are expected to:

1. Interact with users of the library promptly and respectfully. Maintainers should respond to issues and pull requests quickly -- even if that response is a simple request for more information or to add a 'help wanted' label. Contributors should feel respected, heard, and motivated to contribute more.
2. Merge contributions of that are of sufficient quality. Pull requests should pass CI and should include adequate tests, documentation, and be reflected in the changelog. Pull requests that meet these criteria and are beneficial to the library should be merged.
3. Curate the issue tracker and repository contents. Maintainers should apply labels to issues, close old issues, and ensure that documentation adequately helps users get started with new contributions. If you notice a way to make the repository more accessible to newcomers, open and label an issue that describes how the project could be improved!

Maintainers aren't necessarily expected to actively contribute code to the projects they maintain. They _are_ expected to keep the repository up to date, to respond quickly to issues and pull requests, and to curate issues in the issue tracker.

### Standard Labels

Labels are a big part of curating the issue tracker in a Contributors library. We use several standard labels for issues of various types:

- `bug` is used for issues that point out a legitimate bug in the library that ought to be fixed
- `document me` is used for issues that indicate documentation needs to be updated, or for issues with great content that ought to be added to the documentation.
- `enhancement` is used for issues that represent an addition to the library
- `good first issue` is used to label tasks that are good for beginners to take on. This is one of the best ways to encourage new contributions to the PureScript ecosystem!
- `help wanted` is used as a call to action to indicate that the maintainers would like a PR that solves this issue.

## Resources for Maintainers

It can be daunting becoming a maintainer for the first time! Fortunately, many of the maintainers in the Contributors organization are (or were recently) in the same situation. Feel free to participate in the internal project management boards to get help with various maintenance tasks.

You can also ping other maintainers on the PureScript Discourse or the functional programming Slack channel.

## FAQ

### Can my library become part of the Contributors organization?

Yes! We regularly accept new libraries to become a part of `purescript-contrib`. Libraries in the organization benefit from shared maintenance and greater visibility to new contributors. However, so that we don't become overwhelmed with projects to maintain, we do have some ground rules for new libraries.

1. Your library must have at least one person committed to maintaining it. Others will help once it's in the organization, but we don't have the bandwidth to totally take over maintenance of new projects.
2. Your library should meet the minimum requirements as outlined for all Contributors libraries in this post. If you need help updating your library to meet these requirements, we can help you.
