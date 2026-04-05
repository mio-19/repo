args@{
  config,
  lib,
  ...
}:
{
  options = {
    allowAdbWirelessWithoutWifi = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to allow enabling wireless debugging without an active Wi-Fi connection.";
    };
  };

  config = lib.mkIf config.allowAdbWirelessWithoutWifi {
    source.dirs."packages/apps/Settings".patches = [
      ./wireless-debugging-without-wifi-settings.patch
    ];

    source.dirs."frameworks/base".patches = [
      ./wireless-debugging-without-wifi-frameworks-base.patch
    ];
  };
}
