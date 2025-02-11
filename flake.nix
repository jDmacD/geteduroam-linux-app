{
  description = "A basic gomod2nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";
  inputs.gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.gomod2nix.inputs.flake-utils.follows = "flake-utils";

  outputs = { self, nixpkgs, flake-utils, gomod2nix }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          callPackage = pkgs.darwin.apple_sdk_11_0.callPackage or pkgs.callPackage;
        in
        {
          packages = {
            gui = callPackage ./. {
              inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
              target = "gui";
            };
            cli = callPackage ./. {
              inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
              target = "cli";
            };
            notifcheck = callPackage ./. {
              inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
              target = "notifcheck";
            };
            full = pkgs.symlinkJoin {
              name = "geteduroam-full";
              paths = [
                self.packages.${system}.gui
                self.packages.${system}.cli
                self.packages.${system}.notifcheck
              ];
            };
            default = self.packages.${system}.full;
          };
          
          devShells.default = callPackage ./shell.nix {
            inherit (gomod2nix.legacyPackages.${system}) mkGoEnv gomod2nix;
          };
        })
    );
}

