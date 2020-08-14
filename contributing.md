# Contributing

Thank you for your interest in contributing to a PureScript Contributors library! This file is a short, sweet introduction to help you get started contributing to one of our projects. We ask that all new contributors read it before their first contribution to make sure we can get your work merged.

## Getting Started

### Do I belong here?

Everyone is welcome! People of all experience levels can join, begin contributing, and feel comfortable and safe making mistakes. People of all backgrounds belong here so long as they treat others with dignity and respect and do not harass or belittel others.

### What is the correct way to ask a question?

Feel free to ask questions by opening an issue on the relevant library. Maintainers are also active on:

- The [PureScript Discourse](https://discourse.purescript.org) (the most popular option and best for detailed questions)
- The [Functional Programming Slack](https://functionalprogramming.slack.com) ([link to join](https://fpchat-invite.herokuapp.com)!) in the `#purescript` and `#purescript-beginners` channels (best for quick, informal questions)

### I'd like to help, how do I pick something to work on?

Any open issue that is not yet assigned to someone is good to work on! If it's your first time contributing it's probably best to pick an issue marked `good first issue`. In general, Contributors libraries follow these conventions:

1. Issues marked `good first issue` are good for beginners and/or new contributors to the library.
2. Issues marked `help wanted` signal that anyone can take the issue and it's a desired addition to the library.
3. Issues marked `document me` are requests for documentation and are often a great first issue to take on.

The easiest way you can help is by contributing documentation, whether via looking for issues marked `document me` or by adding new documentation of your own. If you'd like to contribute documentation we suggest [reading about the four kinds of documentation](https://documentation.divio.com).

### How big should my contribution be?

Your contribution can be as small as copypasting instructions from an issue into the project documentation! Everything is welcome, including very small changes and quality of life improvements.

If you have larger contributions to make, those are also welcome. However, if you would like to contribute a particularly large or a breaking change, you may want to open an issue proposing the change before you implement it. That helps us ensure your time is not wasted.

## Contributing Code

### Tooling

All `purescript-contrib` libraries use recent versions of [PureScript](https://github.com/purescript/purescript), [Spago](https://github.com/purescript/spago), and [psa](https://github.com/natefaubion/purescript-psa). A library without scripts in a `package.json` file will use the standard `spago build` and `spago test` commands.

Any additional development dependencies can be installed via NPM and are listed in the `package.json` file for the repository.

### Proposing changes

If you would like to contribute code, tests, or documentation, please feel free to open a pull request for small changes. For large changes we recommend you first open an issue to propose your change and ensure that the maintainers are on board before you spend time implementing the change. We want to respect your time and effort. We can also assign the issue to you if you would like to make sure you're the one to work on it.

### Merging changes

All changes must happen through a pull request. Everyone with commit access can merge changes, though by convention we like to wait for two approvals for non-trivial changes. All pull requests must pass continuous integration; if the change adds new code we may also ask that you add a test.

## How do I get the "commit bit"?

If you'd like to take part in maintaining a package, just ask! We hand out the commit bit to folks who display sustained interest in the project. You can ask directly (for example: on Slack or via a DM on Discourse) or by opening an issue -- whichever you prefer!
