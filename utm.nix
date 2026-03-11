args@{
  config,
  pkgs,
  lib,
  ...
}:
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
}
