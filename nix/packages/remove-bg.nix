{
    lib,
    stdenvNoCC,
    makeWrapper,
    python314,
}: let
    pythonEnv = python314.withPackages (ps: [ps.rembg]);
in
    stdenvNoCC.mkDerivation {
        pname = "remove-bg";
        version = "0.1.0";
        src = ../../.;
        nativeBuildInputs = [makeWrapper];
        dontBuild = true;
        installPhase = ''
            install -Dm755 Assets/shell/remove-bg.py $out/bin/remove-bg.py
            wrapProgram $out/bin/remove-bg.py --prefix PATH : ${pythonEnv}/bin
        '';
        meta = {
            description = "Background removal using rembg core library (no gradio)";
            homepage = "https://github.com/danielgatis/rembg";
            license = lib.licenses.mit;
        };
    }
