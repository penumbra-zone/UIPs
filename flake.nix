# in flake.nix
{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system ;
          };
        in
        with pkgs;
        {
          devShells.default = mkShell {
            buildInputs = [ 
                firebase-tools
                just
                markdownlint-cli
                mdbook
            ];
          };
        }
      );
}
