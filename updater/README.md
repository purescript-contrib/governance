# Updater

This directory contains a command-line tool useful for updating existing contrib libraries, migrating new ones, and performing common administrative tasks.

Please see the [contrib-updater documentation](./docs) to learn about the commands available in the CLI tool and how to manage related assets like templates.

## Installation

First, ensure you have all necessary dependencies by entering a developer shell:

```sh
nix-shell
```

Then, build the executable by running the `build` script:

```sh
npm run build
```

Finally, run `npm link` to add the executable to your PATH:

```sh
# Nix restricts permissions, so sudo is required if inside the shell.
sudo npm link
```

You can now use the `contrib-updater` executable.

## Usage

You can see usage information by passing the `--help` flag to `contrib-updater` (or to one of its subcommands):

```sh
contrib-updater --help
```

## Documentation

The [contrib-updater documentation](./docs) describes the commands available in the CLI tool and how to manage related assets like templates.
