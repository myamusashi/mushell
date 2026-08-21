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
    fetchFromGitHub,
}: let
    material-color-utilities = fetchFromGitHub {
        owner = "material-foundation";
        repo = "material-color-utilities";
        rev = "f05459ea2170f3be610f89a4ddeee8843c2deb61";
        hash = "sha256-EQozefgSHR9SM7So2oRgsu1tSPeeZkwjS7HxJYKgWjo=";
    };
in
    stdenv.mkDerivation {
        pname = "vast-plugin";
        version = "1.0";
        src = ../../Plugins;

        postPatch = ''
            mkdir -p third_party/material-color-utilities
            cp -r --no-preserve=mode ${material-color-utilities}/. third_party/material-color-utilities/
        '';

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
