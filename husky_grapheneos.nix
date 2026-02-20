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
      rev = "ca5c9ade50d99db93d43d72b8702eec2adf849f5";
      hash = "sha256-mtwb/f6NBW9qNvY+De6AwHoMQaCdU/0zTaJ4WiXqo5Q=";
      fetchLFS = true;
    };
  };
  signing.avb.size = 4096;
}
