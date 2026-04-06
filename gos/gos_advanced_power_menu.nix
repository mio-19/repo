args@{
  config,
  lib,
  ...
}:
{
  options = {
    advancedPowerMenu = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable LineageOS advanced power menu restart options.";
    };
  };

  config = lib.mkIf config.advancedPowerMenu {
    source.dirs."frameworks/base".patches = [
      # Downloaded from:
      # https://github.com/LineageOS/android_frameworks_base/commit/efade7e0bf3d1ca2815895c16e7e64935f63b0bc.patch
      ./advanced-power-menu.patch
    ];
  };
}
