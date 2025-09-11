# see log: adb logcat | grep lindroid
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nix-github-actions.url = "github:nix-community/nix-github-actions";
  inputs.nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
  inputs.robotnix.url = "github:nix-community/robotnix";

  outputs =
    {
      self,
      robotnix,
      nix-github-actions,
      nixpkgs,
      ...
    }:
    {
      githubActions = nix-github-actions.lib.mkGithubMatrix { checks = self.robotnixConfigurations; };
      # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
      robotnixConfigurations = nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
        gta4xlwifi = (
          args@{ config, pkgs, ... }:
          {
            buildDateTime = 1757560291;
            imports = [ ./common.nix ];
            manufactor = "samsung";
            kernel-short = "gta4xl";
            defconfig = "arch/arm64/configs/exynos9611-gta4xlwifi_defconfig";
            legacy = true;
            ksu = false; # buggy
            patch-daria = true;
            patch-overlayfs = true;
            device = "gta4xlwifi";
            flavorVersion = "22.2";
          }
        );
        enchilada = (
          args@{ config, pkgs, ... }:
          {
            buildDateTime = 1757560291;
            imports = [ ./common.nix ];
            manufactor = "oneplus";
            kernel-short = "sdm845";
            defconfig = "arch/arm64/configs/enchilada_defconfig";
            device = "enchilada";
            flavorVersion = "22.2";
            #flavorVersion = "23.0";
          }
        );
        nx_tab = (
          args@{ config, pkgs, ... }:
          {
            buildDateTime = 1757560291;
            imports = [ ./common.nix ];
            manufactor = "nintendo";
            device-name = "nx";
            kernel-name = "nvidia/kernel-4.9-nx";
            defconfig = "arch/arm64/configs/tegra_android_defconfig";
            lindroid = false;
            legacy = true;
            # ksu doesn't compile
            #In file included from ../../../../../../kernel/nvidia/kernel-4.9-nx/drivers/kernelsu/throne_tracker.c:1:
            #../../../../../../kernel/nvidia/kernel-4.9-nx/drivers/kernelsu/throne_tracker.c: In function ‘track_throne’:
            #../../../../../../kernel/nvidia/kernel-4.9-nx/include/linux/err.h:30:9: error: ‘fp’ may be used uninitialized in this function [-Werror=maybe-uninitialized]
            #   30 |  return (long) ptr;
            #      |         ^~~~~~~~~~
            #../../../../../../kernel/nvidia/kernel-4.9-nx/drivers/kernelsu/throne_tracker.c:356:15: note: ‘fp’ was declared here
            #  356 |  struct file *fp;
            #      |               ^~
            #../../../../../../kernel/nvidia/kernel-4.9-nx/drivers/kernelsu/throne_tracker.c: At top level:
            #cc1: error: unrecognized command line option ‘-Wno-gcc-compat’ [-Werror]
            #cc1: all warnings being treated as errors
            ksu = false;
            device = "nx_tab";
            flavorVersion = "22.2";
          }
        );
      };
    };
}
