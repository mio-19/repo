args@{ config, pkgs, lib, ... }:
{
  imports = [ ./gos.nix ];
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    src = pkgs.fetchgit {
      url = "https://github.com/mio-19/device_google_shusky-kernels_6.1.git";
      rev = "468e9c62688aa0770e0f338b9eadcfaa563a2e25";
      hash = "sha256-qQGIG/yzGMRrTfX6VlJPFyyPYs/mjNFE5ORpjU0ltZ0=";
      fetchLFS = true;
    };
  };
  signing.avb.size = 4096;
  #variant = "userdebug";
}
