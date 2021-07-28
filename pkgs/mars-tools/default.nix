{ lib, stdenvNoCC, cachix, makeWrapper }:
stdenvNoCC.mkDerivation {
  pname = "mars-tools";
  version = "unstable-2021-07-28";

  src = ./src;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/lib/mars-tools $out/bin
    cp -r $src/* $out/lib/mars-tools

    makeWrapper $out/lib/mars-tools/mars $out/bin/mars \
      --argv0 mars \
      --prefix PATH : $out/lib/mars-tools \
      --prefix PATH : ${cachix}/bin
  '';

  meta = with lib; {
    description = "Mars Research shell utilities";
    license = licenses.mit;
    maintainers = with maintainers; [ zhaofengli ];
  };
}
