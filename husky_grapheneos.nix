args@{
  config,
  pkgs,
  lib,
  ...
}:
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
  # Making userdebug builds with ro.adb.secure=1 to have root access via ADB with the rest of the security model intact is officially supported by GrapheneOS. Using Magisk massively rolls back the OS security model and is strongly discouraged. Using ADB on a production device isn't recommended with or without root, but it's officially supported if you want to do it. If you only grant ADB access to the computer you use for building and signing the OS, it's not a big deal. You need to be aware that you need to heavily secure that computer and shouldn't use it for anything else though. https://news.ycombinator.com/item?id=40250160
  source.dirs."vendor/adevtool".postPatch = ''
    echo '
    PRODUCT_SYSTEM_PROPERTIES += ro.adb.secure=1
    $(call inherit-product, vendor/lindroid/lindroid.mk)' >> config/mk/google_devices/device/husky/device.mk
  '';
  # lindroid:
  source.dirs."frameworks/native".patches = [ ./inputflinger.patch ];
  # to fix soft reboot when starting container on A14 (temporary!!! workaround) https://t.me/linux_on_droid/10346
  source.dirs."frameworks/base".patches = [
    ./16qpr2-Ignore-uevent-s-with-null-name-for-Extcon-WiredAcces.patch
  ];
  source.dirs."vendor/lindroid" = {
    src = pkgs.fetchgit {
      # lindroid-22.1
      url = "https://github.com/Linux-on-droid/vendor_lindroid.git";
      rev = "279f7f4dca7fdae757be74febd5bf7630f416737";
      hash = "sha256-mZowr9x1wKeJC956bl095HtAK/2t7NHMuC0+QXCQRpM=";
    };
    # https://t.me/linux_on_droid/18552
    postPatch = ''
      sed -i 's|android.hardware.graphics.common-V5|android.hardware.graphics.common-V6|' interfaces/composer/Android.bp
    '';
  };
  source.dirs."external/lxc".src = pkgs.fetchgit {
    url = "https://github.com/Linux-on-droid/external_lxc.git";
    # lindroid-21
    rev = "4e3a3630fff3dc04e0d4a761309f87f248e40b17";
    sha256 = "1c993880v9sv97paqkqxd4c9p6j1v8m6d1b2sjwhav3f3l9dh7wn";
  };
  source.dirs."libhybris".src = pkgs.fetchgit {
    url = "https://github.com/Linux-on-droid/libhybris.git";
    # lindroid-21
    rev = "419f3ff6736e01cb0e579f65a34c85cfa7de578b";
    sha256 = "1hp69929yrhql2qc4scd4fdvy5zv8g653zvx376c3nlrzckjdm47";
  };
}
