{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  options = {
    bundleLimboTensor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Bundle Limbo Tensor as a system app with a dedicated SELinux domain.";
    };
    bundleDroidVM = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Build and bundle DroidVM as a system app with a dedicated SELinux domain.";
    };
    bundleKernelSUManager = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Build and bundle the KernelSU manager so the user can approve VM apps for root access.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.bundleLimboTensor {
      apps.prebuilt.limboTensor = {
        enable = true;
        name = "LimboTensor";
        packageName = "com.limbo.emu.main.arm";
        apk = "${self.packages.${pkgs.stdenv.hostPlatform.system}.apk_limbo_tensor}/limbo-tensor.apk";
      };
    })
    (lib.mkIf config.bundleDroidVM {
      apps.prebuilt.droidVM = {
        enable = true;
        name = "DroidVM";
        packageName = "cn.classfun.droidvm";
        apk = "${self.packages.${pkgs.stdenv.hostPlatform.system}.apk_droidvm}/droidvm.apk";
      };
    })
    (lib.mkIf config.bundleKernelSUManager {
      apps.prebuilt.kernelSU = {
        enable = true;
        name = "KernelSU";
        packageName = "me.weishu.kernelsu";
        apk = "${self.packages.${pkgs.stdenv.hostPlatform.system}.apk_kernelsu}/kernelsu.apk";
      };
    })
  ];
}
