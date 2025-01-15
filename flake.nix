{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }: let
    forAllSystems = p:
      nixpkgs.lib.genAttrs [
        "i686-linux"
        "x86_64-linux"
      ] (system: p nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: rec {
      bin = pkgs.callPackage ./package.nix {
        withTarget = "vulpforth.bin";
      };
      debug = pkgs.callPackage ./package.nix {
        withTarget = "vulpforth";
      };
      zip = pkgs.callPackage ./package.nix {
        withTarget = "vulpforth.zip";
      };
      zipdebug = pkgs.callPackage ./package.nix {
        withTarget = "vulpforth.zip";
        withSstrip = false;
        withUpx = false;
      };
      default = bin;
    });
  };
}
