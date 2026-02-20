args@{ config, pkgs, lib, ... }:
{
  buildDateTime = 1771157080;
  flavor = "grapheneos";
  device = "husky";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = [
    ./Disable-FLAG_SECURE.patch
    #./No-gestural-navigation-hint-bar.patch
  ];
  # check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1" = lib.mkForce {
    src = pkgs.fetchgit {
      url = "https://github.com/mio-19/device_google_shusky-kernels_6.1.git";
      rev = "d2fb020dd95df3d7ddb216a0d109371250e5f40c";
      hash = "sha256-VqiAWZ8JPMgTtdHpNFB3CFxJ3JtO4PwOQ8YnM3+hcbc=";
      fetchLFS = true;
    };
  };
}
