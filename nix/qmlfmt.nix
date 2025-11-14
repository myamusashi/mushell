{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  qt6,
}: let
  qtcreator-src = stdenv.mkDerivation {
    name = "qtcreator-src-patched";

    src = fetchFromGitHub {
      owner = "qt-creator";
      repo = "qt-creator";
      rev = "4c84e42a0dc204dd95f057c6e482d359dc058ea4";
      hash = "sha256-MmvaNkjBJxhkB9JdGWzjW1VylJMaFLHbpBWdmZB+8Io=";
      fetchSubmodules = false;
    };

    patches = [../patches/qt-creator-missing-header.patch];

    dontBuild = true;
    installPhase = ''
      cp -r . $out
    '';
  };
in
  stdenv.mkDerivation {
    pname = "qmlfmt";
    version = "unstable-2025-06-10";

    src = fetchFromGitHub {
      owner = "jesperhh";
      repo = "qmlfmt";
      rev = "dddaf5ca525131697bd5c24dd342c60bc0793d61";
      hash = "sha256-WOK3UaTiJJp7A2Qq5aICqOrjIpjtBEMt4EzsFRjjBkc=";
      fetchSubmodules = false;
    };

    nativeBuildInputs = [
      cmake
      qt6.wrapQtAppsHook
    ];

    buildInputs = [
      qt6.qtbase
      qt6.qt5compat
      qt6.qtdeclarative
    ];

    patches = [../patches/qmlfmt-pty-unix-include.patch];

    postPatch = ''
      substituteInPlace CMakeLists.txt \
        --replace-fail "qt-creator/cmake/QtCreatorIDEBranding.cmake" \
                 "${qtcreator-src}/cmake/QtCreatorIDEBranding.cmake"

      substituteInPlace qmljs/CMakeLists.txt \
        --replace-fail "../qt-creator/src/libs" \
                 "${qtcreator-src}/src/libs"

      substituteInPlace qmljs/ptyqt.cpp \
        --replace-fail '"../qt-creator/src/libs/3rdparty/libptyqt/ptyqt.h"' \
                 '"${qtcreator-src}/src/libs/3rdparty/libptyqt/ptyqt.h"' \
        --replace-fail '"../qt-creator/src/libs/3rdparty/libptyqt/conptyprocess.h"' \
                 '"${qtcreator-src}/src/libs/3rdparty/libptyqt/conptyprocess.h"' \
        --replace-fail '"../qt-creator/src/libs/3rdparty/libptyqt/unixptyprocess.h"' \
                 '"${qtcreator-src}/src/libs/3rdparty/libptyqt/unixptyprocess.h"'
    '';

    cmakeFlags = [
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
      "-DCMAKE_BUILD_TYPE=Release"
      "-DBUILD_TESTING=OFF"
    ];

    dontWrapQtApps = true;

    meta = with lib; {
      description = "Command line application that formats QML files";
      longDescription = ''
        qmlfmt is a command line tool for formatting QML files.
        It uses Qt Creator's QML parser and formatter to provide
        consistent QML code formatting.
      '';
      homepage = "https://github.com/jesperhh/qmlfmt";
      license = licenses.bsd3;
      maintainers = [];
      platforms = platforms.unix;
      mainProgram = "qmlfmt";
    };
  }
