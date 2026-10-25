{
  pkgs,
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
  mkAxpPatch = path: sources.axp_build.src + "/Patches/LineageOS-22.2/${path}";
in
{
  /*
    Conservative AXP.OS hardening/privacy subset for LineageOS 24.0.

    Source:
    - AXP.OS LineageOS-22.2 patch set from the build repo axp branch via nvfetcher
      (AXP.OS has no newer LineageOS patch set yet)

    Selection:
    - start from the 23.x subset in ./los_hardened_23_2.nix
    - keep only patches that apply (git apply --check) cumulatively, in upstream
      order, to the lineage-24.0 branch of each repo
    - patches dropped because they no longer apply on 24.0:
      - bionic 0016, 0017 (stack canary changes)
      - frameworks/base 0029, 0032, 0035, 0036, 0038, 0039
      - system/sepolicy 0002, 0003
      - packages/apps/SetupWizard 0001
    - revisit when AXP.OS publishes a LineageOS 23.x/24.x patch set
  */

  source.dirs."bionic".patches = [
    (mkAxpPatch "android_bionic/0014-replace-vla-formatting-with-dprintf-like-function.patch")
    (mkAxpPatch "android_bionic/0015-increase-default-pthread-stack-to-8mib-on-64-bit.patch")
    (mkAxpPatch "android_bionic/0018-switch-pthread_atfork-handler-allocation-to-mmap.patch")
    (mkAxpPatch "android_bionic/0019-add-memory-protection-for-pthread_atfork-handlers.patch")
  ];

  source.dirs."build/make".patches = [
    (mkAxpPatch "android_build_make/0001-Enable_fwrapv.patch")
  ];

  source.dirs."frameworks/base".patches = [
    (mkAxpPatch "android_frameworks_base/0001-supl-dont-send-imsi--phone-number-to-supl-server.patch")
    (mkAxpPatch "android_frameworks_base/0002-use-permanent-fingerprint-lockout-immediately.patch")
    (mkAxpPatch "android_frameworks_base/0005-always-set-deprecated-build.serial-to-unknown.patch")
    (mkAxpPatch "android_frameworks_base/0006-stop-auto-granting-location-to-system-browsers.patch")
  ];
}
