args@{ config, pkgs, ... }:
{
  buildDateTime = 1771157080;
  flavor = "grapheneos";
  device = "husky";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = [
    ./Disable-FLAG_SECURE.patch
    #./No-gestural-navigation-hint-bar.patch
  ];
  # this is enough to override. check in nix repl (import ./.).gosSign.husky.config.source.dirs."device/google/shusky-kernels/6.1"
  source.dirs."device/google/shusky-kernels/6.1".src = pkgs.fetchgit {
    url = "https://github.com/mio-19/device_google_shusky-kernels_6.1.git";
    rev = "4f21c869fb7aabd8e1e500ab64bd2919ba39e90a";
    hash = "sha256-JjwWMnJAXVEl586CxUns229v59geql8aJZns1d9I7ZY=";
    fetchLFS = true;
  };
}
