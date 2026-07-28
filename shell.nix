{pkgs}:
pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
        qt6.wrapQtAppsHook
        cmake
    ];

    buildInputs = with pkgs; [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qt5compat
        qt6.qttranslations
        ddcutil
        pipewire.dev
    ];

    packages = with pkgs; [
        go
        gopls
        golangci-lint
        nil
        pkg-config
        qt6.qttools
        qt6.qtshadertools
        python313Packages.rembg
        gcc
        gdb
        cmake
        clang-tools
    ];

    shellHook = ''
        go build -o ./Assets/go/formatting ./Assets/go/formatting.go

        echo "Compiling shaders..."
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/ImageTransition.vert.qsb Assets/shaders/ImageTransition.vert
        for name in fade wipeDown circleExpand dissolve splitHorizontal hexTile slideUp pixelate diagonalWipe boxExpand roll; do
            qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/transitions/$name.frag.qsb Assets/shaders/transitions/$name.frag
        done
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/borderProgress.vert.qsb Assets/shaders/borderProgress.vert
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/borderProgress.frag.qsb Assets/shaders/borderProgress.frag
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/wavy.vert.qsb Assets/shaders/wavy.vert
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/wavy.frag.qsb Assets/shaders/wavy.frag
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/waveForm.vert.qsb Assets/shaders/waveForm.vert
        qsb --glsl "450,330,300 es" --hlsl 50 --msl 12 -o Assets/shaders/waveForm.frag.qsb Assets/shaders/waveForm.frag

        echo "mushell environment"
    '';
}
