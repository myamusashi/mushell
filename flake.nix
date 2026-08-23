{
    description = "quickshell config";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        wl-screenrec-fork = {
            url = "github:myamusashi/wl-screenrec";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        another-ripple = {
            url = "github:myamusashi/Another-Ripple";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        m3Shapes = {
            url = "github:myamusashi/m3shapes";
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
        m3Shapes,
        quickshell,
        another-ripple,
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
                inherit quickshell wl-screenrec-fork another-ripple m3Shapes;
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
