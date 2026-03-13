{
  withSystem,
  self,
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs robotnix nix-github-actions;
in
{

  perSystem =
    args@{
      pkgs,
      lib,
      system,
      ...
    }:
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
    rec {
      packages =
        let
          convertKernel = name: {
            name = "kernelSrc-${name}";
            value = self.packages.${system}.${name}.patchedKernelSrc.overrideAttrs (old: {
              # when building kernel in our robotnix build env, with patchShebangs: /nix/store/2hjsch59amjs3nbgh7ahcfzm2bfwl8zi-bash-5.3p9/bin/sh: symbol lookup error: /usr/lib/libc.so.6: undefined symbol: __nptl_change_stack_perm, version GLIBC_PRIVATE
              # https://github.com/xddxdd/nix-kernelsu-builder/blob/cc0fce340e330ad07331692b7c3673d9974be377/pipeline/kernel-config-cmd.nix
              postPatch =
                let
                  config = kernelsu.${name};
                in
                builtins.replaceStrings [ "patchShebangs ." ] [ "" ] old.postPatch
                + ''
                  tee -a arch/${config.arch}/configs/${lib.lists.last config.kernelDefconfigs} << 'EOF'
                  ${lib.optionalString (config.kernelSU.enable or false) ''
                    CONFIG_MODULES=y
                    CONFIG_KPROBES=y
                    CONFIG_HAVE_KPROBES=y
                    CONFIG_KPROBE_EVENTS=y
                    CONFIG_OVERLAY_FS=y
                    CONFIG_KSU=y
                  ''}
                  ${lib.optionalString (config.susfs.enable or false) ''
                    CONFIG_KSU_SUSFS=y
                    CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y
                    CONFIG_KSU_SUSFS_SUS_PATH=y
                    CONFIG_KSU_SUSFS_SUS_MOUNT=y
                    CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y
                    CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y
                    CONFIG_KSU_SUSFS_SUS_KSTAT=y
                    CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y
                    CONFIG_KSU_SUSFS_TRY_UMOUNT=y
                    CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y
                    CONFIG_KSU_SUSFS_SPOOF_UNAME=y
                    CONFIG_KSU_SUSFS_ENABLE_LOG=y
                    CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y
                    CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y
                    CONFIG_KSU_SUSFS_OPEN_REDIRECT=y
                    CONFIG_KSU_SUSFS_SUS_SU=y
                    CONFIG_TMPFS_XATTR=y
                    CONFIG_TMPFS_POSIX_ACL=y
                  ''}
                  ${lib.optionalString (config.bbg.enable or false) ''
                    CONFIG_BBG=y
                  ''}
                  ${config.kernelConfig}
                  EOF
                '';
            });
          };
        in
        builtins.listToAttrs (
          map convertKernel [
            "gts7l"
            "gts7lwifi"
            "gta4xlwifi"
            "enchilada"
          ]
        );
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
              arch = "arm64";
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
          samsung_sm8250 = device: {
            arch = "arm64";
            kernelMakeFlags = [
              "KCFLAGS=\"-Wno-error\""
              "KCPPFLAGS=\"-Wno-error\""
            ];
            anyKernelVariant = "kernelsu";
            clangVersion = "latest";
            kernelDefconfigs = [
              # https://github.com/LineageOS/android_device_samsung_sm8250-common/blob/442e774de353ac00db5e602e63fb8ec6a4a4ec99/BoardConfigCommon.mk#L77 https://github.com/LineageOS/android_device_samsung_gts7lwifi/blob/78279272e6099a54bead3cc6d6af6a18cbbd6a73/BoardConfig.mk#L22
              "vendor/kona-perf_defconfig"
              "vendor/samsung/kona-sec-common.config"
              "vendor/samsung/${device}.config"
            ];
            kernelImageName = "Image";

            kernelSU.enable = true;
            #kernelSU.variant = "official";
            kernelSU.variant = "custom";
            kernelSU.src = (pkgs.callPackage ./ksuNext111.nix { });
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
          };
        in
        {
          # currently only compiles on aarch64-linux
          enchilada = {
            arch = "arm64";
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
          gts7l = samsung_sm8250 "gts7l" // {
            # https://download.lineageos.org/devices/gts7l/builds
            # TODO: correct this
            oemBootImg = pkgs.fetchurl {
              url = "https://web.archive.org/web/20260304113004if_/https://mirrors.ocf.berkeley.edu/lineageos/full/gts7lwifi/20260302/boot.img";
              hash = "sha256-5VUj4UcqtOynGy2HwBHe7gKI3muta18vJSX9UntQKCM=";
            };
          };
          gts7lwifi = samsung_sm8250 "gts7lwifi" // {
            # https://download.lineageos.org/devices/gts7lwifi/builds
            oemBootImg = pkgs.fetchurl {
              url = "https://web.archive.org/web/20260304113004if_/https://mirrors.ocf.berkeley.edu/lineageos/full/gts7lwifi/20260302/boot.img";
              hash = "sha256-5VUj4UcqtOynGy2HwBHe7gKI3muta18vJSX9UntQKCM=";
            };
          };
        };
    };
}
