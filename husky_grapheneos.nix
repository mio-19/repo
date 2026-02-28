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
    # pixel8pro-stock.patch pixel8pro-stock-fix-attempt3.patch lindroid ksu105 0001-daria.patch sidharth-hack.patch
    src = pkgs.fetchFromGitHub {
      owner = "forked-by-mio";
      repo = "device_google_shusky-kernels_6.1";
      rev = "a076e8fb7804fcff1cb8efefe50b4aa2d8c4610c";
      hash = "sha256-Bkoe2sgLA5MXO7ZxkqKy0C6vYnIYGL7D7qWlsKT6ZPI=";
    };
  };
  signing.avb.size = 4096;
  stateVersion = "2";
}
