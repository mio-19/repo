args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  source.dirs."bootable/recovery" = lib.mkForce {
    src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_bootable_recovery";
      rev = "833e2948bfe4bbfbf73796391a9336850108e7bd";
      hash = "sha256-QFrwYPZ6Vt/KoUaHWd7w72KB7s4SeYQ2xFoymgi7JeE=";
    };
  };
  source.dirs."build/soong".patches = with pkgs; [
    # required for export_cflags
    (fetchpatch {
      name = "soong: Add equivalent for LOCAL_EXPORT_CFLAGS";
      url = "https://github.com/LineageOS/android_build_soong/commit/25aa912a6cadab1f47753c719b05c6596022c5f8.patch";
      hash = "sha256-o+nQlmA8RoVRxrSYqSJoJQh725RVJLp5J9SUILX0bHA=";
    })
  ];
}
