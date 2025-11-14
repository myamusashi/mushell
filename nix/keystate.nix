{
  stdenvNoCC,
  go,
}:
stdenvNoCC.mkDerivation {
  pname = "keystate-bin";
  version = "0.1.0";

  src = ../Assets;

  nativeBuildInputs = [go];

  buildPhase = ''
    export HOME=$TMPDIR
    go build -o keystate-bin keystate.go
  '';

  installPhase = ''
    install -Dm755 keystate-bin $out/bin/keystate-bin
  '';

  meta = {
    description = "Keyboard state monitor";
    mainProgram = "keystate-bin";
  };
}
