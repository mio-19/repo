# see log: adb logcat | grep lindroid
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    #  --option extra-substituters https://robotnix.cachix.org --option extra-trusted-public-keys robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0=
    #robotnix.url = "github:nix-community/robotnix";
    robotnix.url = "github:mio-19/robotnix";
    robotnix.inputs.nixpkgs.follows = "nixpkgs";
    robotnix.inputs.androidPkgs.follows = "android-nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # https://github.com/xddxdd/nix-kernelsu-builder
    nix-kernelsu-builder.url = "github:xddxdd/nix-kernelsu-builder";
    nix-kernelsu-builder.inputs.flake-parts.follows = "flake-parts";
    nix-kernelsu-builder.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      robotnix,
      nix-github-actions,
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.nix-kernelsu-builder.flakeModules.default
      ];
      flake =
        let
          # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
          mkRobotnixConfigurations =
            ccache:
            let
              common =
                f:
                args@{ config, ... }:
                {
                  imports = [ f ];
                  ccache.enable = ccache;
                };
            in
            nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
              gta4xlwifi = common ./gta4xlwifi.nix;
              gta4xlwifi23 = common ./gta4xlwifi23.nix;
              enchilada = common ./enchilada.nix;
              enchilada23 = common ./enchilada23.nix;
              nx_tab = common ./nx_tab.nix;
              oriole = common ./oriole.nix;
            };
        in
        {
          githubActions = nix-github-actions.lib.mkGithubMatrix {
            checks.x86_64-linux =
              with nixpkgs.lib;
              (mapAttrs' (name: cfg: nameValuePair "${name}-ota" cfg.ota) self.androidNoCcache)
              // (mapAttrs' (name: cfg: nameValuePair "${name}-img" cfg.img) self.androidNoCcache);
          };
          android = mkRobotnixConfigurations true;
          androidNoCcache = mkRobotnixConfigurations false;
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        args@{ pkgs, ... }:
        let
          sources = (import ./_sources/generated.nix) {
            inherit (pkgs)
              fetchurl
              fetchgit
              fetchFromGitHub
              dockerTools
              ;
          };
        in
        {
          kernelsu =
            let
              oriole14 = {
                anyKernelVariant = "kernelsu";
                clangVersion = "latest";
                kernelDefconfigs = [
                  "gki_defconfig"
                ];
                kernelSU.variant = "next";
                kernelImageName = "Image";
                kernelSrc = sources.oriole-kernel14.src;
              };
              oriole = {
                anyKernelVariant = "kernelsu";
                clangVersion = "latest";
                kernelDefconfigs = [
                  "gki_defconfig"
                ];
                kernelSU.variant = "next";
                kernelImageName = "Image";
                kernelSrc = sources.oriole-kernel.src;
                oemBootImg = pkgs.fetchurl {
                  url = "https://mirrorbits.lineageos.org/full/oriole/20250908/boot.img";
                  sha256 = "1bivg0sn1zs8plcsncv1jpcp81n15xw1hyhq07pfz11wnp8y50hg";
                };
              };
              # currently only compiles on aarch64-linux
              enchilada = {
                kernelMakeFlags = [
                  "KCFLAGS=\"-Wno-error -target aarch64-linux-gnu -march=armv8.2-a+crc -mtune=cortex-a75\""
                  "KCPPFLAGS=\"-Wno-error -target aarch64-linux-gnu -march=armv8.2-a+crc -mtune=cortex-a75\""
                ];
                anyKernelVariant = "osm0sis";
                clangVersion = "latest";
                kernelDefconfigs = [
                  "enchilada_defconfig"
                ];
                kernelSU.variant = "next";
                kernelImageName = "Image";
                kernelSrc = sources.enchilada-kernel.src;
                kernelPatches = [
                  ./filter_count.patch
                  #./0001-CROSS_COMPILE-aarch64-linux-gnu.patch
                  #./0001-CLANG_TARGET_FLAGS-ported-from-android_kernel_samsun.patch
                ];
                oemBootImg = pkgs.fetchurl {
                  url = "https://mirrorbits.lineageos.org/full/enchilada/20250910/boot.img";
                  sha256 = "0d2cxz3jhi54qvlqmfghga621851njjxsldr9w8n1ni4g6g2nslp";
                };
              };
              gta4xlwifi_evobka = mk_gta4xlwifi sources.gta4xlwifi-evobka-kernel.src;
              gta4xlwifi = mk_gta4xlwifi sources.gta4xlwifi-kernel.src // {
                oemBootImg = pkgs.fetchurl {
                  url = "https://mirrorbits.lineageos.org/full/gta4xlwifi/20250906/boot.img";
                  sha256 = "0yzzli36inmbpa5x5rb35qmphi3k0mfnra7v7f7vs9k57dskzfmw";
                };
              };
              mk_gta4xlwifi =
                kernel:
                let
                  s = import ./sources.nix args;
                in
                {
                  # https://github.com/Linux-On-LineageOS/lindroid-drm-loopback/commit/73e732316409ad5b75a5715684d3c2d940d8670b
                  kernelMakeFlags = [
                    "KCFLAGS=\"-Wno-error\""
                    "KCPPFLAGS=\"-Wno-error\""
                  ];
                  anyKernelVariant = "osm0sis";
                  clangVersion = "latest";
                  kernelDefconfigs = [
                    "exynos9611-gta4xlwifi_defconfig"
                  ];
                  kernelSU.variant = "next";
                  kernelImageName = "Image";
                  #susfs.enable = true; # TODO
                  susfs.src = sources.susfs414.src;
                  kernelSrc = (
                    pkgs.runCommand "gta4xlwifi-patched-kernel" { } ''
                      cp -r ${kernel} $out
                      chmod -R +w $out
                      cp -r ${s.lindroid-drm} $out/drivers/lindroid-drm

                      # https://kernelsu.org/guide/how-to-integrate-for-non-gki.html
                      echo '
                      CONFIG_SYSVIPC=y
                      CONFIG_UTS_NS=y
                      CONFIG_PID_NS=y
                      CONFIG_IPC_NS=y
                      CONFIG_USER_NS=y
                      CONFIG_NET_NS=y
                      CONFIG_CGROUP_DEVICE=y
                      CONFIG_CGROUP_FREEZER=y
                      CONFIG_DRM=y
                      CONFIG_DRM_LINDROID_EVDI=y

                      CONFIG_KSU_KPROBES_HOOK=n
                      CONFIG_KPROBES=n
                      ' >> $out/arch/arm64/configs/exynos9611-gta4xlwifi_defconfig
                      sed -i "/endmenu/i\source \"drivers/lindroid-drm/Kconfig\"" $out/drivers/Kconfig
                      echo 'obj-y += lindroid-drm/' >> $out/drivers/Makefile
                    ''
                  );
                  kernelPatches = [
                    ./filter_count.patch
                    ./overlayfs.patch
                    ./0001-KSUManual4.14.patch
                    ./0001-we-don-t-have-linux-msm_drm_notify.h.patch
                    ./daria.patch
                  ];
                };
            in
            {
              oriole14 = oriole14;
              oriole = oriole;
              enchilada = enchilada;
              gta4xlwifi = gta4xlwifi;
              gta4xlwifi_evobka = gta4xlwifi_evobka;
            };
        };
    };
}
