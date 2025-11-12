{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    #  --option extra-substituters https://robotnix.cachix.org --option extra-trusted-public-keys robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0=
    #robotnix.url = "github:nix-community/robotnix/signing-unfuck";
    #robotnix.url = "git+https://github.com/nix-community/robotnix.git";
    robotnix.url = "github:mio-19/robotnix";
    robotnix.inputs.nixpkgs.follows = "nixpkgs-stable";
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
          mkGos =
            { ccache, sign }:
            let
              common =
                f:
                args@{ config, ... }:
                {
                  imports = [ f ];
                  ccache.enable = ccache;
                  signing.enable = sign;
                  signing.keyStorePath = "/home/user/Documents/repo/keys";
                };
            in
            # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
            nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
              akita = common ./akita_grapheneos.nix;
            };
          mkLos =
            { ccache, sign }:
            let
              common =
                f:
                args@{ config, ... }:
                {
                  imports = [ f ];
                  ccache.enable = ccache;
                  signing.enable = sign;
                  signing.keyStorePath = "/home/user/Documents/repo/keys";
                };
            in
            # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
            nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
              gta4xlwifi = common ./gta4xlwifi.nix;
              enchilada = common ./enchilada.nix;
              nx_tab = common ./nx_tab.nix;
              akita = common ./akita.nix;
            };
        in
        {
          githubActions = nix-github-actions.lib.mkGithubMatrix {
            checks.x86_64-linux =
              with nixpkgs.lib;
              (mapAttrs' (name: cfg: nameValuePair "${name}-ota" cfg.ota) self.losNoCcache)
              // (mapAttrs' (name: cfg: nameValuePair "${name}-img" cfg.img) self.losNoCcache);
          };
          los = mkLos {
            ccache = true;
            sign = false;
          };
          gos = mkGos {
            ccache = true;
            sign = false;
          };
          losNoCcache = mkLos {
            ccache = true;
            sign = false;
          };
          losSign = mkLos {
            ccache = true;
            sign = true;
          };
          gosSign = mkGos {
            ccache = true;
            sign = true;
          };
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
                kernelSU.enable = false; # can compile but not working
                kernelSU.variant = "next";
                kernelImageName = "Image";
                kernelSrc = sources.enchilada-kernel.src;
                #kernelConfig = ''
                #  CONFIG_KSU_KPROBES_HOOK=n
                #  CONFIG_KPROBES=n
                #'';
                kernelPatches = [
                  ./filter_count.patch
                  #./0001-KSUManual4.9.patch
                  #./0001-CROSS_COMPILE-aarch64-linux-gnu.patch
                  #./0001-CLANG_TARGET_FLAGS-ported-from-android_kernel_samsun.patch
                ];
                /*
                  oemBootImg = pkgs.fetchurl {
                    # https://download.lineageos.org/devices/enchilada/builds
                    url = "https://mirrorbits.lineageos.org/full/enchilada/20251001/boot.img";
                    sha256 = "1450v8sx3fzgl4v4qfdq164c7k2dd8pam4p3ly7zfzqs2s93his7";
                  };
                */
              };
              gta4xlwifi_evobka = mk_gta4xlwifi sources.gta4xlwifi-evobka-kernel.src;
              gta4xlwifi = mk_gta4xlwifi sources.gta4xlwifi23-kernel.src // {
                oemBootImg = pkgs.fetchurl {
                  # https://download.lineageos.org/devices/gta4xlwifi/builds
                  url = "https://mirrorbits.lineageos.org/full/gta4xlwifi/20251025/boot.img";
                  sha256 = "1wgna0xxz216hr7zdj19sg2dvx3xfw3279rv4x881j7hgday97iq";
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
                  kernelConfig = ''
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
                  '';
                  kernelSrc = kernel;
                  postPatch = ''
                    cp -r ${s.lindroid-drm} ./drivers/lindroid-drm

                    sed -i "/endmenu/i\source \"drivers/lindroid-drm/Kconfig\"" ./drivers/Kconfig
                    echo 'obj-y += lindroid-drm/' >> ./drivers/Makefile
                  '';
                  kernelPatches = [
                    ./filter_count.patch
                    ./overlayfs.patch
                    ./0001-KSUManual4.14.patch
                    ./0001-we-don-t-have-linux-msm_drm_notify.h.patch
                    ./daria.patch
                    ./0001-drop-master-lindroid-patch.patch
                  ];
                };
            in
            {
              enchilada = enchilada;
              gta4xlwifi = gta4xlwifi;
              gta4xlwifi_evobka = gta4xlwifi_evobka;
            };
        };
    };
}
