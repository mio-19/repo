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
    ./gos_userdebug.nix
  ];
  device = "husky";
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    src = pkgs.fetchFromGitHub {
      # pixel8pro-stock-3840Hz.patch pixel8pro-stock-fix-attempt3.patch lindroid-partial6 0ac686b9e81ba331c2ad9b420fd21262a80daaa4.patch  3dcc884c689681dda2d9ad24a9e219013f70cfe8.patch a72032ecf33c63d8a4abb64b08c1a0b847c82a32.patch
      owner = "forked-by-mio";
      repo = "device_google_shusky-kernels_6.1";
      rev = "d8ff200e30079bfc5bb1f0dfc39c2da680d0a258";
      hash = "sha256-Gug1bBXnwob4uXKt1t5TrA3/FFgaOCAHYvhnzIi5hIc=";
    };
  };
  signing.avb.size = 4096;
}
