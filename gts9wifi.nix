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
  variant = "userdebug";
  imports = [ ./los.nix ];
  manufactor = "samsung";
  kernel-short = "sm8550";
  defconfig = "arch/arm64/configs/gts9wifi_defconfig";
  device = "gts9wifi";
  flavorVersion = "23.2";
  lindroid = false;
  ksu = false;
  gapps = true;
  microg.enable = false;

  source.dirs = {
    "device/samsung/gts9wifi" = {
      src = sources.sm8550_tab_device_gts9wifi.src;
      postPatch = ''
        # The pinned hardware/samsung source no longer provides SamsungParts.
        sed -i '/^[[:space:]]*SamsungParts[[:space:]]*\\$/d' device.mk
      '';
    };
    "device/samsung/sm8550-common".src = sources.sm8550_tab_device_sm8550_common.src;
    "vendor/samsung/gts9wifi".src = sources.sm8550_tab_vendor_gts9wifi.src;
    "vendor/samsung/sm8550-common".src = sources.sm8550_tab_vendor_sm8550_common.src;
    "kernel/samsung/sm8550".src = sources.sm8550_tab_kernel_sm8550.src;
    "kernel/samsung/sm8550-modules" = {
      src = sources.sm8550_tab_kernel_sm8550_modules.src;
      postPatch = ''
        camera_makefile=qcom/opensource/camera-kernel/Makefile
        sed -i '/^cam_generated_h:/,/^$/c\
        cam_generated_h:\
        \t@:' "$camera_makefile"
        cat > qcom/opensource/camera-kernel/cam_generated_h <<'EOF'
        #define CAMERA_COMPILE_TIME "robotnix"
        #define CAMERA_COMPILE_BY "nix"
        #define CAMERA_COMPILE_HOST "nix"
        EOF
      '';
    };
    "hardware/samsung".src = sources.sm8550_tab_hardware_samsung.src;
  };

  stateVersion = "3";
}
