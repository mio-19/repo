# see log: adb logcat | grep lindroid
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nix-github-actions.url = "github:nix-community/nix-github-actions";
  inputs.nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
  inputs.robotnix.url = "github:nix-community/robotnix";

  outputs =
    { self, robotnix }:
    let
      common = (
        args@{
          config,
          pkgs,
          lib,
          ...
        }:
        {
          manufactor,
          kernel ? config.device,
          defconfig,
          legacy ? false,
          lindroid ? true,
          patch-daria ? false,
          patch-overlayfs ? false,
          ksu ? true,
          device-name ? config.device,
          kernel-name ? "${manufactor}/${kernel}",
        }:
        extra:

        let
          lindroid-drm = pkgs.fetchgit {
            url = "https://github.com/Linux-on-droid/lindroid-drm-loopback.git";
            rev = "5141110c8bed09be9404e10de7440184bfcf32d4";
            sha256 = "1yvbbkyf7m41ay54ha1d54a0aj1rkisx4gdnixx17wam5phappll";
          };
          kernelsu = pkgs.fetchgit {
            url = "https://github.com/KernelSU-Next/KernelSU-Next.git";
            rev = "5bdb938e845f2dacd37db4a3761d2b38503a708b";
            sha256 = "12r9hgphxgdkq5ky6d8wqmb3kixs0d9nzmawiqy046ls99ryn32k";
          };
        in
        extra
        // {
          flavor = "lineageos";
          microg.enable = true;
          apps.fdroid.enable = true;
          apps.fdroid.additionalRepos = {
            "microG F-Droid repo" = {
              enable = true;
              url = "https://microg.org/fdroid/repo";
              pubkey = "308202ed308201d5a003020102020426ffa009300d06092a864886f70d01010b05003027310b300906035504061302444531183016060355040a130f4e4f47415050532050726f6a656374301e170d3132313030363132303533325a170d3337303933303132303533325a3027310b300906035504061302444531183016060355040a130f4e4f47415050532050726f6a65637430820122300d06092a864886f70d01010105000382010f003082010a02820101009a8d2a5336b0eaaad89ce447828c7753b157459b79e3215dc962ca48f58c2cd7650df67d2dd7bda0880c682791f32b35c504e43e77b43c3e4e541f86e35a8293a54fb46e6b16af54d3a4eda458f1a7c8bc1b7479861ca7043337180e40079d9cdccb7e051ada9b6c88c9ec635541e2ebf0842521c3024c826f6fd6db6fd117c74e859d5af4db04448965ab5469b71ce719939a06ef30580f50febf96c474a7d265bb63f86a822ff7b643de6b76e966a18553c2858416cf3309dd24278374bdd82b4404ef6f7f122cec93859351fc6e5ea947e3ceb9d67374fe970e593e5cd05c905e1d24f5a5484f4aadef766e498adf64f7cf04bddd602ae8137b6eea40722d0203010001a321301f301d0603551d0e04160414110b7aa9ebc840b20399f69a431f4dba6ac42a64300d06092a864886f70d01010b0500038201010007c32ad893349cf86952fb5a49cfdc9b13f5e3c800aece77b2e7e0e9c83e34052f140f357ec7e6f4b432dc1ed542218a14835acd2df2deea7efd3fd5e8f1c34e1fb39ec6a427c6e6f4178b609b369040ac1f8844b789f3694dc640de06e44b247afed11637173f36f5886170fafd74954049858c6096308fc93c1bc4dd5685fa7a1f982a422f2a3b36baa8c9500474cf2af91c39cbec1bc898d10194d368aa5e91f1137ec115087c31962d8f76cd120d28c249cf76f4c70f5baa08c70a7234ce4123be080cee789477401965cfe537b924ef36747e8caca62dfefdd1a6288dcb1c4fd2aaa6131a7ad254e9742022cfd597d2ca5c660ce9e41ff537e5a4041e37";
            };
          };
          # Remember to add /var/cache/ccache as an additional sandbox path to Nix config.
          # https://docs.robotnix.org/modules/other.html
          # mkdir -p -m0770 /var/cache/ccache
          # chown root:nixbld /var/cache/ccache
          # echo max_size = 100G > /var/cache/ccache/ccache.conf
          ccache.enable = true;
          apps.updater.enable = false;
          apps.seedvault.enable = true;
          #apps.chromium.enable = false;
          #webview.chromium.enable = false;
          #apps.vanadium.enable = true;
          #webview.vanadium.enable = true;
          #webview.vanadium.availableByDefault = true;
          #[ 92% 167016/181352] Verifying uses-libraries: robotnix/prebuilt/magisk/magisk.apk (priority: 7)
          #FAILED: out/target/product/gta4xlwifi/obj/APPS/Robotnixmagisk_intermediates/enforce_uses_libraries.status
          #/bin/bash -c "(rm -f out/target/product/gta4xlwifi/obj/APPS/Robotnixmagisk_intermediates/enforce_uses_libraries.status ) && (build/soong/scripts/manifest_check.py     --enforce-uses-libraries     --enforce-uses-libraries-status out/target/product/gta4xlwifi/obj/APPS/Robotnixmagisk_intermediates/enforce_uses_libraries.status     --aapt out/host/linux-x86/bin/aapt2                         robotnix/prebuilt/magisk/magisk.apk )"
          #error: mismatch in the <uses-library> tags between the build system and the manifest:
          #  - required libraries in build system: []
          #                   vs. in the manifest: []
          #  - optional libraries in build system: []
          #      and missing ones in build system: []
          #                   vs. in the manifest: [androidx.window.extensions, androidx.window.sidecar]
          #  - tags in the manifest (robotnix/prebuilt/magisk/magisk.apk):
          #    uses-library-not-required:'androidx.window.extensions'    uses-library-not-required:'androidx.window.sidecar'
          #note: the following options are available:
          #  - to temporarily disable the check on command line, rebuild with RELAX_USES_LIBRARY_CHECK=true (this will set compiler filter "verify" and disable AOT-compilation in dexpreopt)
          #  - to temporarily disable the check for the whole product, set PRODUCT_BROKEN_VERIFY_USES_LIBRARIES := true in the product makefiles
          #  - to fix the check, make build system properties coherent with the manifest
          #  - for details, see build/make/Changes.md and https://source.android.com/devices/tech/dalvik/art-class-loader-context
          #apps.prebuilt.magisk = {
          #  apk = pkgs.fetchurl {
          #    url = "https://github.com/topjohnwu/Magisk/releases/download/v29.0/Magisk-v29.0.apk";
          #    hash = "sha256-mdQN8aaKBaXnhFKpzU8tdTQ012IrrutE6hSugjjBqco=";
          #  };
          #};
          source.dirs."vendor/lindroid" = lib.mkIf lindroid {
            src = pkgs.fetchgit {
              url = "https://github.com/Linux-on-droid/vendor_lindroid.git";
              # lindroid-22.1
              rev = "2d777654939404c333e351f1493d4cf9c93250bc";
              sha256 = "05n39bwbffig1gbp3lrlf2ghh3v4px9xy8b3262gih9ybdskdnd1";
            };
            # https://t.me/linux_on_droid/18552
            postPatch = ''
              sed -i 's|android.hardware.graphics.common-V5|android.hardware.graphics.common-V6|' interfaces/composer/Android.bp
            '';
          };
          source.dirs."external/lxc".src = lib.mkIf lindroid (
            pkgs.fetchgit {
              url = "https://github.com/Linux-on-droid/external_lxc.git";
              # lindroid-21
              rev = "4e3a3630fff3dc04e0d4a761309f87f248e40b17";
              sha256 = "1c993880v9sv97paqkqxd4c9p6j1v8m6d1b2sjwhav3f3l9dh7wn";
            }
          );
          source.dirs."libhybris".src = lib.mkIf lindroid (
            pkgs.fetchgit {
              url = "https://github.com/Linux-on-droid/libhybris.git";
              # lindroid-21
              rev = "419f3ff6736e01cb0e579f65a34c85cfa7de578b";
              sha256 = "1hp69929yrhql2qc4scd4fdvy5zv8g653zvx376c3nlrzckjdm47";
            }
          );
          source.dirs."kernel/${kernel-name}" = {
            patches = lib.mkMerge [
              (lib.mkIf (lindroid && patch-overlayfs) [
                # if overlayfs can't be mounted, you can pick a HACK: https://github.com/android-kxxt/android_kernel_xiaomi_sm8450/commit/ae700d3d04a2cd8b34e1dae434b0fdc9cde535c7
                ./ae700d3d04a2cd8b34e1dae434b0fdc9cde535c7.patch
              ])
              (lib.mkIf (legacy && ksu) [
                # https://github.com/KernelSU-Next/KernelSU-Next/pull/743 -> -Note: legacy kernels: selfmusing/kernel_xiaomi_violet@9596554
                ./9596554cfbdab57682a430c15ca64c691d404152.patch
              ])
              (lib.mkIf (lindroid && patch-daria) [
                # https://t.me/linux_on_droid/19434 -> https://t.me/linux_on_droid/9783
                ./daria.patch
              ])
            ];
            # https://github.com/KernelSU-Next/KernelSU-Next/blob/next/kernel/Kconfig
            postPatch = ''
              ${lib.optionalString lindroid ''cp -r ${lindroid-drm} drivers/lindroid-drm''}
              ${lib.optionalString ksu ''
                cp -r ${kernelsu}/kernel drivers/kernelsu
                chmod -R +w drivers/kernelsu
                sed -i 's|-DKSU_VERSION=11998|-DKSU_VERSION=14630|' drivers/kernelsu/Makefile
                # https://kernelsu-next.github.io/webpage/pages/installation.html -> https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh
                printf "\nobj-\$(CONFIG_KSU) += kernelsu/\n" >> drivers/Makefile
                sed -i "/endmenu/i\source \"drivers/kernelsu/Kconfig\"" drivers/Kconfig

                # https://github.com/KernelSU-Next/KernelSU-Next/blob/5bdb938e845f2dacd37db4a3761d2b38503a708b/kernel/Makefile#L72C1-L115C1
                # 1) Insert can_umount() if missing
                if ! grep -Eq "^static int can_umount" ./fs/namespace.c; then
                    echo "-- KSU_NEXT: adding function 'static int can_umount(const struct path *path, int flags);' to ./fs/namespace.c"
                    sed -i '/^static bool is_mnt_ns_file/i \
                static int can_umount(const struct path *path, int flags)\n\
                {\n\t\
                        struct mount *mnt = real_mount(path->mnt);\n\t\
                        if (flags & ~(MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW))\n\t\t\
                                return -EINVAL;\n\t\
                        if (!may_mount())\n\t\t\
                                return -EPERM;\n\t\
                        if (path->dentry != path->mnt->mnt_root)\n\t\t\
                                return -EINVAL;\n\t\
                        if (!check_mnt(mnt))\n\t\t\
                                return -EINVAL;\n\t\
                        if (mnt->mnt.mnt_flags & MNT_LOCKED)\n\t\t\
                                return -EINVAL;\n\t\
                        if (flags & MNT_FORCE && !capable(CAP_SYS_ADMIN))\n\t\t\
                                return -EPERM;\n\t\
                        return 0;\n\
                }\n' ./fs/namespace.c
                fi
                # 2) Insert path_umount() if missing
                if ! grep -Eq "^int path_umount" ./fs/namespace.c; then
                    echo "-- KSU_NEXT: adding function 'int path_umount(struct path *path, int flags);' to ./fs/namespace.c"
                    sed -i '/^static bool is_mnt_ns_file/i \
                int path_umount(struct path *path, int flags)\n\
                {\n\t\
                        struct mount *mnt = real_mount(path->mnt);\n\t\
                        int ret;\n\t\
                        ret = can_umount(path, flags);\n\t\
                        if (!ret)\n\t\t\
                                ret = do_umount(mnt, flags);\n\t\
                        dput(path->dentry);\n\t\
                        mntput_no_expire(mnt);\n\t\
                        return ret;\n\
                }\n' ./fs/namespace.c
                fi
                # 3) Insert prototype into fs/internal.h if missing
                if ! grep -Eq "^int path_umount(struct path \*path, int flags);" ./fs/internal.h; then
                    sed -i '/^extern void __init mnt_init/a int path_umount(struct path *path, int flags);' ./fs/internal.h
                    echo "-- KSU_NEXT: adding 'int path_umount(struct path *path, int flags);' to ./fs/internal.h"
                fi
              ''}
              echo '
              ${lib.optionalString lindroid ''
                CONFIG_SYSVIPC=y
                CONFIG_UTS_NS=y
                CONFIG_PID_NS=y
                CONFIG_IPC_NS=y
                CONFIG_USER_NS=y
                CONFIG_NET_NS=y
                CONFIG_CGROUP_DEVICE=y
                CONFIG_CGROUP_FREEZER=y

                CONFIG_DRM_LINDROID_EVDI=y''}

              ${lib.optionalString ksu ''
                # https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v1.0.5 : (KPROBES is not really ideal of NON-GKI since some 4.x kernels have buggy KPROBES support which will render your root hooks broken)
                CONFIG_KSU_KPROBES_HOOK=n
              ''}
              ' >> ${defconfig}
              ${lib.optionalString lindroid ''
                echo 'source "drivers/lindroid-drm/Kconfig"' >> drivers/Kconfig
                echo 'obj-y += lindroid-drm/' >> drivers/Makefile''}
            '';
          };
          #source.dirs."kernel/${kernel-name}/drivers/gpu/drm/lindroid".src = lindroid-drm;
          source.dirs."device/${manufactor}/${device-name}".postPatch = lib.mkIf lindroid ''
            echo '
            $(call inherit-product, vendor/lindroid/lindroid.mk)' >> device.mk
          '';
          source.dirs."kernel/configs".postPatch = ''
            sed -i '/# CONFIG_SYSVIPC is not set/d'  */*/android-base.config
          '';
          # https://gerrit.libremobileos.com/c/LMODroid/platform_frameworks_native/+/12936
          source.dirs."frameworks/native".patches = lib.mkIf lindroid [ ./51b680f.diff ];
          # to fix soft reboot when starting container on A14 (temporary!!! workaround) https://t.me/linux_on_droid/10346
          source.dirs."frameworks/base".patches = lib.mkIf lindroid [
            ./0001-Ignore-uevent-s-with-null-name-for-Extcon-WiredAcces.patch
          ];
        }
      );
    in
    {
      githubActions = nix-github-actions.lib.mkGithubMatrix { checks = self.robotnixConfigurations; };
      # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/flake.nix#L57
      robotnixConfigurations = nixpkgs.lib.mapAttrs (n: v: robotnix.lib.robotnixSystem v) {
        gta4xlwifi = (
          args@{ config, pkgs, ... }:
          common args
            {
              manufactor = "samsung";
              kernel = "gta4xl";
              defconfig = "arch/arm64/configs/exynos9611-gta4xlwifi_defconfig";
              legacy = true;
              ksu = false; # buggy
              patch-daria = true;
              patch-overlayfs = true;
            }
            {
              device = "gta4xlwifi";
              flavorVersion = "22.2";
            }
        );
        enchilada = (
          args@{ config, pkgs, ... }:
          common args
            {
              manufactor = "oneplus";
              kernel = "sdm845";
              defconfig = "arch/arm64/configs/enchilada_defconfig";
            }
            {
              device = "enchilada";
              flavorVersion = "22.2";
              #flavorVersion = "23.0";
            }
        );
        nx_tab = (
          args@{ config, pkgs, ... }:
          common args
            {
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
            }
            {
              device = "nx_tab";
              flavorVersion = "22.2";
            }
        );
      };
    };
}
