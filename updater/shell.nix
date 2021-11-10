let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/21.05.tar.gz";
  }) {};

  # nix-prefetch-git https://github.com/justinwoo/easy-purescript-nix
  pursPkgs = import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-purescript-nix";
    rev = "7802db65618c2ead3a55121355816b4c41d276d9";
    sha256 = "0n99hxxcp9yc8yvx7bx4ac6askinfark7dnps3hzz5v9skrvq15q";
  }) { inherit pkgs; };

in pkgs.stdenv.mkDerivation {
  name = "updater";

  buildInputs = with pursPkgs; [
    pursPkgs.purs
    pursPkgs.spago
    pursPkgs.purs-tidy
    pkgs.nodejs-14_x
    pkgs.dhall-json
  ];

  shellHook =''
    npm install
    npm run build
    alias contrib-updater="node $(readlink -f bin/index.js)"
  '' ;
}
