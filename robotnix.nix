{
  withSystem,
  self,
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs robotnix nix-github-actions;
  mkGos =
    { ccache }:
    let
      common =
        f:
        args@{ pkgs, ... }:
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
        args@{ pkgs, ... }:
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
      dm3q-kenzie = common ./dm3q-kenzie.nix;
      dm3q_cola2261 = common ./dm3q-cola2261.nix;
      gts9wifi = common ./gts9wifi.nix;
      gts7lwifi = common ./gts7lwifi.nix;
      gts7l = common ./gts7l.nix;
    };
in
{
  flake = {
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
            ]
            ++ pkgs.callPackage ./oneplus_sdm845_axp_patches.nix {
              axp_kernel_patches = sources.axp_kernel_patches.src;
            };
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
              # AXP.OS backports selected from the sm8250 CVE patcher after checking
              # them against LineageOS android_kernel_samsung_sm8250 lineage-23.2
              # (4.19.325) and keeping only the patches that also applied in
              # upstream order as one cumulative series.
            ]
            ++ pkgs.callPackage ./samsung_sm8250_axp_patches.nix {
              axp_kernel_patches = sources.axp_kernel_patches.src;
            };
            # https://download.lineageos.org/devices/gts7lwifi/builds
            oemBootImg = pkgs.fetchurl {
              url = "https://web.archive.org/web/20260304113004if_/https://mirrors.ocf.berkeley.edu/lineageos/full/gts7lwifi/20260302/boot.img";
              hash = "sha256-5VUj4UcqtOynGy2HwBHe7gKI3muta18vJSX9UntQKCM=";
            };
          };
        };
    };
}
