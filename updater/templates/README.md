# PureScript Contributors Library Templates

This directory contains templates for a standard set of files that each project in the Contributors organization has. It also contains scripts that can be used to make sure a particular library is up-to-date.

> Note: In the future we'd like to have a GitHub Action that runs in each Contributor library weekly to sync it with changes to the base templates. Until then libraries are maintained manually.

## Templates

The templates include default content that each Contributor library is expected to have. Templates are provided in layers, where later layers override earlier ones:

### Layer 1: Base

`base` includes content and configuration each Contributor library is expected to have.

- An informative README with badges for the build status, latest release, latest Pursuit documentation, and current maintainers.
- A documentation directory containing library documentation and a CHANGELOG (used to ensure releases are informative)
- A `.github` directory containing issue and pull request templates, a contributors file, a `stale.yml` file to automate management for stale issues, and continuous integration via GitHub Actions and `setup-purescript`
- Various dotfiles, including standard `.gitignore` and `.editorconfig` files.

### Layer 2: FFI

Some libraries in the Contributors organization rely on NPM libraries and/or the foreign function interface (FFI). Those libraries have additional templates, including:

- An `.eslintrc.json` configuration file. Any library using JavaScript is expected to pass `eslint` via this configuration.
- A minimal `package.json` file listing any NPM dependencies (including `eslint`) and which includes a `build` script (which calls `eslint` before building the source).
- An updated `ci.yml` file that installs and caches NPM dependencies in addition to the ordinary PureScript toolchain.

All of these files can be set up via the template scripts and libraries are allowed to depart from the defaults if necessary.

## Scripts

There are some scripts available to help automate the process of updating a library according to these standards. These scripts:

1. Copy the templates into their proper locations in the repository. If they conflict with existing files, those files are moved to `<filename>.old.<extension>` so that you can copy over any relevant content later.
2. Fill in any variables in the templates according to the arguments you provide (for example, the repository name, package name, and so on).
3. Allow you to clean up all `<filename>.old.<extension>` files when you have copied over any relevant content, leaving the repository in a clean state.

In typical usage, you will:

1. Run the `sync-base.sh` script to set up the repository defaults, providing the information the script requests from you to fill in template variables
2. Run the `sync-with-ffi.sh` script if your project uses the FFI or has NPM dependencies
3. Perform any manual reconciliation you need to do
4. Run the `sync-labels.sh` script to standardize the labels used in the repository, if it isn't already using the standard Contributors labels.
5. Run the `sync-cleanup.sh` script to remove leftover files.
