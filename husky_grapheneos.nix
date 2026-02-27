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
    # pixel8pro-stock.patch pixel8pro-stock-fix-attempt3.patch lindroid-partial-b4 lindroid-common ksu105
    src = pkgs.fetchFromGitHub {
      owner = "forked-by-mio";
      repo = "device_google_shusky-kernels_6.1";
      rev = "0f62c1d9450887936edc9e9be27fc8fcf3b59a5f";
      hash = "sha256-KqzOxnHAEvEEPWSxEG1OMSe03Wj2MSIKhF1NEdTlOlU=";
    };
  };
  signing.avb.size = 4096;
  stateVersion = "3";
}
