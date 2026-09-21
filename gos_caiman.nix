args@{
  config,
  pkgs-unfree,
  lib,
  ...
}:
{
  imports = [
    ./gos
  ];
  options = {
    caimanHighEmissionFrequency = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable PWM hack for Caiman";
    };
  };

  config = {
    enableLindroid = false;
    enableDroidspaces = false;
    device = "caiman";
    source.dirs."device/google/caimito-kernels/6.1" = lib.mkForce {
      src =
        let
          src = pkgs-unfree.callPackage ./gos_caimito_kernel.nix {
            inherit (config) enableLindroid enableDroidspaces;
            pwmmode = if config.caimanHighEmissionFrequency then "0x01" else "stock";
          };
        in
        assert src.version == config.grapheneos.release;
        src;
    };
    stateVersion = "3";
  };
}
