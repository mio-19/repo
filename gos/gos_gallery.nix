{ lib, ... }:
{
  options.useLineageGallery = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Use the LineageOS Gallery2 app instead of the GrapheneOS Gallery app.
      The LineageOS source is pinned to its Android 17 branch and includes
      downstream delete confirmation fixes.
    '';
  };
}
