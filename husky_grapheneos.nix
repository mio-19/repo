args@{ config, pkgs, lib, ... }:
{
  imports = [ ./gos.nix ];
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    src = pkgs.fetchgit {
      url = "https://github.com/mio-19/device_google_shusky-kernels_6.1.git";
      rev = "a7d924e1071ae88caf1511e34f5f03a0b76c3ef5";
      hash = "sha256-2qrMqOas7FoV3f4kGdE130zKGINeIaim+JNBHxAdq3Q=";
      fetchLFS = true;
    };
  };
  signing.avb.size = 4096;
  #variant = "userdebug";
}
