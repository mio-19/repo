args@{ config, pkgs, lib, ... }:
{
  imports = [ ./gos.nix ];
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    src = pkgs.fetchgit {
      url = "https://github.com/mio-19/device_google_shusky-kernels_6.1.git";
      # pixel8pro-stock-fix.patch
      rev = "3bfdce92cbaef6a221d4e28361479f61cde93241";
      hash = "sha256-N4J9kKrBnhyVuMf4I8uRUG+Dk4aJMuor5eup686BRo4=";
      fetchLFS = true;
    };
  };
  signing.avb.size = 4096;
  variant = "userdebug";
  config.source.dirs."vendor/adevtool".postPatch =
     ''
      echo '
      PRODUCT_SYSTEM_PROPERTIES += ro.adb.secure=1' >> config/mk/google_devices/device/husky/device.mk
    '';
}
