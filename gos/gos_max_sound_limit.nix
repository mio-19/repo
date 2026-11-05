args@{
  config,
  lib,
  ...
}:
{
  options = {
    maxSoundLimit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to add ear protection (maximum volume limiter) settings to protect hearing.
        Provides a configurable volume limit slider and headphone-specific enforcement in Settings.
      '';
    };
  };

  config = lib.mkIf config.maxSoundLimit {
    # Downstream changes to GrapheneOS Settings (Apache-2.0):
    # https://github.com/GrapheneOS/platform_packages_apps_Settings
    source.dirs."packages/apps/Settings".patches = [
      ./max-sound-limit-settings.patch
    ];

    # Downstream changes to GrapheneOS frameworks/base (Apache-2.0):
    # https://github.com/GrapheneOS/platform_frameworks_base
    source.dirs."frameworks/base".patches = [
      ./max-sound-limit-frameworks-base.patch
    ];
  };
}
