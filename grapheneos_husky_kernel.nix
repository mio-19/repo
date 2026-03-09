# # pixel8pro-stock.patch pixel8pro-stock-fix-attempt3.patch lindroid ksu105 0001-daria.patch sidharth-hack.patch
{
  lib,
  fetchurl,
  fetchgit,
  fetchFromGitHub,
  dockerTools,
  callPackage,
  enableKSU ? false,
  enable0x01 ? false,
  enable0x05 ? true,
  enable3840Hz ? false,
  enableLindroid ? false,
  enableDaria ? enableLindroid,
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
in
callPackage ./grapheneos_kernel_common.nix { } {
  pname = "grapheneos-husky-kernel";
  buildScript = "build_shusky.sh";
  distDir = "shusky";
  inherit enableKSU;
  extraBuildCommands = ''
    apply_patch ${
      assert (!(enable0x01 && enable3840Hz) && !(enable0x05 && enable3840Hz) && !(enable0x01 && enable0x05)) "enable0x01, enable0x05, and enable3840Hz are mutually exclusive";
      if enable0x01 then
        ./kernel/pixel8pro-stock-0x01.patch
      else if enable0x05 then
        ./kernel/pixel8pro-stock-0x05.patch
      else if enable3840Hz then
        ./kernel/pixel8pro-stock-3840Hz.patch
      else
        ./kernel/pixel8pro-stock.patch
    }
    apply_patch ${./kernel/pixel8pro-stock-fix-attempt3.patch}

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
    ''}

    ${lib.optionalString enableDaria ''
      apply_patch ${./kernel/0001-daria.patch}
    ''}
    apply_patch ${./kernel/sidharth-hack.patch}
  '';
}
