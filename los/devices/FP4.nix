{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../default.nix
    ../hardened_24_0.nix
  ];

  device = "FP4";
  manufactor = "fairphone";
  kernel-short = "sm7225";
  defconfig = "arch/arm64/configs/vendor/lito-perf_defconfig";
  flavorVersion = "24.0";
  stateVersion = "3";
  variant = "user";
  # FP4 otherwise emits vbmeta flags that disable verification and verity.
  envVars.WITH_AVB = "true";
  signing.avb.enable = true;
  signing.avb.mode = "vbmeta_chained_v2";

  ksu = false;
  lindroid = false;
  gapps = false;
  microg.enable = false;

  # The 24.0 manifest records this dependency but marks it inactive. FP4 still
  # uses the LineageOS 23.2 kernel; reuse the manifest's exact revision/hash.
  source.dirs."kernel/fairphone/sm7225".src = pkgs.fetchgit {
    url = "https://github.com/LineageOS/android_kernel_fairphone_sm7225";
    rev = "0ff1c1c66c00373cd9445db0ef1805493554cae1";
    hash = "sha256-tNcjgK5IV2cSgDr9aq7nnJm68kL722r5Q0Wec9jmCrk=";
    fetchLFS = true;
    fetchSubmodules = false;
  };
  source.dirs."kernel/fairphone/sm7225".patches =
    pkgs.callPackage ../../kernel/fairphone_sm7225_axp_patches.nix
      {
        axp_kernel_patches = pkgs.fetchgit {
          url = "https://gitlab.com/mio-mirror/git.disroot.org/AXP.OS/kernel_patches.git";
          rev = "a20109ae4aab35215e4acf38f08cb93aeab64aa4";
          hash = "sha256-JKkPk0OQYqfr+D6vZWZVPus3dSZfRxuQSbuQZTuiuDM=";
          fetchSubmodules = false;
        };
      };

  # Keep the Android kernel compatibility requirements intact for this build.
  source.dirs."kernel/configs".postPatch = lib.mkForce "";
}
