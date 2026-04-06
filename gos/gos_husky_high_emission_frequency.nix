args@{
  config,
  lib,
  ...
}:
{
  options = {
    huskyHighEmissionFrequency = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to add a husky Settings toggle for high emission frequency PWM mode.";
    };
  };

  config = lib.mkIf config.huskyHighEmissionFrequency {
    source.dirs."packages/apps/Settings".patches = [
      ./husky-high-emission-frequency-settings.patch
    ];

    source.dirs."vendor/adevtool".patches = [
      ./husky-high-emission-frequency-adevtool.patch
    ];

    source.dirs."system/sepolicy".patches = [
      ./husky-high-emission-frequency-sepolicy.patch
    ];
  };
}
