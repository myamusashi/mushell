{
    description = "quickshell config";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        wl-screenrec-fork = {
            url = "github:myamusashi/wl-screenrec";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        quickshell = {
            url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = {
        self,
        nixpkgs,
        quickshell,
        wl-screenrec-fork,
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
                inherit quickshell wl-screenrec-fork;
            });

        nixosModules.default = import ./nix/nixos-modules.nix {
            inherit self;
        };

        devShells = forAllSystems (system: let
            pkgs = pkgsFor system;
        in {
            default = import ./shell.nix {inherit pkgs;};
        });
    };
}
