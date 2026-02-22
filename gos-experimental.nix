args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  source.dirs."bootable/recovery" = lib.mkForce {
    src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_bootable_recovery";
      rev = "833e2948bfe4bbfbf73796391a9336850108e7bd";
      hash = "sha256-QFrwYPZ6Vt/KoUaHWd7w72KB7s4SeYQ2xFoymgi7JeE=";
    };
  };
}
