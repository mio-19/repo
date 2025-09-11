args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  lindroid-drm = pkgs.fetchgit {
    #url = "https://github.com/Linux-on-droid/lindroid-drm-loopback.git";
    url = "https://github.com/Linux-On-LineageOS/lindroid-drm-loopback.git";
    rev = "71fea78ad41e806d0177379b964cf6931d9baa1e";
    sha256 = "14jv9aa85521scnyn6fp683j78zbdr7884i2nf0f4q9vh9r2scbl";
  };
  lindroid-drm414 = pkgs.fetchgit {
    url = "https://github.com/mio-19/lindroid-drm-loopback.git";
    rev = "a2d5acc66bc3c0ffa6132df43c0db854169f4ef6";
    sha256 = "09nkr6plvbcz0lzdhh86jb7f9gp0k8jsz85zzr0ipk0hzqgr12vs";
  };
  kernelsu = pkgs.fetchgit {
    url = "https://github.com/KernelSU-Next/KernelSU-Next.git";
    rev = "8edb892792dc4f2a8fb6bba5aa48e20006dac0c3";
    sha256 = "0skmq4cl471bph1wgj9vdw66bhk2n0qnv48d8savfabs07p6xgly";
  };
in
{
  options = {
    manufactor = lib.mkOption {
      type = lib.types.str;
      description = "Device manufacturer";
    };
    kernel-short = lib.mkOption {
      type = lib.types.str;
      default = config.device;
      description = "Kernel short name";
    };
    defconfig = lib.mkOption {
      type = lib.types.str;
      description = "Defconfig path";
    };
    legacy414 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Legacy kernel";
    };
    lindroid = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable lindroid";
    };
    lindroid-drm = lib.mkOption {
      type = lib.types.bool;
      default = config.lindroid;
      description = "Enable lindroid-drm";
    };
    patch-daria = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable daria patch";
    };
    patch-overlayfs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable overlayfs patch";
    };
    ksu = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable KernelSU";
    };
    device-name = lib.mkOption {
      type = lib.types.str;
      default = config.device;
      description = "Device name";
    };
    kernel-name = lib.mkOption {
      type = lib.types.str;
      default = "${config.manufactor}/${config.kernel-short}";
      description = "Kernel name path";
    };
  };
  config.flavor = "lineageos";
  config.microg.enable = true;
  config.apps.fdroid.enable = true;
  config.apps.fdroid.additionalRepos = {
    "microG F-Droid repo" = {
      enable = true;
      url = "https://microg.org/fdroid/repo";
      pubkey = "308202ed308201d5a003020102020426ffa009300d06092a864886f70d01010b05003027310b300906035504061302444531183016060355040a130f4e4f47415050532050726f6a656374301e170d3132313030363132303533325a170d3337303933303132303533325a3027310b300906035504061302444531183016060355040a130f4e4f47415050532050726f6a65637430820122300d06092a864886f70d01010105000382010f003082010a02820101009a8d2a5336b0eaaad89ce447828c7753b157459b79e3215dc962ca48f58c2cd7650df67d2dd7bda0880c682791f32b35c504e43e77b43c3e4e541f86e35a8293a54fb46e6b16af54d3a4eda458f1a7c8bc1b7479861ca7043337180e40079d9cdccb7e051ada9b6c88c9ec635541e2ebf0842521c3024c826f6fd6db6fd117c74e859d5af4db04448965ab5469b71ce719939a06ef30580f50febf96c474a7d265bb63f86a822ff7b643de6b76e966a18553c2858416cf3309dd24278374bdd82b4404ef6f7f122cec93859351fc6e5ea947e3ceb9d67374fe970e593e5cd05c905e1d24f5a5484f4aadef766e498adf64f7cf04bddd602ae8137b6eea40722d0203010001a321301f301d0603551d0e04160414110b7aa9ebc840b20399f69a431f4dba6ac42a64300d06092a864886f70d01010b0500038201010007c32ad893349cf86952fb5a49cfdc9b13f5e3c800aece77b2e7e0e9c83e34052f140f357ec7e6f4b432dc1ed542218a14835acd2df2deea7efd3fd5e8f1c34e1fb39ec6a427c6e6f4178b609b369040ac1f8844b789f3694dc640de06e44b247afed11637173f36f5886170fafd74954049858c6096308fc93c1bc4dd5685fa7a1f982a422f2a3b36baa8c9500474cf2af91c39cbec1bc898d10194d368aa5e91f1137ec115087c31962d8f76cd120d28c249cf76f4c70f5baa08c70a7234ce4123be080cee789477401965cfe537b924ef36747e8caca62dfefdd1a6288dcb1c4fd2aaa6131a7ad254e9742022cfd597d2ca5c660ce9e41ff537e5a4041e37";
    };
    # https://github.com/MatthewCroughan/nixcfg/blob/afab322e6da20cc038d8577dd4a365673702d183/hosts/pyxis/default.nix#L28C7-L33C7
    bitwarden = {
      enable = true;
      url = "https://mobileapp.bitwarden.com/fdroid/repo";
      pubkey = "3082050b308202f3a003020102020450bb84bb300d06092a864886f70d01010b050030363110300e060355040b1307462d44726f6964312230200603550403131962697477617264656e2d5669727475616c2d4d616368696e65301e170d3139303630373031323531305a170d3436313032333031323531305a30363110300e060355040b1307462d44726f6964312230200603550403131962697477617264656e2d5669727475616c2d4d616368696e6530820222300d06092a864886f70d01010105000382020f003082020a02820201008d80ad2dec6a0a227fc4ccf55b20c1c968f375fadf457fd6fd03a5f0eec0743fcb037595fa450603faa94c1c49307786e591c5f4324704ed087491f6329d6921ab82402a7b2b65c14d0443e390f44e0e43af606b6aee8be0ad6fcaa808b2b68cd275844a1496e187a47a9546fed59fea48f1ee4eef6ee2b8df2d0139e6bf0dc58bd1adfcb9b6545dd0fe9ad1c685ed09692aa202745d2cbe3f43b917fdfd8fdf2ac9f01f09dd4c2a5eb3401e1648912b324c3b96dba361fc2ff7308456179ebb7fa4e6700a9af986829bb63c27ddb02c4881ec272446c3bcb286ebfcd50b1ff4e3864bc447d164400982f97c89380094e1ac146ecdf7c36469bfc6a17a177cd6f6bd14695b1858358af6a2b2f32e9ac457539ce2b19a986354483b77acbd0544863becd437ff11bb1bc9d2493b93607049c31b1cc72a81d4bfeac2eb2e49c0ab3be8037ffa2e2df90a3cf8bb2d90e37d20f917d3b56cc308fd0fa49b111daca230d77028b82285085a3c896561c8000f61b3aeb102ecf67c9466a62854bf477f82def889a6fe2d606fc296387bf70c4250188c80a292cd563a5bde28eebd7911822a01ff8667dce1324cab735b60d18f0cce3a114bb72ae0019c0f93adc1a2a8d81be9782c78d724d9917eee6b1c81a751b009f18828cf17593c1a52e27a35b03aece4f03a8dcf280557d9294d6f95df44bdeef8be32321a1397b09fb72848990203010001a321301f301d0603551d0e04160414fd6084b86a35190c8c2e14bde4ece1950c22c603300d06092a864886f70d01010b050003820201005af4595384cb93cc1be2f0afbfea9b5f7d730ed38cb15410dde9eaa1b4399229e9bef1237cb72a30978211651ba5d4c54a42815f3560fe5c6bc681b560e68cbb3783f93ce5c464900748d94a254f971bf216504c83dddf22687e1417f4b0f856054ec179ca6a40d590452eb420742238f0745e0d7aea7e2480f754d1e3d222aca89db4728b339f8f15824f6787c8f65236ec76812a3223426a24e2d86c180cf7b792f9609b1f60a3c52c1eeb976f0195ed279f30a575746e9092dcf9682f3a577b67099e2bc1f2a0315feddd2b575c94bdd60db4213f93ea6b5597c55944d3e86f73cd5c5d166d8eefdc78aea1ae66b8dfb166198fe0cfdfba348b884357f506335328432b1cae8eac5f1bd34442f30d68dbeef6b97ca1b169dc6f3c0a6d57396a09785f4a4de5853ba7a53cf92636d25a3e1d7af183b7b94b93a2aa4821aa5e9b684d1f756fde036cdc666c40fcefe65fe6be29af71440517e1f9fb3039c3394d0c3989d6f75a7675a659c568f8255080d9dcccb42f7243cf2ba1d317d432a584f095bc2ef9e394b1be16055e3a0feee66c4f0dc78854f13fbfb814ba001fa99a454dfa97684c37d71eff1959ce05b455ac3f80b960c824e2b39d985c9cf8b2d25d5c51252c547c29060b9e7e78eb53b0492f0aef0c6839c7850c95bf68038c02c5cacd6f7f43c0db065b0296ea1c313e0cec92a87edcaeb3ae4a2f51ee169d";
    };
  };
  # Remember to add /var/cache/ccache as an additional sandbox path to Nix config.
  # https://docs.robotnix.org/modules/other.html
  # mkdir -p -m0770 /var/cache/ccache
  # chown root:nixbld /var/cache/ccache
  # echo max_size = 100G > /var/cache/ccache/ccache.conf
  config.ccache.enable = lib.mkDefault true;
  config.apps.updater.enable = false;
  config.apps.seedvault.enable = true;
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
  config.source.dirs."vendor/lindroid" = lib.mkIf config.lindroid {
    src = pkgs.fetchgit {
      url = "https://github.com/Linux-on-droid/vendor_lindroid.git";
      # lindroid-22.1
      rev = "04bad35b95a1694bbc1fad43758c0d9253fef321";
      sha256 = "1zk2vidq805njw59llvsxrwrfnxxp38804n5myr0shrmd0si163s";
    };
    # https://t.me/linux_on_droid/18552
    postPatch = ''
      sed -i 's|android.hardware.graphics.common-V5|android.hardware.graphics.common-V6|' interfaces/composer/Android.bp
    '';
  };
  config.source.dirs."external/lxc".src = lib.mkIf config.lindroid (
    pkgs.fetchgit {
      url = "https://github.com/Linux-on-droid/external_lxc.git";
      # lindroid-21
      rev = "4e3a3630fff3dc04e0d4a761309f87f248e40b17";
      sha256 = "1c993880v9sv97paqkqxd4c9p6j1v8m6d1b2sjwhav3f3l9dh7wn";
    }
  );
  config.source.dirs."libhybris".src = lib.mkIf config.lindroid (
    pkgs.fetchgit {
      url = "https://github.com/Linux-on-droid/libhybris.git";
      # lindroid-21
      rev = "419f3ff6736e01cb0e579f65a34c85cfa7de578b";
      sha256 = "1hp69929yrhql2qc4scd4fdvy5zv8g653zvx376c3nlrzckjdm47";
    }
  );
  config.source.dirs."kernel/${config.kernel-name}" = {
    # config.kernel = {
    # relpath = "kernel/${config.kernel-name}";
    # enable = true;
    patches = lib.mkMerge [
      (lib.mkIf (config.lindroid && config.patch-overlayfs) [
        # if overlayfs can't be mounted, you can pick a HACK: https://github.com/android-kxxt/android_kernel_xiaomi_sm8450/commit/ae700d3d04a2cd8b34e1dae434b0fdc9cde535c7
        ./ae700d3d04a2cd8b34e1dae434b0fdc9cde535c7.patch
      ])
      (lib.mkIf (config.legacy414 && config.ksu) [
        # https://github.com/KernelSU-Next/KernelSU-Next/pull/743 -> -Note: legacy kernels: selfmusing/kernel_xiaomi_violet@9596554
        ./9596554cfbdab57682a430c15ca64c691d404152.patch
      ])
      (lib.mkIf (config.lindroid && config.lindroid-drm && config.legacy414) [
        ./0001-drm-name-changes.patch
        ./0001-DRM_MODESET_ACQUIRE_INTERRUPTIBLE.patch
        ./0001-int-drm_modeset_backoff.patch
      ])
      (lib.mkIf (config.lindroid && config.patch-daria) [
        # https://t.me/linux_on_droid/19434 -> https://t.me/linux_on_droid/9783
        ./daria.patch
      ])
      (lib.mkIf (config.lindroid && config.kernel-short == "gta4xl") [
        ./0001-we-don-t-have-linux-msm_drm_notify.h.patch
      ])
    ];
    # https://github.com/KernelSU-Next/KernelSU-Next/blob/next/kernel/Kconfig
    postPatch = ''
      ${lib.optionalString (config.lindroid && config.lindroid-drm)
        ''cp -r ${if config.legacy414 then lindroid-drm414 else lindroid-drm} drivers/lindroid-drm''
      }
      ${lib.optionalString config.ksu ''
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
      ${lib.optionalString config.lindroid ''
        CONFIG_SYSVIPC=y
        CONFIG_UTS_NS=y
        CONFIG_PID_NS=y
        CONFIG_IPC_NS=y
        CONFIG_USER_NS=y
        CONFIG_NET_NS=y
        CONFIG_CGROUP_DEVICE=y
        CONFIG_CGROUP_FREEZER=y''}

      ${lib.optionalString (config.lindroid && config.lindroid-drm) ''
        CONFIG_DRM=y
        CONFIG_DRM_LINDROID_EVDI=y''}

      ${lib.optionalString config.ksu ''
        # https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/v1.0.5 : (KPROBES is not really ideal of NON-GKI since some 4.x kernels have buggy KPROBES support which will render your root hooks broken)
        CONFIG_KSU_KPROBES_HOOK=n
      ''}
      ' >> ${config.defconfig}
      ${lib.optionalString (config.lindroid && config.lindroid-drm) ''
        sed -i "/endmenu/i\source \"drivers/lindroid-drm/Kconfig\"" drivers/Kconfig
        echo 'obj-y += lindroid-drm/' >> drivers/Makefile''}
    '';
  };
  #source.dirs."kernel/${config.kernel-name}/drivers/gpu/drm/lindroid".src = lindroid-drm;
  config.source.dirs."device/${config.manufactor}/${config.device-name}".postPatch =
    lib.mkIf config.lindroid ''
      echo '
      $(call inherit-product, vendor/lindroid/lindroid.mk)' >> device.mk
    '';
  config.source.dirs."kernel/configs".postPatch = ''
    sed -i '/# CONFIG_SYSVIPC is not set/d'  */*/android-base.config
  '';
  # https://gerrit.libremobileos.com/c/LMODroid/platform_frameworks_native/+/12936
  config.source.dirs."frameworks/native".patches = lib.mkIf config.lindroid [ ./51b680f.diff ];
  # to fix soft reboot when starting container on A14 (temporary!!! workaround) https://t.me/linux_on_droid/10346
  config.source.dirs."frameworks/base".patches = lib.mkIf config.lindroid [
    ./0001-Ignore-uevent-s-with-null-name-for-Extcon-WiredAcces.patch
  ];
}
