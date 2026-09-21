args@{
  pkgs-unfree,
  lib,
  config,
  ...
}:
{
  imports = [
    ./gos
  ];
  options = {
    mustangHighEmissionFrequency = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable PWM hack for Mustang and Pixel 10 family";
    };
  };
  config = {
    device = "mustang";
    source.dirs."device/google/laguna-kernels/6.6" = lib.mkForce {
      src =
        let
          src = pkgs-unfree.callPackage ./gos_mustang_kernel.nix {
            pwmmode = if config.mustangHighEmissionFrequency then "0x01" else "stock";
          };
        in
        assert src.version == config.grapheneos.release;
        src;
    };
    signing.avb.size = 4096;
    stateVersion = "3";
  };
}
