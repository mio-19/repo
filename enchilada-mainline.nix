args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./los.nix ];
  manufactor = "oneplus";
  kernel-short = "sdm845";
  defconfig = "arch/arm64/configs/defconfig";
  device = "enchilada";
  flavorVersion = "23.2";
  gapps = true;
  microg.enable = false;
  legacy414 = false;
  ksu = false;
  lindroid = false;
  lindroid-drm = false;
  stateVersion = "3";
  enable-kernel = false;
  # robotnix marks enchilada 23.2 as missing deps because upstream manifest lacks
  # kernel/oneplus/sdm845. We provide it explicitly below.
  assertions = lib.mkForce [ ];

  source.dirs = {
    "vendor/oneplus/enchilada" = {
      src = pkgs.fetchFromGitHub {
        owner = "TheMuppets";
        repo = "proprietary_vendor_oneplus_enchilada";
        rev = "2dedc8d1099e0b4d3e507c0049ee9bdcf12d77f0";
        hash = "sha256-Tw9HIZ0AAIXLFFA5ZSot14eQ2K2hyEXG0kinXni0DC8=";
      };
      postPatch = ''
        sed -i 's/add-radio-file-sha1-checked/add-radio-file/g' Android.mk
      '';
    };
    "vendor/oneplus/sdm845-common".src = pkgs.fetchFromGitHub {
      owner = "TheMuppets";
      repo = "proprietary_vendor_oneplus_sdm845-common";
      rev = "3d6b72f093ccfb99e8bfc17af204441b6e6322aa";
      hash = "sha256-Qa6vdg7+qmij7VMdHXSQ+wYDmYdwUcAd1RdiH47Dzgg=";
    };
    "hardware/qcom-caf/bootctrl".postPatch = ''
      sed -i 's/false: \[\],/"false": [],/' gpt-utils/Android.bp
    '';

    # Keep the device tree but switch it to mainline kernel config/image defaults.
    "device/oneplus/sdm845-common".postPatch = ''
      sed -i \
        -e 's|^BOARD_KERNEL_IMAGE_NAME := .*|BOARD_KERNEL_IMAGE_NAME := Image.gz|' \
        -e 's|^TARGET_KERNEL_CONFIG := .*|TARGET_KERNEL_CONFIG := defconfig sdm845.config|' \
        BoardConfigCommon.mk
      sed -i '/^DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := \\/,/^DEVICE_MATRIX_FILE := /c\
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := \\\
    $(COMMON_PATH)/framework_compatibility_matrix.xml \\\
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml \\\
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix_legacy.xml\
\
DEVICE_MATRIX_FILE := $(COMMON_PATH)/compatibility_matrix.xml' BoardConfigCommon.mk
    '';

    # Reuse LineageOS mainline components used by current mainline devices.
    "device/mainline/common".src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_device_mainline_common";
      rev = "63d6b822704a8539ebb0f84319db0957ddbbf99c";
      hash = "sha256-TVE1C0GM9CABdwCGjYJoMyThHQa5nPdTHWgWTEaOvWM=";
    };
    "device/mainline/qcom-common".src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_device_mainline_qcom-common";
      rev = "a78e396481404aa0a1aeb0f859bb8aaf5ffc3989";
      hash = "sha256-ApuFe8DhqKDkepq/+q5JgVtmlXB+AKbsq6QdjWxRDPU=";
    };
    "kernel/mainline/configs".src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_kernel_mainline_configs";
      rev = "cbd8590fed658bd598bd77f4460bb96c0f1fb0c7";
      hash = "sha256-yT+Vo7GUFCIMwv8+5Vj2iM83sFsyHqI1XJc7XObtpeU=";
    };
    "hardware/mainline/common".src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_hardware_mainline_common";
      rev = "a041424e50ef9304092f0663a60b906925000d29";
      hash = "sha256-Q6SSGrPJtuWpYEGHxh1lL/bdh/Txp/7amMRXnpV7IiY=";
    };
    "hardware/mainline/qcom".src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_hardware_mainline_qcom";
      rev = "ecf7f082f63c79431141b76648c0398acf99b34c";
      hash = "sha256-zJW8jJJZt+9qN7RCFuiq5nilWQrv9ivLQpQo2f1Fwk0=";
    };
    "external/linux-firmware-mainline".src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_external_linux-firmware-mainline";
      rev = "6734582a4fba084e07bd5d80ccfc2ea4976e865f";
      hash = "sha256-C84GuV/JD+9ozj52fkmX98g6IdGCfnUui/3t80FvZsw=";
    };
    "external/tinyhal".src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_external_tinyhal";
      rev = "0e87ac3457b98c5f7104540e896e3c7610c95750";
      hash = "sha256-+jIOqs/CfiqhxLMakTHZRHKWvZO7UYMG13pHlVfyOqI=";
    };
    "hardware/sony/timekeep".src = pkgs.fetchFromGitHub {
      owner = "LineageOS";
      repo = "android_hardware_sony_timekeep";
      rev = "07f619c12dd80052f865c51e5d8c77d860c68c64";
      hash = "sha256-JYQlqeeWIFh4ibx9EYfUmrmqlAOTik1+7AJO77Msang=";
    };

    # Mainline SDM845 kernel from postmarketOS.
    "kernel/oneplus/sdm845" = lib.mkForce {
      src = pkgs.fetchFromGitLab {
        owner = "sdm845-mainline";
        repo = "linux";
        rev = "sdm845-6.16.7-r0";
        hash = "sha256-XYlXuzapuesiTpvquuz0b6yPyAqEdK9lMdglST+EZhk=";
      };
    };
  };
}
