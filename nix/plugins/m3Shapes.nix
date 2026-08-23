{
    lib,
    clangStdenv,
    cmake,
    ninja,
    patchelf,
    fetchFromGitHub,
    qt6,
}:
clangStdenv.mkDerivation {
    pname = "m3shapes";
    version = "unstable-2025-01-13";

    src = fetchFromGitHub {
        owner = "myamusashi";
        repo = "m3shapes";
        rev = "1c8e6751febf230d7f94bf8015eaeb643bb4521e";
        hash = "sha256-aLMj10UaFEBGHDw75+3QFvvk2wjokkXRQyRjs1guVGI=";
    };

    nativeBuildInputs = [
        cmake
        ninja
        patchelf
        qt6.wrapQtAppsHook
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
    ];

    cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
        "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
        (lib.cmakeFeature "INSTALL_QMLDIR" "lib/qt-6/qml")
    ];

    dontWrapQtApps = true;

    postInstall = ''
        pluginPath="$out/${qt6.qtbase.qtQmlPrefix}/M3Shapes/libm3shapesplugin.so"

        patchelf --set-rpath "${placeholder "out"}/${qt6.qtbase.qtQmlPrefix}/M3Shapes:${qt6.qtbase.outPath}/lib" "$pluginPath"
    '';
}
