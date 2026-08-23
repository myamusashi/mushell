{pkgs}:
(pkgs.mkShell.override {stdenv = pkgs.clangStdenv;}) {
    nativeBuildInputs = with pkgs; [
        qt6.wrapQtAppsHook
        cmake
        ninja
    ];

    buildInputs = with pkgs; [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtmultimedia
        qt6.qtgraphs
        qt6.qt5compat
        qt6.qttranslations
        ddcutil
        pipewire.dev
        wayland
        wayland-protocols
    ];

    packages = with pkgs; [
        go
        gopls
        golangci-lint
        nil
        pkg-config
        wayland-scanner
        qt6.qttools
        qt6.qtshadertools
        python314Packages.rembg
        clang
        clang-tools
        gdb
    ];

    shellHook = ''
        FLAGS='--glsl "450,330,300 es" --hlsl 50 --msl 12'

        compile_if_missing() {
            local output="$1"
            local input="$2"

            if [ ! -f "$output" ]; then
                echo "Compiling: $output"
                eval qsb $FLAGS -o "$output" "$input"
            fi
        }

        compile_if_missing "Assets/shaders/ImageTransition.vert.qsb" "Assets/shaders/ImageTransition.vert"

        TRANSITIONS=(
            fade wipeDown circleExpand dissolve splitHorizontal
            hexTile slideUp pixelate diagonalWipe boxExpand roll
        )
        for name in "''${TRANSITIONS[@]}"; do
            compile_if_missing "Assets/shaders/transitions/$name.frag.qsb" "Assets/shaders/transitions/$name.frag"
        done

        SHADERS=(borderProgress wavy waveForm)
        for shader in "''${SHADERS[@]}"; do
            compile_if_missing "Assets/shaders/$shader.vert.qsb" "Assets/shaders/$shader.vert"
            compile_if_missing "Assets/shaders/$shader.frag.qsb" "Assets/shaders/$shader.frag"
        done

        echo "mushell environment (clang toolchain)"
    '';
}
