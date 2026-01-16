{
  lib,
  stdenvNoCC,
  makeWrapper,
  stdenv,
  gnugrep,
  findutils,
  gnused,
  gawk,
  lucide,
  weather-icons,
  libnotify,
  quickshell,
  m3Shapes,
  util-linux,
  networkmanager,
  matugen,
  playerctl,
  wl-clipboard,
  wl-screenrec,
  ffmpeg,
  foot,
  kdePackages,
  polkit,
  hyprland,
  qt6,
  callPackage,
  fetchFromGitHub,
}: let
  app2unit = callPackage ./app2unit.nix {};
  keystate-bin = callPackage ./keystate.nix {};
  material-symbols = callPackage ./material-symbols.nix {};

  rounded-polygon-qmljs = fetchFromGitHub {
    owner = "end-4";
    repo = "rounded-polygon-qmljs";
    rev = "8aa62a41bd4cdc4899bdfdc0d9cf103ac34c51f6";
    sha256 = "sha256-m9mxJ7M1cH8tASnzk0efgXeNGJyEQDbYGb0wRob3qfU=";
  };

  runtimeDeps = [
    findutils
    gnugrep
    gawk
    gnused
    util-linux
    networkmanager
    matugen
    playerctl
    wl-clipboard
    libnotify
    weather-icons
    wl-screenrec
    ffmpeg
    foot
    polkit
    m3Shapes
    hyprland
    kdePackages.qtmultimedia
    qt6.qtgraphs
    material-symbols
    (lucide.overrideAttrs rec {
      version = "0.544.0";

      url = "https://unpkg.com/lucide-static@${version}/font/Lucide.ttf";
      hash = "sha256-Cf4vv+f3ZUtXPED+PCHxvZZDMF5nWYa4iGFSDQtkquQ=";
    })
  ];

  shell = stdenvNoCC.mkDerivation {
    pname = "shell";
    version = "0.1.0";
    src = ../.;

    nativeBuildInputs = [makeWrapper];

    postPatch = ''
      rm -rf Submodules/rounded-polygon-qmljs
      mkdir -p Submodules
      ln -s ${rounded-polygon-qmljs} Submodules/rounded-polygon-qmljs

      substituteInPlace shell.qml \
        --replace-fail 'ShellRoot {' 'ShellRoot { settings.watchFiles: false'
    '';

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/quickshell
      cp -r * $out/share/quickshell/

      install -Dm755 ${keystate-bin}/bin/keystate-bin \
        $out/share/quickshell/Assets/keystate-bin
      install -Dm755 ${app2unit}/bin/app2unit $out/bin/app2unit
      install -Dm755 ${keystate-bin}/bin/keystate-bin $out/bin/keystate-bin

      mkdir -p $out/share/fonts/truetype
      cp -r ${material-symbols}/share/fonts/truetype/* \
        $out/share/fonts/truetype/

      makeWrapper ${quickshell.packages.${stdenv.hostPlatform.system}.default}/bin/quickshell \
        $out/bin/shell \
        --add-flags "-p $out/share/quickshell" \
        --set QUICKSHELL_CONFIG_DIR "$out/share/quickshell" \
        --set QT_QPA_FONTDIR "${material-symbols}/share/fonts" \
        --prefix PATH : ${lib.makeBinPath (runtimeDeps ++ [app2unit])} \
        --suffix PATH : /run/current-system/sw/bin \
        --suffix PATH : /etc/profiles/per-user/$USER/bin \
        --suffix PATH : $HOME/.nix-profile/bin

      runHook postInstall
    '';

    meta = {
      description = "Custom Quickshell configuration";
      mainProgram = "shell";
    };
  };
in {
  inherit
    shell
    keystate-bin
    material-symbols
    app2unit
    runtimeDeps
    ;
  default = shell;
}
