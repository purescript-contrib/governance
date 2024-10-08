> [!WARNING]
> 
> In late 2024 this document is obsolete. See
> - [Spago: Publish my library](https://github.com/purescript/spago?tab=readme-ov-file#publish-my-library)
> - [Registry: Publish a Package](https://github.com/purescript/registry#publish-a-package)

# How to publish a package to Pursuit

In 2022 Pursuit and the PureScript ecosystem are in the interstice between 
[Bower](https://bower.io/) and 
[Registry](https://github.com/purescript/registry). The PureScript package system was originally built on Bower, but 
[Bower has been retired](https://discourse.purescript.org/t/the-bower-registry-is-no-longer-accepting-package-submissions/1103). 
The PureScript core team is working on a replacement package system called Registry, but it is not yet ready.
In this post-Bower, pre-Registry era, we still need to publish packages to Pursuit.

These instructions provide a reasonable basic method for publishing to Pursuit in 2022.
Most of this advice is only applicable in the year 2022 and will be obsolete after the whole Bower and Registry situation is sorted out.

For a development shell which can run all of these commands, we recommend the deluxe `nix develop` shell from [__easy-purescript-nix__](https://github.com/justinwoo/easy-purescript-nix). Install the [Nix package manager](https://nixos.org/download.html). To enter the shell, run this command:

```
nix develop github:justinwoo/easy-purescript-nix#deluxe
```

Then, in the package repo directory, issue the following commands.

1. `git clean -xdff`

    Delete `.pulp-cache`, `.spago`, `bower_components`, `output`, `node_modules`, et cetera, for a totally clean build.

2. `spago bump-version --no-dry-run major`

    If any package dependencies might have changed then we need to generate a new `bower.json`. If we are sure that no package
    dependencies changed then we can skip this step.
    
    We don't really want to `spago bump-version` yet, what we want is for `spago` to generate a new `bower.json` for us,
    and this is the best way to get that. Commit the new `bower.json`. If it turns out that we didn't need a 
    new `bower.json` then this command may actually succeed, in which case it will create a new git tag, which we should delete.

3. `bower install`

    `pulp` will need the bower dependencies installed.

4. `pulp build` `pulp docs`

    If these two commands succeed, then we know that the `pulp publish` command 
    later will succeed.

5. `spago test`

    One last time to be sure.

6. `spago bump-version --no-dry-run major`

    For real this time.

7. `git push origin main`

    Push the *main* branch to Github. Make sure it passes CI.
    
8. `git push` the new tag.

9. Publish to the Registry

   https://github.com/purescript/registry#publish-a-package
    
   The [pacchettibotti](https://github.com/pacchettibotti) will publish our package to Pursuit. 
