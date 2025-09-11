# see log: adb logcat | grep lindroid
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nix-github-actions.url = "github:nix-community/nix-github-actions";
  inputs.nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
  #  --option extra-substituters https://robotnix.cachix.org --option extra-trusted-public-keys robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0=
  inputs.robotnix.url = "github:nix-community/robotnix";

  outputs =
    {
      self,
      robotnix,
      nix-github-actions,
      nixpkgs,
      ...
    }:
    let
      # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
      mkRobotnixConfigurations =
        ccache:
        nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
          gta4xlwifi = (
            args@{ config, pkgs, ... }:
            {
              ccache.enable = ccache;
              buildDateTime = 1757560291;
              imports = [ ./common.nix ];
              manufactor = "samsung";
              kernel-short = "gta4xl";
              defconfig = "arch/arm64/configs/exynos9611-gta4xlwifi_defconfig";
              legacy414 = true;
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
              ccache.enable = ccache;
              buildDateTime = 1757560291;
              imports = [ ./common.nix ];
              manufactor = "oneplus";
              kernel-short = "sdm845";
              defconfig = "arch/arm64/configs/enchilada_defconfig";
              device = "enchilada";
              flavorVersion = "22.2";
              #flavorVersion = "23.0";
              legacy414 = true;
              lindroid-drm = false; # /build/kernel/oneplus/sdm845/drivers/lindroid-drm/evdi_modeset.c:35:10: fatal error: 'drm/drm_gem_framebuffer_helper.h' file not found
            }
          );
          nx_tab = (
            args@{ config, pkgs, ... }:
            {
              ccache.enable = ccache;
              buildDateTime = 1757560291;
              imports = [ ./common.nix ];
              manufactor = "nintendo";
              device-name = "nx";
              kernel-name = "nvidia/kernel-4.9-nx";
              defconfig = "arch/arm64/configs/tegra_android_defconfig";
              lindroid = false;
              legacy414 = true;
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
    in
    {
      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks.x86_64-linux =
          with nixpkgs.lib;
          (mapAttrs' (name: cfg: nameValuePair "${name}-ota" cfg.ota) self.robotnixConfigurationsNoCcache)
          // (mapAttrs' (name: cfg: nameValuePair "${name}-img" cfg.img) self.robotnixConfigurationsNoCcache);
      };
      robotnixConfigurations = mkRobotnixConfigurations true;
      robotnixConfigurationsNoCcache = mkRobotnixConfigurations false;
    };
}
