{ config, lib, ... }:
{
  options = {
    replaceArtwork = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Replace GrapheneOS artwork with custom artwork";
    };
  };

  config = lib.mkIf config.replaceArtwork {
    bootanimation = {
      enable = true;
      logoMask = ./ngo-mask.png;
      logoShine = ./ngo-shine.png;
    };
  };
}
