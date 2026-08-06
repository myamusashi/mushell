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
    src = ../../Plugins;

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
        "-DINSTALL_QMLDIR=${qt6.qtbase.qtQmlPrefix}"
    ];

    dontWrapQtApps = true;

    # The plugin is split into per-domain QML modules under the Vast
    # namespace (Vast.Audio, Vast.Clipboard, ...). Backing targets live in
    # <qml>/Vast/lib, plugins in <qml>/Vast/<Module>/. Patch an rpath on every
    # shared object so they can find each other and the Qt deps.
    postInstall = ''
        VAST_DIR="$out/${qt6.qtbase.qtQmlPrefix}/Vast"
        DEPS="${lib.makeLibraryPath [
            qt6.qtbase
            qt6.qtdeclarative
            pipewire
            ddcutil
            wayland
        ]}"

        find "$VAST_DIR" -name '*.so' -print0 | while IFS= read -r -d ''' so_file; do
            echo "Patching $so_file"
            patchelf --set-rpath "$(dirname "$so_file"):$VAST_DIR/lib:$DEPS" "$so_file"
        done
    '';

    meta = with lib; {
        description = "Vast QML modules for Quickshell (Vast.Audio, Vast.Clipboard, ...)";
        license = licenses.gpl3Plus;
        platforms = platforms.linux;
    };
}