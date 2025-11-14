{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "material-symbols";
  version = "4.0.0-unstable-2025-04-11";

  src = fetchFromGitHub {
    owner = "google";
    repo = "material-design-icons";
    rev = "941fa95d7f6084a599a54ca71bc565f48e7c6d9e";
    hash = "sha256-5bcEh7Oetd2JmFEPCcoweDrLGQTpcuaCU8hCjz8ls3M=";
    sparseCheckout = ["variablefont"];
  };

  dontBuild = true;

  installPhase = ''
    install -Dm644 variablefont/MaterialSymbolsOutlined[FILL,GRAD,opsz,wght].ttf \
      $out/share/fonts/truetype/MaterialSymbolsOutlined.ttf
  '';

  meta = {
    description = "Material Symbols variable font";
    homepage = "https://github.com/google/material-design-icons";
    license = lib.licenses.asl20;
  };
}
