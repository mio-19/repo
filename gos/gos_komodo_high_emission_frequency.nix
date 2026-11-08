args@{
  config,
  lib,
  ...
}:
{
  options = {
    komodoHighEmissionFrequency = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to add a Pixel 9 Pro XL (komodo) experimental PWM mode control which resets to stock on every boot.";
    };
  };

  # Downstream device integration for GrapheneOS adevtool (Apache-2.0):
  # https://github.com/GrapheneOS/adevtool
  config = lib.mkIf (config.komodoHighEmissionFrequency && config.caimanHighEmissionFrequency) {
    source.dirs."packages/apps/Settings".patches = [
      ./komodo-high-emission-frequency-settings.patch
    ];

    source.dirs."vendor/adevtool".patches = [
      ./komodo-high-emission-frequency-adevtool.patch
    ];

    source.dirs."system/sepolicy".patches = [
      ./komodo-high-emission-frequency-sepolicy.patch
    ];
  };
}
