args@{
  config,
  pkgs,
  lib,
  self,
  ...
}:
{
  imports = [ ./gts7l.nix ];
  device = "gts7lwifi";
}
