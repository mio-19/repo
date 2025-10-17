args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./enchilada22.nix ];
  flavorVersion = lib.mkForce "23.0";
}
