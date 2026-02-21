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
    src = pkgs.fetchFromGitHub {
      owner = "mio-19";
      repo = "device_google_shusky-kernels_6.1";
      # pixel8pro-stock-3840Hz.patch;pixel8pro-stock-fix-attempt3.patch;pixel8pro-lindroid.patch
      rev = "86a6dd1fb698984abfbb4ec8834f789b2bdc3167";
      hash = "sha256-VLtT63ZzTkujVlOo31KkdXyFLrK/FAVleEtBwhUG8UY=";
      #fetchLFS = true; # no need for fetchFromGitHub, right?
    };
  };
  signing.avb.size = 4096;
  variant = "userdebug";
  # Making userdebug builds with ro.adb.secure=1 to have root access via ADB with the rest of the security model intact is officially supported by GrapheneOS. Using Magisk massively rolls back the OS security model and is strongly discouraged. Using ADB on a production device isn't recommended with or without root, but it's officially supported if you want to do it. If you only grant ADB access to the computer you use for building and signing the OS, it's not a big deal. You need to be aware that you need to heavily secure that computer and shouldn't use it for anything else though. https://news.ycombinator.com/item?id=40250160
  source.dirs."vendor/adevtool".postPatch = ''
    echo '
    PRODUCT_SYSTEM_PROPERTIES += ro.adb.secure=1' >> config/mk/google_devices/device/husky/device.mk
    sed -i '/vendor\/adevtool\/config\/mk\/google_devices\/platform\/zuma\/product-common\.mk/a $(call inherit-product, vendor/lindroid/lindroid.mk)' config/mk/google_devices/device/husky/device.mk
  '';
  source.dirs."vendor/adevtool".patches = [
    ./0001-husky-increase-default-zram-and-writeback-sizes.patch
  ];
  # lindroid:
  source.dirs."frameworks/native".patches = [ ./inputflinger.patch ];
  # to fix soft reboot when starting container on A14 (temporary!!! workaround) https://t.me/linux_on_droid/10346
  source.dirs."frameworks/base".patches = [
    ./16qpr2-Ignore-uevent-s-with-null-name-for-Extcon-WiredAcces.patch
  ];
  source.dirs."vendor/lindroid" = {
    src = pkgs.fetchFromGitHub {
      # lindroid-22.1
      owner = "Linux-on-droid";
      repo = "vendor_lindroid";
      rev = "279f7f4dca7fdae757be74febd5bf7630f416737";
      hash = "sha256-mZowr9x1wKeJC956bl095HtAK/2t7NHMuC0+QXCQRpM=";
    };
    # https://t.me/linux_on_droid/18552
    postPatch = ''
      sed -i 's|android.hardware.graphics.common-V5|android.hardware.graphics.common-V7|' interfaces/composer/Android.bp
    '';
  };
  source.dirs."external/lxc".src = pkgs.fetchFromGitHub {
    owner = "Linux-on-droid";
    repo = "external_lxc";
    # lindroid-21
    rev = "4e3a3630fff3dc04e0d4a761309f87f248e40b17";
    sha256 = "1c993880v9sv97paqkqxd4c9p6j1v8m6d1b2sjwhav3f3l9dh7wn";
  };
  source.dirs."libhybris".src = pkgs.fetchFromGitHub {
    owner = "Linux-on-droid";
    repo = "libhybris";
    # lindroid-21
    rev = "419f3ff6736e01cb0e579f65a34c85cfa7de578b";
    sha256 = "1hp69929yrhql2qc4scd4fdvy5zv8g653zvx376c3nlrzckjdm47";
  };
}
