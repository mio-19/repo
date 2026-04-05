args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    enableUserDebug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable UserDebug";
    };
  };
  config = lib.mkIf config.enableUserDebug {
    variant = "userdebug";
    # Making userdebug builds with ro.adb.secure=1 to have root access via ADB with the rest of the security model intact is officially supported by GrapheneOS. Using Magisk massively rolls back the OS security model and is strongly discouraged. Using ADB on a production device isn't recommended with or without root, but it's officially supported if you want to do it. If you only grant ADB access to the computer you use for building and signing the OS, it's not a big deal. You need to be aware that you need to heavily secure that computer and shouldn't use it for anything else though. https://news.ycombinator.com/item?id=40250160
    source.dirs."vendor/adevtool".postPatch = ''
      for f in config/mk/google_devices/device/*/device.mk; do
      echo '
      PRODUCT_SYSTEM_PROPERTIES += ro.adb.secure=1' >> "$f"
      done
    '';
  };
}
