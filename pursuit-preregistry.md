# How to publish a package to Pursuit

In 2022 Pursuit and the PureScript ecosystem are in the interstice between 
[Bower](https://bower.io/) and 
[Registry](https://github.com/purescript/registry). The PureScript package system was originally built on Bower, but 
[Bower has been retired](https://discourse.purescript.org/t/the-bower-registry-is-no-longer-accepting-package-submissions/1103). 
The PureScript core team is working on a replacement package system called Registry, but it is not yet ready.
In this post-Bower, pre-Registry era, we still need to publish packages to Pursuit.

These instructions provide a reasonable basic method for publishing to Pursuit in 2022.
Most of this advice is only applicable in the year 2022 and will be obsolete after the whole Bower and Registry situation is sorted out.

Here is a `shell.nix` file which gives us a `nix-shell` with these tools on the `PATH`:

* `purs`
* `spago`
* `purs-tidy`
* `purs-backend-es`
* `pulp`
* `node`
* `npm`
* `bower`
* `esbuild`

```nix
# Universal shell for PureScript repos
# { pkgs ? import <nixpkgs> { }
{ pkgs ? import (builtins.fetchGit {
  # https://github.com/NixOS/nixpkgs/releases/tag/22.05
  url = "https://github.com/nixos/nixpkgs/";
  ref = "refs/tags/22.05";
  rev = "ce6aa13369b667ac2542593170993504932eb836";
  }) {}
}:
let
  easy-ps-src = builtins.fetchGit {
    url = "https://github.com/justinwoo/easy-purescript-nix.git";
    ref = "master";
    rev = "3d8b602e80c0fa7d97d7f03cb8e2f8b06967d509";
  };
  easy-ps = import easy-ps-src { inherit pkgs; };
in
pkgs.mkShell {
  nativeBuildInputs = [
    easy-ps.purs-0_15_4
    easy-ps.spago
    easy-ps.pulp
    easy-ps.psc-package
    easy-ps.purs-tidy
    easy-ps.purs-backend-es
    pkgs.nodejs-18_x
    pkgs.nodePackages.bower
    pkgs.esbuild
  ];
  LC_ALL = "C.UTF-8"; # https://github.com/purescript/spago/issues/507
  # https://github.com/purescript/spago#install-autocompletions-for-bash
  shellHook = ''
    source <(spago --bash-completion-script `which spago`)
  '';
}
```

Install the [Nix package manager](https://nixos.org/download.html). Enter the shell with the command `nix-shell shell.nix`.

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

8. `pulp publish --no-push`

    This will publish our package to Pursuit. No README will appear because we haven't pushed the new version tag to Github yet, which is fine.

    This command often fails the first time, but run it again and it will always succeed, in my experience.

10. `git push` the new tag.

    Now the README will appear on Pursuit.

Don’t forget to update the registry. https://github.com/purescript/registry#publish-a-package
