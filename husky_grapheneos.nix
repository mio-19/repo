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
    # pixel8pro-stock.patch pixel8pro-stock-fix-attempt3.patch lindroid-partial-b4 ksu lindroid-common
    src = pkgs.fetchFromGitHub {
      owner = "forked-by-mio";
      repo = "device_google_shusky-kernels_6.1";
      rev = "4dd74c3938feabc24c9df94e798229c773ee7274";
      hash = "sha256-/D6z6sVf7U8Hp7AxIpVXrQ2Dnl5bGrlDQMDgdp8lm0I=";
    };
  };
  signing.avb.size = 4096;
  stateVersion = "3";
}
