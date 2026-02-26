args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./gos.nix
    ./gos_lindroid.nix
    #./gos_userdebug.nix
  ];
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    # pixel8pro-stock.patch pixel8pro-stock-fix-attempt3.patch lindroid-partial-b1 0ac686b9e81ba331c2ad9b420fd21262a80daaa4.patch  3dcc884c689681dda2d9ad24a9e219013f70cfe8.patch a72032ecf33c63d8a4abb64b08c1a0b847c82a32.patch
    src = pkgs.fetchFromGitHub {
      owner = "forked-by-mio";
      repo = "device_google_shusky-kernels_6.1";
      rev = "b2bb2a6c2599e6e135c7f7b789445c4a82d4d2d7";
      hash = "sha256-U7mbrbd5nRmb8Arfs40XTjaUg0RQXb1jYZbb8pgoq0o=";
    };
  };
  signing.avb.size = 4096;
  stateVersion = "3";
}
