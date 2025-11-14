{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  gnugrep,
  findutils,
  gnused,
  gawk,
  scdoc,
  libnotify,
}:
stdenvNoCC.mkDerivation rec {
  pname = "app2unit";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "Vladimir-csp";
    repo = "app2unit";
    tag = "v${version}";
    hash = "sha256-7eEVjgs+8k+/NLteSBKgn4gPaPLHC+3Uzlmz6XB0930=";
  };

  nativeBuildInputs = [makeWrapper];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 app2unit $out/bin/app2unit

    wrapProgram $out/bin/app2unit \
      --prefix PATH : ${lib.makeBinPath [
      findutils
      gnugrep
      gnused
      gawk
      scdoc
      libnotify
    ]}

    runHook postInstall
  '';

  meta = {
    description = "Systemd integration for applications";
    homepage = "https://github.com/Vladimir-csp/app2unit";
    license = lib.licenses.gpl3Plus;
  };
}
