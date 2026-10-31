{
  config,
  lib,
  pkgs,
  ...
}:
let
  # GrapheneOS ships its boot animation through the `branding` repository now.
  # Only the vector artwork is tracked; frames and the stored (uncompressed)
  # bootanimation.zip archives are built here from logo.svg.
  customBootanimation =
    pkgs.runCommand "grapheneos-custom-bootanimation"
      {
        nativeBuildInputs = [
          (pkgs.python3.withPackages (ps: [
            ps.pycairo
            ps.pillow
          ]))
          pkgs.librsvg
        ];
      }
      ''
        python3 ${./bootanimation/generate.py} ${./bootanimation/logo.svg} $out
      '';
in
{
  options = {
    replaceArtwork = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Replace GrapheneOS artwork with custom artwork";
    };
  };

  config = lib.mkIf config.replaceArtwork {
    # Fallback for the rare case where no bootanimation.zip is found.
    bootanimation = {
      enable = true;
      logoMask = ./ngo-mask.png;
      logoShine = ./ngo-shine.png;
    };

    # GrapheneOS selects one of these by display canvas size.  Replacing all of
    # them keeps every supported device on the custom animation.
    source.dirs."branding".postPatch = ''
      for size in 1080 1280 1344 1440 1600; do
        cp ${customBootanimation}/$size.zip bootanimation/$size.zip
      done
    '';
  };
}
