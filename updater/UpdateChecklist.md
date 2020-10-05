
# Contributor Library Update Checklist
One goal of the Contributors working group is to make sure that the `purescript-contrib` libraries all meet the [library guidelines](https://github.com/purescript-contrib/governance/blob/main/library-guidelines.md). This includes adequate tests, documentation, and tooling (using Spago, using the same issue labels, and so on). The [contrib updater](https://github.com/purescript-contrib/governance/tree/main/updater) tool can help with this migration and it has documentation on correct use (see [the readme](https://github.com/purescript-contrib/governance/tree/main/updater#updater) for more).

However, libraries require manual review and some manual steps as part of the process. In general, to update a library in the Contributors organization, you will need to:

1. Update the project to use Spago (if it doesn’t already use it)
2. Update some files that are lowercased so they are uppercased (contributing.md, for example), which should be done with git if you are on Mac or Windows
3. Use the contrib updater tool to update the project’s files
4. Reconcile any high quality content that would be removed by the updater tool by manually putting it back into the generated templates.
5. Open a pull request with your changes
6. Manually review the library’s tests and documentation to see if it meets the library guidelines. If not, open issues for each way in which it fails to meet the guidelines and add an appropriate label.

You can use the [machines library](https://github.com/purescript-contrib/purescript-machines) or the [js timers library](https://github.com/purescript-contrib/purescript-js-timers) as an example of what the final result should look like (I used js timers in the walkthrough below). You can also take any of the open issues if you would like to tackle one!

## 1. Update the project to use Spago
After forking / cloning the library in question and checking out a branch like `contrib-update`, the first thing to do is migrate it to Spago if it’s not already done. Specifically:

1. Run `spago init -C` to migrate the project, without comments.
2. If there are any problems, use the package registry to see what the Spago file needs to contain as dependencies.
3. (If you didn't run with `-C`, delete the comments in the packages.dhall and spago.dhall files — I consider them to be quite noisy in these standard files and make it harder to see what package set is in use.)
4. (If there are generated overrides and additions from the packages.dhall file, remove them -- now that Spago uses the `with` syntax they aren’t necessary. Or if I missed an update that no longer generates them, that’s fine too).

You need to preserve the Bower file in place until the library can be updated for the package registry format.

![spago-migration](https://user-images.githubusercontent.com/10245104/92983105-6a89c500-f456-11ea-9a38-eee6c82ace62.gif)

## 2. Update some files that are lowercased
Some files in these repositories (namely the pull request template and the contributing file) were added as lowercased files. The files have to be renamed because otherwise links won’t work — a link to ‘contributing.md’ is not the same as to ‘CONTRIBUTING.md’, so we need to standardize them. 

Simply renaming these files on Mac or Windows won’t have an effect because these file systems are case sensitive. Instead we can rename them via git with a command like:

```sh
git mv .github/contributing.md ./CONTRIBUTING.md
git mv .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md
```

![update-lowercased](https://user-images.githubusercontent.com/10245104/92983114-78d7e100-f456-11ea-9bf9-883a4fa4604e.gif)

You’ll also see an issue template in these repositories. You can ignore or delete this file. Either way, it will be removed in the next step (using the contrib-updater tool to update project files).

## 3. Use the contrib updater tool to update the project’s files
In this step we’ll update the project files and repository structure. This involves a couple steps:

1. Delete any obvious unused files. Typically, you should delete the `issue_template.md` file, `.travis.yml` file, `package.json` and `package-lock.json` files (unless the project uses JS, in which case keep the `package.json` file), and `jshintrc` files. If in doubt about any other files and whether to keep them, just make a note in the PR about it.
2. Run the updater tool to generate the files the project should use. If the project uses JS (for example, via the FFI) then include the `--uses-js` flag.

> Note: You should read the Travis file before deleting it. If all it does is download PureScript tooling, build the project, and upload docs to Pursuit (which is broken), then it’s safe to delete.

Note: You will probably want to enter a Nix shell via the goverance/contrib-updater repository before using the updater tool, as it uses `dhall-to-json`  to read the Spago file and determine the package name (you can also just install dhall-json):

![nix-shell](https://user-images.githubusercontent.com/10245104/92983124-82614900-f456-11ea-8d11-0295f71ffe42.gif)

When you run the updater tool a new directory will be created named “backups”. This has a copy of any file that would have been overwritten by the updater tool, unless that file had the same contents as the updater tool has. We’ll use that in the next section to reconcile any content we want to keep.

Typically you'll just run:

```
contrib-updater generate --maintainer MAINTAINER1 --maintainer MAINTAINER2
```

In action:
![delete-then-run-updater](https://user-images.githubusercontent.com/10245104/92983138-8b521a80-f456-11ea-9029-13a2c16f1763.gif)

## 4. Reconcile content
If there is any good content that was in the repository before, then you can look in the backups directory and use it to update the relevant content. For example, the new README will have no library summary or quick start — most libraries do at least have a library summary already, so you can copy it over and improve it a little as you see fit.

Some common things you might want to check:

* If the project uses JS and has a package.json file, then you can check the backed-up file to see if it does anything other than provide a ‘clean’ command and build the project (and optionally run eslint). If this is all it provides, then you can delete it and just use the file generated by the updater tool.
* Read through the backed-up README so you can excerpt any good content (like a library summary, quick start, or tutorial) into the new README or documentation folder.

## 5. Open a PR with your changes
I am using this template for PRs and adding any other relevant information I notice to it — [I used this to open. PR to js-timers](https://github.com/purescript-contrib/purescript-js-timers/pull/15). Move the header to be the title of the PR and adjust the content as needed.

```
# Update according to Contributors library guidelines

This pull request is part of an effort to update and standardize the Contributors libraries according to the [Library Guidelines](https://github.com/purescript-contrib/governance/blob/main/library-guidelines.md). Specifically, it:

1. Adjusts the files and repository structure according to the [repository structure](https://github.com/purescript-contrib/governance/blob/main/library-guidelines.md#repository-structure) section of the guidelines, which includes standard pr templates, issue templates, CI in GitHub Actions, automatic stale issue management, ensures the project uses Spago, and so on.
2. Updates the README and documentation according to the [documentation](https://github.com/purescript-contrib/governance/blob/main/library-guidelines.md#documentation) section of the guidelines. This is a first step towards ensuring Contributors libraries have adequate module documentation, READMEs, a docs directory, and tests (even if just usage examples) in a `test` directory.
3. Updates labels where relevant to help folks better sift through issues on this library and get started contributing.

This PR is the groundwork for followup efforts to ensure contributor libraries are kept up-to-date, documented, tested, and accessible to users and new contributors.
```

## 6. Manually review the project tests and documentation
When reviewing tests and documentation I’m looking for four things, each of which is covered by an issue template. Each of these templates can be adjusted to fit the particular case you’re working with.

First, does the package have any tests? (JS Timers does, so no problem here.)
```
# Repository doesn't have tests
**Is your change request related to a problem? Please describe.**
As described in the [tests section of the Library Guidelines](https://github.com/purescript-contrib/governance/blob/main/library-guidelines.md#tests), Contributors libraries are expected to have tests exercised in CI on pull requests and the main branch.

This library currently doesn't have any real tests.

**Describe the solution you'd like**
There should be at least one real test in the [test](../blob/main/test) directory. It can be a minimal usage example similar to the quick start in the repository README.

**Additional context**
See the [Governance repository](https://github.com/purescript-contrib/governance) for more information about requirements in the Contributors organization.
```

Second, does the package README have quick start documentation to get a new user up to speed right away? (JS Timers [does not have this](https://github.com/purescript-contrib/purescript-js-timers/issues/16)).
```
# Repository doesn't have a quick start section in the README
**Is your change request related to a problem? Please describe.**
As described in the [documentation section of the Library Guidelines](https://github.com/purescript-contrib/governance/blob/main/library-guidelines.md#documentation), Contributors libraries are expected to have in their README a short summary of the library's purpose, installation instructions, a quick start with a minimal usage example, and links to the documentation and contributing guide.

This library currently doesn't have a completed [quick start](../#quick-start) in the README.

**Describe the solution you'd like**
The library needs a quick start section after the installation instructions. [argonaut-codecs](https://github.com/purescript-contrib/purescript-argonaut-codecs#quick-start) is one example of a library with a quick start.

**Additional context**
See the [Governance repository](https://github.com/purescript-contrib/governance) for more information about requirements in the Contributors organization.
```

Third, does the package have module documentation? (JS Timers does have this.)
```
# Library doesn't have sufficient module documentation
**Is your change request related to a problem? Please describe.**
As described in the [documentation section of the Library Guidelines](https://github.com/purescript-contrib/governance/blob/main/library-guidelines.md#documentation), Contributors libraries are expected to have mostly complete module documentation, preferably uploaded to Pursuit.

This library currently doesn't have sufficient module documentation -- many publicly-exported types and functions don't have any documentation comments.

**Describe the solution you'd like**
The library needs to have documentation comments on the majority (and preferably all) public types and functions. Once updated, we should tag a release and upload new module documentation to Pursuit so that folks can use it.

**Additional context**
See the [Governance repository](https://github.com/purescript-contrib/governance) for more information about requirements in the Contributors organization.
```

Fourth, does the package have good documentation in the docs directory.
```
# Library has inadequate documentation in the docs directory
**Is your change request related to a problem? Please describe.**
As described in the [documentation section of the Library Guidelines](https://github.com/purescript-contrib/governance/blob/main/library-guidelines.md#documentation), Contributors libraries are expected to have some documentation in the docs directory -- specifically, at least a short tutorial that expands on the quick start in the README.

This library currently doesn't have comprehensive documentation in the [docs](../blob/main/docs) directory.

**Describe the solution you'd like**
At least a short tutorial needs to be added to the docs directory, or other documentation [as described in this Divio article](https://documentation.divio.com).

The [argonaut-codecs docs directory](https://github.com/purescript-contrib/purescript-argonaut-codecs/tree/master/docs) has a good example of expanded documentation for a Contributor library. But it would even be useful to add something considerably smaller and shorter to this library.

**Additional context**
See the [Governance repository](https://github.com/purescript-contrib/governance) for more information about requirements in the Contributors organization.
```
