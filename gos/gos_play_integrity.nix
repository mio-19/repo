args@{
  config,
  lib,
  ...
}:
{
  options = {
    playIntegritySpoofing = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable ROM-native Play Integrity and hardware attestation spoofing via custom keybox.";
    };
  };

  config = lib.mkIf config.playIntegritySpoofing {
    source.dirs."frameworks/base".patches = [
      ./play-integrity-frameworks-base.patch
    ];

    source.dirs."packages/apps/Settings".patches = [
      ./play-integrity-settings.patch
    ];
  };
}
