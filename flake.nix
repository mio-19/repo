{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-25.05";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    #  --option extra-substituters https://robotnix.cachix.org --option extra-trusted-public-keys robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0=
    #robotnix.url = "git+https://github.com/nix-community/robotnix.git?shallow=1";
    #robotnix.url = "github:nix-community/robotnix/grapheneos_2026-02-14";
    robotnix.url = "github:mio-19/robotnix";
    robotnix.inputs.nixpkgs.follows = "nixpkgs-stable";
    robotnix.inputs.androidPkgs.follows = "android-nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # https://github.com/xddxdd/nix-kernelsu-builder
    nix-kernelsu-builder.url = "github:xddxdd/nix-kernelsu-builder/cc0fce340e330ad07331692b7c3673d9974be377";
    nix-kernelsu-builder.inputs.flake-parts.follows = "flake-parts";
    nix-kernelsu-builder.inputs.nixpkgs.follows = "nixpkgs";
    # --option extra-substituters https://nixos-apple-silicon.cachix.org --option extra-trusted-public-keys nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20=
    nixos-apple-silicon = {
      #url = "github:nix-community/nixos-apple-silicon";
      # merged with https://github.com/nix-community/nixos-apple-silicon/pull/353
      #url = "github:mio-19/nixos-apple-silicon";
      # https://github.com/nix-community/nixos-apple-silicon/issues/384
      url = "github:mio-19/nixos-apple-silicon/mio-release-2025-08-23";
      #inputs.nixpkgs.follows = "nixpkgs"; # needs to comment out this to use binary cache
    };
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
    openwrt-imagebuilder = {
      url = "github:astro/nix-openwrt-imagebuilder";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    {
      self,
      robotnix,
      nix-github-actions,
      nixpkgs,
      flake-parts,
      openwrt-imagebuilder,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.nix-kernelsu-builder.flakeModules.default
      ];
      flake =
        let
          mkGos =
            { ccache }:
            let
              common =
                f:
                args@{ config, pkgs, ... }:
                {
                  _module.args.pkgs-unstable = import nixpkgs {
                    system = pkgs.stdenv.hostPlatform.system;
                    config.allowUnfree = true;
                  };
                  _module.args.self = self;
                  imports = [ f ];
                  ccache.enable = ccache;
                };
            in
            # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
            nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
              akita = common ./akita_grapheneos.nix;
              husky = common ./husky_grapheneos.nix;
              mustang = common ./mustang_grapheneos.nix;
              tangorpro = common ./tangorpro_grapheneos.nix;
            };
          mkLos =
            { ccache }:
            let
              common =
                f:
                args@{ config, pkgs, ... }:
                {
                  _module.args.pkgs-unstable = import nixpkgs {
                    system = pkgs.stdenv.hostPlatform.system;
                    config.allowUnfree = true;
                  };
                  _module.args.self = self;
                  imports = [ f ];
                  ccache.enable = ccache;
                };
            in
            # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
            nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
              gta4xlwifi = common ./gta4xlwifi.nix;
              enchilada = common ./enchilada.nix;
              enchilada_mainline = common ./enchilada-mainline.nix;
              nx_tab = common ./nx_tab.nix;
              utm = common ./utm.nix;
              akita = common ./akita.nix;
              "dm3q-kenzie" = common ./dm3q-kenzie.nix;
              dm3q_cola2261 = common ./dm3q-cola2261.nix;
              gts9wifi = common ./gts9wifi.nix;
              gts7lwifi = common ./gts7lwifi.nix;
              gts7l = common ./gts7l.nix;
            };
        in
        {
          packages.x86_64-linux.flient2 =
            let
              pkgs = nixpkgs.legacyPackages.x86_64-linux;

              profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; };

              config = profiles.identifyProfile "glinet_gl-mt6000" // {
                # add package to include in the image, ie. packages that you don't
                # want to install manually later
                packages = [
                  "tmux"
                  "curl"
                  "nano"
                  "diffutils"
                  "tailscale"
                  "luci-app-aria2"
                  "luci-app-irqbalance"
                  "luci-app-https-dns-proxy"
                  "docker"
                  "dockerd"
                  "luci-app-dockerman"
                  "shadow"
                ];

                disabledServices = [ ];

                # include files in the images.
                # to set UCI configuration, create a uci-defauts scripts as per
                # official OpenWRT ImageBuilder recommendation.
                files = pkgs.runCommand "image-files" { } "";
              };

            in
            openwrt-imagebuilder.lib.build config;
          githubActions = nix-github-actions.lib.mkGithubMatrix {
            checks.x86_64-linux =
              with nixpkgs.lib;
              (mapAttrs' (name: cfg: nameValuePair "${name}-ota" cfg.ota) losNoCcache)
              // (mapAttrs' (name: cfg: nameValuePair "${name}-img" cfg.img) losNoCcache);
          };
          los = mkLos {
            ccache = true;
          };
          gos = mkGos {
            ccache = true;
          };
          gosNoCcache = mkGos {
            ccache = false;
          };
          losNoCcache = mkLos {
            ccache = false;
          };
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        args@{ pkgs, system, ... }:
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
          # https://github.com/nix-community/nixos-apple-silicon/pull/353
          packages.zfs-installer =
            (nixpkgs.lib.nixosSystem {
              inherit system;
              pkgs = import nixpkgs {
                crossSystem.system = "aarch64-linux";
                localSystem.system = system;
                overlays = [ inputs.nixos-apple-silicon.overlays.default ];
              };
              modules = [
                inputs.nixos-apple-silicon.outputs.nixosModules.apple-silicon-installer
                {
                  hardware.asahi.pkgsSystem = system;
                  nixpkgs.hostPlatform.system = "aarch64-linux";
                  nixpkgs.buildPlatform.system = system;
                }
                (
                  { pkgs, ... }:
                  {
                    boot.supportedFilesystems.zfs = true;
                    networking.hostId = "AAAAAAAA";
                    environment.systemPackages = with pkgs; [
                      git
                      rsync
                    ];
                  }
                )
              ];
            }).config.system.build.isoImage;
          packages.grapheneos-husky-kernel = pkgs.callPackage ./grapheneos_husky_kernel.nix { };
          packages.grapheneos-mustang-kernel = pkgs.callPackage ./grapheneos_mustang_kernel.nix { };
          packages.grapheneos-tangorpro-kernel = pkgs.callPackage ./grapheneos_tangorpro_kernel.nix { };
          packages.grapheneos-camera = pkgs.callPackage ./grapheneos_camera_app.nix { };
          packages.grapheneos-info = pkgs.callPackage ./grapheneos_info_app.nix { };
          # followings are for garnix:
          packages.grapheneos-husky-key-script = self.gosNoCcache.husky.generateKeysScript;
          packages.grapheneos-husky-factory-img = self.gosNoCcache.husky.factoryImg;
          packages.grapheneos-tangorpro-key-script = self.gosNoCcache.tangorpro.generateKeysScript;
          packages.grapheneos-tangorpro-factory-img = self.gosNoCcache.tangorpro.factoryImg;
          packages.los-gts7lwifi-ota = self.losNoCcache.gts7lwifi.ota;
          packages.los-gts7l-ota = self.losNoCcache.gts7l.ota;
          packages.los-enchilada-img = self.losNoCcache.enchilada.img;
          packages.los-utm-img = self.losNoCcache.utm.img;
          /*
            packages.grapheneos-husky-srcs = self.gos.husky.config.build.android.overrideAttrs (old: {
              buildPhase = "";
              installPhase = ''
                mkdir $out
                cp -r . $out/
              '';
            });
          */
          kernelsu =
            let
              gts7l_robotnix = robotnix.lib.robotnixSystem {
                inherit (self.los.gts7l.config)
                  flavor
                  device
                  flavorVersion
                  stateVersion
                  ;
              };
              gts7lwifi_robotnix = robotnix.lib.robotnixSystem {
                inherit (self.los.gts7lwifi.config)
                  flavor
                  device
                  flavorVersion
                  stateVersion
                  ;
              };
              gta4xlwifi_robotnix = robotnix.lib.robotnixSystem {
                inherit (self.los.gta4xlwifi.config)
                  flavor
                  device
                  flavorVersion
                  stateVersion
                  ;
              };
              enchilada_robotnix = robotnix.lib.robotnixSystem {
                inherit (self.los.enchilada.config)
                  flavor
                  device
                  flavorVersion
                  stateVersion
                  ;
              };
              mk_gta4xlwifi =
                kernel:
                let
                  s = import ./sources.nix args; # TODO: replace with more recent lindroid-drm
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
                  kernelSU.enable = false; # TODO: regenerate the patch ./0001-KSUManual4.14.patch
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
                    CONFIG_TMPFS_POSIX_ACL=y

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
                    #./0001-KSUManual4.14.patch # TODO: regenerate the patch
                    ./0001-we-don-t-have-linux-msm_drm_notify.h.patch
                    ./daria.patch
                    ./0001-drop-master-lindroid-patch.patch
                  ];
                };
            in
            {
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
                kernelSrc =
                  assert enchilada_robotnix.config.source.dirs."kernel/oneplus/sdm845".patches == [ ];
                  enchilada_robotnix.config.source.dirs."kernel/oneplus/sdm845".src;
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
                # https://download.lineageos.org/devices/enchilada/builds
                oemBootImg = pkgs.fetchurl {
                  url = "https://web.archive.org/web/20260304112850if_/https://mirrors.ocf.berkeley.edu/lineageos/full/gta4xlwifi/20260228/boot.img";
                  hash = "sha256-1p5R6bGVaQsuF/etyo3hF3Y67XLBiQ1x9p3W2SX/DX0=";
                };
              };
              gta4xlwifi_evobka = mk_gta4xlwifi sources.gta4xlwifi-evobka-kernel.src;
              gta4xlwifi =
                mk_gta4xlwifi (
                  assert gta4xlwifi_robotnix.config.source.dirs."kernel/samsung/gta4xl".patches == [ ];
                  gta4xlwifi_robotnix.config.source.dirs."kernel/samsung/gta4xl".src
                )
                // {
                  # https://download.lineageos.org/devices/gta4xlwifi/builds
                  oemBootImg = pkgs.fetchurl {
                    url = "https://web.archive.org/web/20260304112854if_/https://saimei.ftp.acc.umu.se/mirror/lineageos/full/enchilada/20260304/boot.img";
                    hash = "sha256-O7fHSZltqye+pLssT1CiHwnWaWRoRcon7HKYAIp6IlQ=";
                  };
                };
              samsung_sm8250 = {
                kernelMakeFlags = [
                  "KCFLAGS=\"-Wno-error\""
                  "KCPPFLAGS=\"-Wno-error\""
                ];
                anyKernelVariant = "kernelsu";
                clangVersion = "latest";
                kernelDefconfigs = [
                  "gki_defconfig"
                ];
                #kernelSU.variant = "next";
                kernelImageName = "Image";
                # waiting for https://github.com/xddxdd/nix-kernelsu-builder/commit/d25cbcdb22d1a28bc6db28bf678ea4720873ffe1#commitcomment-178938881
                kernelSU.variant = "custom";
                kernelSU.src = pkgs.callPackage ./ksuNext.nix { };
                kernelSU.revision = null;
                kernelSU.subdirectory = "KernelSU-Next";
                #susfs.enable = true;
                #susfs.src = sources.susfs419.src;
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
                  CONFIG_TMPFS_POSIX_ACL=y
                '';
                kernelSrc =
                  assert gts7lwifi_robotnix.config.source.dirs."kernel/samsung/sm8250".patches == [ ];
                  assert gts7l_robotnix.config.source.dirs."kernel/samsung/sm8250".patches == [ ];
                  assert
                    gts7l_robotnix.config.source.dirs."kernel/samsung/sm8250".src
                    == gts7lwifi_robotnix.config.source.dirs."kernel/samsung/sm8250".src;
                  gts7lwifi_robotnix.config.source.dirs."kernel/samsung/sm8250".src;
                postPatch = ''
                  cp -r ${sources.lindroid_drm_loopback.src} ./drivers/lindroid-drm

                  sed -i "/endmenu/i\source \"drivers/lindroid-drm/Kconfig\"" ./drivers/Kconfig
                  echo 'obj-y += lindroid-drm/' >> ./drivers/Makefile
                '';
                kernelPatches = [
                  ./filter_count.patch
                  ./overlayfs.patch
                ];
                # https://download.lineageos.org/devices/gts7lwifi/builds
                oemBootImg = pkgs.fetchurl {
                  url = "https://web.archive.org/web/20260304113004if_/https://mirrors.ocf.berkeley.edu/lineageos/full/gts7lwifi/20260302/boot.img";
                  hash = "sha256-5VUj4UcqtOynGy2HwBHe7gKI3muta18vJSX9UntQKCM=";
                };
              };
            };
        };
    };
  nixConfig = {
    extra-substituters = [
      # https://garnix.io/docs/caching # garnix sometimes often 504 Gateway Time-out. to avoid waiting on this garnix, supply `--offline` to nix commands.
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };
}
