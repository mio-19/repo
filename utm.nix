# WIP
args@{
  config,
  pkgs,
  lib,
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
{
  imports = [ ./los.nix ];

  # LineageOS documents UTM on Apple Silicon Macs via the aarch64-only
  # virtio target.
  manufactor = "generic";
  kernel-short = "virtio_arm64only";
  defconfig = "arch/arm64/configs/defconfig";
  device = "virtio_arm64only";
  flavorVersion = "23.2";
  stateVersion = "3";

  enable-kernel = false;
  lindroid = false;
  gapps = true;
  microg.enable = false;

  # TODO: enable KSU after switching this target away from TARGET_NO_KERNEL /
  # prebuilt virtual-device kernels to a source-built kernel path.
  ksu = false;

  source.dirs = {
    "device/mainline/common".src = sources.lineage_device_mainline_common.src;
    "device/virt/virtio_arm64only".src = sources.lineage_device_virtio_arm64only.src;
    "device/virt/virtio_arm64".src = sources.lineage_device_virtio_arm64.src;
    "device/virt/virt-common".src = sources.lineage_device_virt_common.src;
    "device/virt/virtio-common".src = sources.lineage_device_virtio_common.src;
    "external/drm_hwcomposer-upstream".src = sources.lineage_external_drm_hwcomposer_upstream.src;
    "external/libdisplay-info-upstream".src = sources.lineage_external_libdisplay_info_upstream.src;
    "external/minigbm-upstream".src = sources.lineage_external_minigbm_upstream.src;
    "external/linux-firmware-mainline".src = sources.lineage_external_linux_firmware_mainline.src;
    "external/mesa".src = sources.lineage_external_mesa.src;
    "hardware/mainline/common".src = sources.lineage_hardware_mainline_common.src;
    "kernel/mainline/configs".src = sources.lineage_kernel_mainline_configs.src;
    "kernel/virt/virtio".src = sources.lineage_kernel_virt_virtio.src;
    "prebuilts/bootmgr".src = sources.lineage_prebuilts_bootmgr.src;
  };
}
