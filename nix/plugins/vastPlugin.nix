{
    lib,
    stdenv,
    cmake,
    qt6,
    patchelf,
    pipewire,
    ddcutil,
    pkg-config,
    wayland,
    wayland-protocols,
    wayland-scanner,
}:
stdenv.mkDerivation {
    pname = "vast-plugin";
    version = "1.0";
    src = ../../Plugins/Vast;

    nativeBuildInputs = [
        cmake
        qt6.wrapQtAppsHook
        patchelf
        pkg-config
        wayland-scanner
        wayland-protocols
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        pipewire
        ddcutil
        wayland
    ];

    cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
        "-DQML_INSTALL_DEST=lib/qt-6/qml/Vast"
    ];

    dontWrapQtApps = true;

    postInstall = ''
        PLUGIN_DIR="$out/${qt6.qtbase.qtQmlPrefix}/Vast"

        if [ -f "$PLUGIN_DIR/libVastPlugin.so" ]; then
          patchelf --set-rpath \
            "$PLUGIN_DIR:${lib.makeLibraryPath [
            qt6.qtbase
            qt6.qtdeclarative
            pipewire
            ddcutil
            wayland
        ]}" \
            "$PLUGIN_DIR/libVastPlugin.so"
        fi

        if [ -f "$PLUGIN_DIR/libVastQmlPlugin.so" ]; then
          patchelf --set-rpath \
            "$PLUGIN_DIR:${lib.makeLibraryPath [
            qt6.qtbase
            qt6.qtdeclarative
        ]}" \
            "$PLUGIN_DIR/libVastQmlPlugin.so"
        fi
    '';

    meta = with lib; {
        description = "Unified Vast Plugin for Quickshell";
        license = licenses.gpl3Plus;
        platforms = platforms.linux;
    };
}
