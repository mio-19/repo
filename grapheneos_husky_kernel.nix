# # pixel8pro-stock.patch pixel8pro-stock-fix-attempt3.patch lindroid ksu105 0001-daria.patch sidharth-hack.patch
{ pkgs }:
let
  src = pkgs.fetchgit {
    url = "https://gitlab.com/grapheneos/kernel_pixel.git";
    rev = "aff4e27a786c017a00179036714ae5309681c784"; # 16-qpr2
    fetchSubmodules = true;
    hash = "sha256-6E/DWOGXAfNfl2fr7JSszlFOSAetyTD11GtMd15b1II=";
  };

  kernelBuildEnv = pkgs.buildFHSEnv {
    name = "grapheneos-kernel-build-env";
    targetPkgs =
      p: with p; [
        bash
        bc
        bison
        cpio
        file
        findutils
        flex
        gawk
        glibc.dev
        stdenv.cc.cc
        git
        gnugrep
        gnumake
        gnused
        hostname
        openssl
        patch
        perl
        python3
        rsync
        which
        zlib
      ];
    runScript = "${pkgs.bashInteractive}/bin/bash";
  };

  lindroidDrm = pkgs.fetchgit {
    url = "https://github.com/Linux-on-droid/lindroid-drm-loopback.git";
    rev = "bfa24f48033660e1f470842582e4b241d9622b4d";
    hash = "sha256-L6+Jp+Jm8r8S/pWIrPlvvbWjp5yV3COCc7q8NFKzOcE=";
  };

  kernelSU = pkgs.fetchgit {
    url = "https://github.com/tiann/KernelSU.git";
    rev = "61c0f7f849aaca299fb42516bc8fc516cefe0d59"; # v1.0.5
    sha256 = "0pacv69h270c4fypj6kbnc765p4l9r2951gzry0pi04y18sbq0pw";
    leaveDotGit = true;
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "grapheneos-husky-kernel";
  version = "16-qpr2-aff4e27a";
  inherit src;
  dontConfigure = true;
  dontFixup = true;

  buildPhase = ''
    runHook preBuild
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    ${kernelBuildEnv}/bin/grapheneos-kernel-build-env -c '
      set -euo pipefail
      apply_patch() {
        local patch_file="$1"
        echo "Applying patch: $patch_file"
        patch -p1 --batch --forward --no-backup-if-mismatch < "$patch_file"
      }

      apply_patch ${./kernel/pixel8pro-stock.patch}
      apply_patch ${./kernel/pixel8pro-stock-fix-attempt3.patch}

      # lindroid steps
      sed -i "/^# CONFIG_PID_NS is not set$/d" aosp/arch/arm64/configs/gki_defconfig
      sed -i "/^CONFIG_NAMESPACES=y$/a CONFIG_USER_NS=y" aosp/arch/arm64/configs/gki_defconfig
      sed -i "/^CONFIG_INTERCONNECT=y$/a CONFIG_DRM_LINDROID_EVDI=y" aosp/arch/arm64/configs/gki_defconfig
      sed -i "/^CONFIG_TMPFS=y$/a CONFIG_TMPFS_POSIX_ACL=y" aosp/arch/arm64/configs/gki_defconfig
      sed -i "/^CONFIG_CPUSETS=y$/a CONFIG_CGROUP_DEVICE=y" aosp/arch/arm64/configs/gki_defconfig
      sed -i "/^CONFIG_UAPI_HEADER_TEST=y$/a CONFIG_SYSVIPC=y" aosp/arch/arm64/configs/gki_defconfig

      sed -i "/^  __fsnotify_parent$/a\\  from_kuid" aosp/android/abi_gki_aarch64_pixel
      sed -i "/^  from_kuid$/a\\  from_kuid_munged" aosp/android/abi_gki_aarch64_pixel
      sed -i "/^  mac_pton$/a\\  make_kuid" aosp/android/abi_gki_aarch64_pixel

      rm -rf aosp/drivers/lindroid-drm
      cp -r ${lindroidDrm} aosp/drivers/lindroid-drm
      echo "obj-y += lindroid-drm/" >> aosp/drivers/Makefile
      sed -i "/endmenu/i\\source \"drivers/lindroid-drm/Kconfig\"" aosp/drivers/Kconfig

      (
        cd aosp
        apply_patch ${./kernel/0ac686b9e81ba331c2ad9b420fd21262a80daaa4.patch}
        apply_patch ${./kernel/3dcc884c689681dda2d9ad24a9e219013f70cfe8.patch}
        apply_patch ${./kernel/a72032ecf33c63d8a4abb64b08c1a0b847c82a32.patch}
      )

      # ksu105 (KernelSU v1.0.5)
      rm -rf aosp/KernelSU
      cp -r ${kernelSU} aosp/KernelSU
      chmod -R u+w aosp/KernelSU
      ln -sfn ../KernelSU/kernel aosp/drivers/kernelsu
      printf "\nobj-\$(CONFIG_KSU) += kernelsu/\n" >> aosp/drivers/Makefile
      sed -i "/endmenu/i\\source \"drivers/kernelsu/Kconfig\"" aosp/drivers/Kconfig

      cp aosp/KernelSU/kernel/Makefile aosp/KernelSU/kernel/Makefile.orig
      {
        echo "srctree := $(pwd)/aosp"
        echo "src := KernelSU/kernel"
        cat aosp/KernelSU/kernel/Makefile.orig
      } > aosp/KernelSU/kernel/Makefile

      apply_patch ${./kernel/0001-daria.patch}
      apply_patch ${./kernel/sidharth-hack.patch}

      export KLEAF_REPO_MANIFEST=aosp_manifest.xml
      ./build_shusky.sh --lto=full
    '
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/grapheneos"
    cp -r out/shusky/dist/. "$out/grapheneos/"
    runHook postInstall
  '';
}
