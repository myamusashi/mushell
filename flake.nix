{
  description = "quickshell config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    quickshell,
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
      inherit self;
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
            pkgs.kdePackages.qtdeclarative
            pkgs.qt6.qtgraphs
            pkgs.go
            pkgs.python3
          ]
          ++ packages.runtimeDeps;

        shellHook = ''
          go build -o ./Assets/keystate-bin ./Assets/keystate.go
          echo "mushell environment"
        '';
      };
    });
  };
}
