{
    lib,
    stdenvNoCC,
    makeWrapper,
    python314,
}: let
    pythonEnv = python314.withPackages (ps: [ps.materialyoucolor ps.pillow]);
in
    stdenvNoCC.mkDerivation {
        pname = "generate-colors-material";
        version = "0.1.0";
        src = ../../.;
        nativeBuildInputs = [makeWrapper];
        dontBuild = true;
        installPhase = ''
            install -Dm755 Assets/shell/generate_colors_material.py $out/bin/generate-colors-material
            wrapProgram $out/bin/generate-colors-material --prefix PATH : ${pythonEnv}/bin
        '';
        meta = {
            description = "Material You color generation from wallpaper image";
            homepage = "https://github.com/end-4/dots-hyprland";
            license = lib.licenses.gpl3Plus;
        };
    }