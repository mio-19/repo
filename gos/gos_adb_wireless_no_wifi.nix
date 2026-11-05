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
      description = ''
        Whether to allow wireless debugging without Wi-Fi. When no Wi-Fi network
        is available, Settings shows 127.0.0.1 and the active ADB TLS port for
        on-device clients such as Termux.
      '';
    };
  };

  config = lib.mkIf config.allowAdbWirelessWithoutWifi {
    # Downstream changes to GrapheneOS Settings (Apache-2.0):
    # https://github.com/GrapheneOS/platform_packages_apps_Settings
    source.dirs."packages/apps/Settings".patches = [
      ./wireless-debugging-without-wifi-settings.patch
    ];

    # Downstream changes to GrapheneOS frameworks/base (Apache-2.0):
    # https://github.com/GrapheneOS/platform_frameworks_base
    source.dirs."frameworks/base".patches = [
      ./wireless-debugging-without-wifi-frameworks-base.patch
    ];
  };
}
