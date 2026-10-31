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
      description = "Whether to add a Pixel 9 Pro XL (komodo) Settings control for the high emission frequency PWM threshold.";
    };
  };

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
