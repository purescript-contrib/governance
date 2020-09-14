# Updater

This directory contains a command-line tool useful for updating existing contrib libraries, migrating new ones, and performing common administrative tasks.

Please see the [contrib-updater documentation](./docs) to learn about the commands available in the CLI tool and how to manage related assets like templates.

## Installation

The Nix shell provides all necessary dependencies and hooks for installing dependencies and building the tool. Start by entering the shell:

```sh
nix-shell
```

You can now use `contrib-updater` to run the tool:

```sh
contrib-updater --help
```

## Usage

You can see usage information by passing the `--help` flag to `contrib-updater` (or to one of its subcommands):

```sh
contrib-updater --help
```

## Documentation

The [contrib-updater documentation](./docs) describes the commands available in the CLI tool and how to manage related assets like templates.
