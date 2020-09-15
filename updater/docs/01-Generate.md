# Generate Template Files

The `generate` command in the `contrib-updater` CLI generates a standard set of files that each project in the Contributors organization has. The templates for these files are stored in the `templates` directory.

The `templates` directory contains templates for a standard set of files that each project in the Contributors organization has. Feel free to use these templates in non-Contributor libraries as well!

## Usage

The `generate` command will create a standard set of files in the current repository based on the set of library templates in the `templates` directory. It will fill in a set of available variables with the contents you provide and will make backups of any existing files that conflict.

This command is used to help manage migrating new libraries into the Contributors organization or to update existing libraries when our standard structure changes.

Example CLI usage with defaults used (this is the typical case):

```sh
contrib-updater generate --maintainer garyb --maintainer thomashoneyman
```

Example CLI usage with all options specified:

```sh
contrib-updater generate \
  # Indicates that JS-related templates should be
  # generated as well as the standard templates.
  --uses-js \
  --owner purescript-contrib \
  --main-branch main \
  --display-name '`argonaut-codecs`' \
  --display-title 'Argonaut Codecs' \
  --maintainer thomashoneyman
```

In typical usage you will:

1. Clone the target repository and change into it
2. Run `contrib-updater generate` and provide values for the relevant variables; if the library uses any JS files, include the `--uses-js` flag.
3. Reconcile the new content with any information that should be preserved from the existing repository (any conflicting files will have been added to the backups directory). For example, you may want to copy sections of the old README into the new one or into the documentation where appropriate.
4. Delete the backups directory and any other files which are no longer necessary in the target repository.
5. Open a PR with your changes!

## Variables

Templates can use the following variables (in code, see the `Updater.Variable` module), provided via the `contrib-updater` tool:

```purs
type Variables =
  { owner :: String
  , mainBranch :: String
  , packageName :: String
  , displayName :: String
  , displayTitle :: String
  , maintainer :: NonEmptyList String
  }
```

- `owner` refers to the owner of the repository being updated. Defaults in the CLI to `"purescript-contrib"`.
- `mainBranch` refers to the primary branch used in the repository. Defaults in the CLI to `"main"`, but some libraries may need to use `"master"` instead.
- `packageName` refers to the package name as represented in the PureScript registry and Spago installation instructions. This is pulled automatically from the `spago.dhall` file.
- `displayName` refers to the way you'd like to render the package name in markdown files. Defaults in the CLI to the name of the package in backticks, ie. `argonaut-codecs`, but it's also common to provide a string (for example, Argonaut Codecs) instead.
- `displayTitle` refers to the way you'd like to render the package name in markdown titles. Defaults in the CLI to the name of the package in title case.
- `maintainer` refers to the assigned maintainer(s) for the library (ex: `"thomashoneyman"`). This is required in the CLI.

Any of these variables can be used in template files via `{{variableName}}` syntax. When templates are generated for a particular repository these variables will be replaced with the values you provided.

## Provided Templates

The templates include default content that each Contributor library is expected to have. Templates are provided in layers, where later layers override earlier ones:

### Layer 1: Base

`base` includes content and configuration each Contributor library is expected to have.

- An informative README with badges for the build status, latest release, latest Pursuit documentation, and current maintainer(s).
- CHANGELOG and CONTRIBUTING files in the repository root.
- A documentation directory containing extra library documentation like tutorials.
- A `.github` directory containing issue and pull request templates and continuous integration via GitHub Actions and `setup-purescript`.
- Various dotfiles, including standard `.gitignore` and `.editorconfig` files.

### Layer 2: FFI

Some libraries in the Contributors organization rely on NPM libraries and/or the foreign function interface (FFI). Those libraries have additional templates, including:

- An `.eslintrc.json` configuration file. Any library using JavaScript is expected to pass `eslint` via this configuration.
- A minimal `package.json` file listing any NPM dependencies (including `eslint`) and which includes a `build` script (which calls `eslint` before building the source).
- An updated `ci.yml` file that installs and caches NPM dependencies in addition to the ordinary PureScript toolchain.

If a library ought to use these files, provide the `--uses-js` flag to the `contrib-updater` CLI tool.
