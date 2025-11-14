{
  description = "quickshell config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
  };

  outputs = {
    self,
    nixpkgs,
    quickshell,
    apple-fonts,
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [];
      };
  in {
    packages = forAllSystems (system: let
      pkgs = pkgsFor system;
    in
      pkgs.callPackage ./nix/default.nix {
        inherit quickshell;
      });

    homeManagerModules.default = import ./nix/hm-modules.nix {
      inherit self apple-fonts;
    };

    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;
      packages = pkgs.callPackage ./nix/default.nix {
        inherit quickshell;
      };
    in {
      default = pkgs.mkShell {
        packages =
          [
            packages.default
            quickshell.packages.${system}.default
            pkgs.go
            (pkgs.callPackage ./nix/qmlfmt.nix {})
          ]
          ++ packages.runtimeDeps
          ++ [
            apple-fonts.packages.${system}.sf-pro
            apple-fonts.packages.${system}.sf-pro-nerd
            apple-fonts.packages.${system}.sf-mono
            apple-fonts.packages.${system}.sf-mono-nerd
          ];

        shellHook = ''
          echo "Quickshell development environment"
        '';
      };
    });
  };
}
