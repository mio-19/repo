args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./enchilada.nix ];
  flavorVersion = lib.mkForce "23.0";
}
