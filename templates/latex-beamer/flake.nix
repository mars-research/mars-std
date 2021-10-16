{
  description = "A presentation";

  inputs = {
    mars-std.url = "github:mars-research/mars-std";
  };

  outputs = { self, mars-std, ... }: let
    # System types to support.
    supportedSystems = [ "x86_64-linux" ];
  in mars-std.lib.eachSystem supportedSystems (system: let
    pkgs = mars-std.legacyPackages.${system};

    texliveBundle = pkgs.texlive.combine {
      inherit (pkgs.texlive) scheme-basic

      latexmk
      beamer beamertheme-metropolis pgfopts;
    };
  in {
    devShell = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        texliveBundle
      ];
    };
  });
}
