# Sync Labels

The `sync-labels` command in the `contrib-updater` CLI sets the issue labels, descriptions, and colors according to the standard set used in Contributor libraries. It can optionally remove all labels which are not part of the standard set (this is not enabled by default).

## Usage

The `sync-labels` command will use a personal GitHub access token you have created to update the labels in a target repository via the GitHub API. Accordingly, you'll need to provide your access token ([create one here](https://github.com/settings/tokens)) and the target repository to update. This command does not need to be run within a checkout of the target repository because all operations happen via the API.

Example CLI usage:

```sh
contrib-updater sync-labels \
  --token abc123 \
  --repo purescript-machines \
  # Optional: Defaults to purescript-contrib if omitted.
  --owner purescript-contrib
  # Optional: Indicates that labels not in the standard Contributor set should
  # be removed from the repository. If omitted those labels will be preserved.
  --delete-unused \
```

## Updating Labels

The set of labels used in the Contributors libraries is maintained by the `SyncLabels` command and should be updated in the source code if you need to make a change.
