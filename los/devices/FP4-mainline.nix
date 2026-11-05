{
  lib,
  pkgs,
  ...
}:
let
  mainlineKernel = pkgs.callPackage ../../kernel/fairphone_fp4_mainline.nix { };
in
{
  imports = [ ./FP4.nix ];

  # Build Android userspace from the FP4 LineageOS tree, but embed the
  # experimental Nura SM6350 mainline kernel instead of rebuilding 4.19.
  # This is an integration experiment; the vendor HALs expect the downstream
  # Android kernel ABI and are not known to work with mainline.
  source.dirs."device/fairphone/FP4".postPatch = lib.mkAfter ''
    substituteInPlace BoardConfig.mk \
      --replace-fail 'BOARD_KERNEL_IMAGE_NAME := Image' 'BOARD_KERNEL_IMAGE_NAME := Image.gz' \
      --replace-fail 'TARGET_KERNEL_SOURCE := kernel/fairphone/sm7225' 'TARGET_KERNEL_SOURCE :='
    cat >> BoardConfig.mk <<'EOF'
    TARGET_PREBUILT_KERNEL := ${mainlineKernel}/Image.gz
    BOARD_PREBUILT_DTBIMAGE_DIR := ${mainlineKernel}/dtb
    EOF
  '';
}
