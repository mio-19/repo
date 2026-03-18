{
  bash,
  bc,
  bison,
  buildFHSEnv,
  bashInteractive,
  cpio,
  file,
  findutils,
  flex,
  gawk,
  glibc,
  gnugrep,
  gnumake,
  gnused,
  hostname,
  lib,
  openssl,
  patch,
  perl,
  python3,
  rsync,
  stdenvNoCC,
  fetchgit,
  which,
  zlib,
  fetchurl,
  fetchFromGitHub,
  dockerTools,
}:
{
  pname,
  version ? "2026030700", # src.tag,
  src ? fetchgit {
    url = "https://gitlab.com/grapheneos/kernel_pixel.git";
    #tag = "2026030700";
    #hash = "sha256-21Db6pD6WJGttTsDUaIq5JU/15izFWvfwCsBlgs/SFo=";
    rev = "d477fba143f661f488cba46900ac4cea31c606eb";
    hash = "sha256-r4MMTi53+NDrAvOkf0wU8henU5/UYzwjhl145jNsFd0=";
    fetchSubmodules = true;
    deepClone = false;
    leaveDotGit = true; # seems like something wants .git # needed with and after 20260307 # fatal: not a git repository (or any parent up to mount point /) in the log
    sparseCheckout = [ ];
  },
  buildScript,
  distDir,
  installSubdir ? "grapheneos",
  enableKSU,
  enableLindroid,
  enableDaria ? enableLindroid,
  buildCommand ? null,
  extraBuildCommands ? "",
}:
let
  sources = (import ./_sources/generated.nix) {
    inherit
      fetchurl
      fetchgit
      fetchFromGitHub
      dockerTools
      ;
  };
  #kernelPixel = sources.grapheneos_kernel_pixel;
  #src = kernelPixel.src;
  #version = "${kernelPixel.date}-${builtins.substring 0 8 kernelPixel.version}";

  lindroidDrm = sources.lindroid_drm_loopback.src;
  kernelSUSrc = import ./kernelSU105.nix { inherit fetchgit; };
  kernelBuildEnv = buildFHSEnv {
    name = "${pname}-build-env";
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
        openssl.dev
        patch
        perl
        python3
        rsync
        which
        zlib
      ];
    runScript = "${bashInteractive}/bin/bash";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;
  dontConfigure = true;
  dontFixup = true;

  buildPhase = ''
    set -euo pipefail
    runHook preBuild
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    ${kernelBuildEnv}/bin/${pname}-build-env -c '
      set -euo pipefail
      apply_patch() {
        local patch_file="$1"
        echo "Applying patch: $patch_file"
        patch -p1 --batch --forward --no-backup-if-mismatch < "$patch_file"
      }

      ${extraBuildCommands}
      ${lib.optionalString enableKSU ''
        # KernelSU v1.0.5 style tree injection shared across GrapheneOS kernels.
        rm -rf aosp/KernelSU
        cp -r ${kernelSUSrc} aosp/KernelSU
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
      ''}

      ${lib.optionalString enableLindroid ''
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

        ${lib.optionalString enableDaria ''
          apply_patch ${./kernel/0001-daria.patch}
        ''}
        apply_patch ${./kernel/sidharth-hack.patch}
      ''}


      ${
        if buildCommand != null then
          buildCommand
        else
          ''
            export KLEAF_REPO_MANIFEST=aosp_manifest.xml
            ./${buildScript} --lto=full
          ''
      }
    '
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/${installSubdir}"
    cp -r out/${distDir}/dist/. "$out/${installSubdir}/"
    runHook postInstall
  '';
}
