args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./gos.nix
    ./gos_lindroid.nix
  ];
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    /*
      src = pkgs.fetchFromGitHub {
        owner = "mio-19";
        repo = "device_google_shusky-kernels_6.1";
        # pixel8pro-stock.patch;pixel8pro-stock-fix-attempt3.patch
        rev = "ec4f5cfd31f0f61309ba2bebcd02ae8b9420c0aa";
        hash = "sha256-t+0OIx9l+/HwTMN3yxCd2LyYdJREPhGu+RbAYM8mCXE";
      };
    */
    src = pkgs.fetchFromGitHub {
      # pixel8pro-stock-3840Hz.patch pixel8pro-stock-fix-attempt3.patch lindroid-partial5 0ac686b9e81ba331c2ad9b420fd21262a80daaa4.patch  3dcc884c689681dda2d9ad24a9e219013f70cfe8.patch a72032ecf33c63d8a4abb64b08c1a0b847c82a32.patch
      owner = "forked-by-mio";
      repo = "device_google_shusky-kernels_6.1";
      rev = "1b067623ef23c5cd711b313960f308d78ea5e9fd";
      hash = "sha256-d6vyvG4mxsoY46U5MK3OjB/wFxfI+/6QVhm0fjqaDW8=";
    };
  };
  signing.avb.size = 4096;
  /*
    variant = "userdebug";
    # Making userdebug builds with ro.adb.secure=1 to have root access via ADB with the rest of the security model intact is officially supported by GrapheneOS. Using Magisk massively rolls back the OS security model and is strongly discouraged. Using ADB on a production device isn't recommended with or without root, but it's officially supported if you want to do it. If you only grant ADB access to the computer you use for building and signing the OS, it's not a big deal. You need to be aware that you need to heavily secure that computer and shouldn't use it for anything else though. https://news.ycombinator.com/item?id=40250160
    source.dirs."vendor/adevtool".postPatch = ''
      set -e
      [ -f config/mk/google_devices/device/husky/device.mk ]
      echo '
      PRODUCT_SYSTEM_PROPERTIES += ro.adb.secure=1' >> config/mk/google_devices/device/husky/device.mk
    '';
  */

  source.dirs."system/sepolicy".patches = [
    #./port-su-to-user-builds.patch # not working, needs more work
  ];
}
