args@{
  config,
  pkgs,
  lib,
  self,
  ...
}:
{
  imports = [ ./gts7l.nix ];
  device = lib.mkForce "gts7lwifi";
}
