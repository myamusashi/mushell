{
    lib,
    makeWrapper,
    stdenv,
    gnugrep,
    findutils,
    gnused,
    gawk,
    weather-icons,
    libnotify,
    iw,
    quickshell,
    wl-screenrec-fork,
    util-linux,
    matugen,
    wl-clipboard,
    ffmpeg,
    wireplumber,
    foot,
    python314,
    kdePackages,
    polkit,
    patchelf,
    hyprland,
    qt6,
    callPackage,
    cmake,
}: let
    app2unit = callPackage ./packages/app2unit.nix {};
    material-symbols = callPackage ./packages/material-symbols.nix {};
    m3shapes = callPackage ./plugins/m3Shapes.nix {};
    another-ripple = callPackage ./plugins/AnotherRipple.nix {};
    vastPlugin = callPackage ./plugins/vastPlugin.nix {};
    vastctl = callPackage ./packages/vastctl.nix {};
    remove-bg = callPackage ./packages/remove-bg.nix {};

    runtimeDeps = [
        findutils
        gnugrep
        gawk
        gnused
        util-linux
        remove-bg
        wireplumber
        iw
        libnotify
        polkit
        weather-icons
        material-symbols
        matugen
        wl-clipboard
        wl-screenrec-fork
        ffmpeg
        foot
        hyprland
        kdePackages.qtmultimedia
        qt6.qt5compat
        qt6.qtbase
        qt6.qtgraphs
    ];

    vast-shell = stdenv.mkDerivation {
        pname = "vast-shell";
        version = "0.1.0";
        src = ../.;

        nativeBuildInputs = [
            makeWrapper
            patchelf
            cmake
            qt6.qttools
            qt6.wrapQtAppsHook
        ];

        buildInputs = [
            qt6.qtbase
            qt6.qtdeclarative
            qt6.qtmultimedia
            qt6.qtgraphs
            qt6.qt5compat
            kdePackages.qtmultimedia
        ];

        postPatch = ''
            substituteInPlace Qml/shell.qml \
              --replace-fail 'ShellRoot {' 'ShellRoot { settings.watchFiles: false'
        '';

        dontUseCmakeConfigure = true;
        dontWrapQtApps = true;

        buildPhase = ''
            runHook preBuild

            echo "Compile Translations..."
            if [ -d "translations" ]; then
                ${qt6.qttools}/bin/lrelease translations/*.ts
            fi

            echo "Cleaning old shaders..."
            find Assets/shaders -name "*.qsb" -delete

            echo "Compile shaders..."
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/ImageTransition.vert.qsb \
                   Assets/shaders/ImageTransition.vert

            for name in fade wipeDown hexTile circleExpand dissolve splitHorizontal slideUp pixelate diagonalWipe boxExpand roll; do
                echo "Compiling ''${name}.frag..."
                ${qt6.qtshadertools}/bin/qsb \
                    --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                    -o Assets/shaders/transitions/''${name}.frag.qsb \
                       Assets/shaders/transitions/''${name}.frag
            done

            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/borderProgress.vert.qsb \
                   Assets/shaders/borderProgress.vert
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/borderProgress.frag.qsb \
                   Assets/shaders/borderProgress.frag
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/wavy.vert.qsb \
                   Assets/shaders/wavy.vert
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/wavy.frag.qsb \
                   Assets/shaders/wavy.frag
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/waveForm.vert.qsb \
                   Assets/shaders/waveForm.vert
            ${qt6.qtshadertools}/bin/qsb \
                --glsl "450,330,300 es" --hlsl 50 --msl 12 \
                -o Assets/shaders/waveForm.frag.qsb \
                   Assets/shaders/waveForm.frag

            runHook postBuild
        '';

        installPhase = ''
            runHook preInstall

            mkdir -p $out/share/quickshell
            shopt -s extglob
            cp -r !(build) $out/share/quickshell/ 2>/dev/null || true

            install -Dm755 ${app2unit}/bin/app2unit $out/bin/app2unit

            cp -r ${vastctl}/share/bash-completion $out/share/ 2>/dev/null || true
            cp -r ${vastctl}/share/fish $out/share/ 2>/dev/null || true
            cp -r ${vastctl}/share/zsh $out/share/ 2>/dev/null || true
            cp -r ${vastctl}/share/nushell $out/share/ 2>/dev/null || true

            makeWrapper ${vastctl}/bin/vastctl \
              $out/bin/vastctl \
                --set VAST_SHELL_DIRECTORY "$out/share/quickshell" \
                --set QT_QPA_FONTDIR "${material-symbols}/share/fonts/truetype" \
                --prefix QML2_IMPORT_PATH : "$out/lib/qt-${qt6.qtbase.version}/qml" \
                --prefix QML2_IMPORT_PATH : "${qt6.qt5compat}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix QML2_IMPORT_PATH : "${qt6.qtgraphs}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix QML2_IMPORT_PATH : "${another-ripple}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix QML2_IMPORT_PATH : "${vastPlugin}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix PATH : ${lib.makeBinPath (runtimeDeps ++ [app2unit])} \
                --suffix PATH : /run/current-system/sw/bin \

            makeWrapper ${quickshell.packages.${stdenv.hostPlatform.system}.default}/bin/quickshell \
              $out/bin/quickshell \
                --set VAST_SHELL_DIRECTORY "$out/share/quickshell" \
                --set QT_QPA_FONTDIR "${material-symbols}/share/fonts/truetype" \
                --prefix QML2_IMPORT_PATH : "$out/lib/qt-${qt6.qtbase.version}/qml" \
                --prefix QML2_IMPORT_PATH : "${qt6.qt5compat}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix QML2_IMPORT_PATH : "${qt6.qtgraphs}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix QML2_IMPORT_PATH : "${another-ripple}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix QML2_IMPORT_PATH : "${vastPlugin}/${qt6.qtbase.qtQmlPrefix}" \
                --prefix PATH : ${lib.makeBinPath runtimeDeps} \
                --suffix PATH : /run/current-system/sw/bin \

            mkdir -p $out/share/fonts/truetype
            cp -r ${material-symbols}/share/fonts/truetype/* $out/share/fonts/truetype/

            mkdir -p $out/${qt6.qtbase.qtQmlPrefix}
            if [ -d "${m3shapes}/${qt6.qtbase.qtQmlPrefix}" ]; then
              cp -r ${m3shapes}/${qt6.qtbase.qtQmlPrefix}/* $out/${qt6.qtbase.qtQmlPrefix}
            fi
            if [ -d "${another-ripple}/${qt6.qtbase.qtQmlPrefix}" ]; then
              cp -r ${another-ripple}/${qt6.qtbase.qtQmlPrefix}/* $out/${qt6.qtbase.qtQmlPrefix}
            fi
            if [ -d "${vastPlugin}/${qt6.qtbase.qtQmlPrefix}" ]; then
              cp -r ${vastPlugin}/${qt6.qtbase.qtQmlPrefix}/* $out/${qt6.qtbase.qtQmlPrefix}
            fi

            runHook postInstall
        '';
    };
in {
    inherit
        vastctl
        vastPlugin
        material-symbols
        app2unit
        remove-bg
        runtimeDeps
        ;
    default = vast-shell;
}
