{self}: {
    config,
    lib,
    pkgs,
    ...
}: let
    cfg = config.programs.quickshell-shell;

    material-symbols = pkgs.callPackage ./packages/material-symbols.nix {};

    greeterConfig = pkgs.writeText "mango-greeter.conf" ''
        ${cfg.greetd.extraConfig}
        exec-once=${cfg.package}/bin/quickshell -p ${cfg.package}/share/quickshell/Qml/greeter.qml
    '';
in {
    options.programs.quickshell-shell = {
        enable = lib.mkEnableOption "quickshell shell";

        package = lib.mkOption {
            type = lib.types.package;
            default = self.packages.${pkgs.system}.default;
            description = "The quickshell-shell package to use";
        };

        installFonts = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Install required fonts (recommended)";
        };

        extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
            description = "Extra packages to make available to quickshell";
        };

        greetd = {
            enable = lib.mkEnableOption "greetd login manager with the quickshell greeter";

            user = lib.mkOption {
                type = lib.types.str;
                default = "greeter";
                description = "The user to run the greeter session";
            };

            restart = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                    Restart the greeter when it exits. Disable while testing to
                    drop back to a console instead of respawning the greeter.
                '';
            };

            compositorPackage = lib.mkOption {
                type = lib.types.package;
                default = pkgs.mango;
                description = ''
                    The compositor used to run the greeter. Must implement the
                    ext-session-lock-v1 protocol (required by WlSessionLock in
                    the greeter). Note: cage does NOT implement it, so the
                    greeter would run but never display.
                '';
            };

            extraConfig = lib.mkOption {
                type = lib.types.lines;
                default = "";
                description = "Extra lines appended to the greeter compositor config";
            };
        };
    };

    config = lib.mkIf cfg.enable {
        environment.variables.VAST_SHELL_DIRECTORY = "${cfg.package}/share/quickshell";

        environment.systemPackages =
            [cfg.package]
            ++ cfg.extraPackages;

        fonts.packages = lib.optionals cfg.installFonts [
            material-symbols
            pkgs.weather-icons
        ];

        systemd.user.services.quickshell-shell = {
            description = "Shell widget using quickshell";
            after = ["graphical-session.target"];
            partOf = ["graphical-session.target"];
            wantedBy = ["graphical-session.target"];

            serviceConfig = {
                Type = "simple";
                ExecStart = "${cfg.package}/bin/vastctl daemon start --foreground";
                Restart = "on-failure";
                RestartSec = "5s";
                Environment = [
                    "WAYLAND_DISPLAY=wayland-1"
                    "XDG_RUNTIME_DIR=/run/user/%U"
                    "QT_QPA_PLATFORM=wayland"
                    "DISPLAY=:0"
                    "PATH=${cfg.package}/bin"
                ];
            };
        };

        services.greetd = lib.mkIf cfg.greetd.enable {
            enable = true;

            settings.default_session = {
                command = "${lib.getExe cfg.greetd.compositorPackage} -c ${greeterConfig}";
                user = cfg.greetd.user;
                inherit (cfg.greetd) restart;
                # source_profile = true;
            };
        };
    };
}
