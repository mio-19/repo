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
    Conservative AXP.OS hardening/privacy subset reused for LineageOS 23.x.

    Source:
    - AXP.OS LineageOS-22.2 patch set from the build repo axp branch via nvfetcher

    Selection:
    - start from the smaller 22.2 subset in ./los_hardened_22_2.nix
    - test each patch against the matching LineageOS 23.x repo branch
      (usually lineage-23.2, but use the latest available 23.x branch per repo)
    - keep only patches that still pass git apply --check and also apply
      cumulatively within each repo in upstream order
    - skip repos with inconsistent upstream archive availability rather than
      carrying unverified patches forward
  */

  source.dirs."bionic".patches = [
    (mkAxpPatch "android_bionic/0014-replace-vla-formatting-with-dprintf-like-function.patch")
    (mkAxpPatch "android_bionic/0015-increase-default-pthread-stack-to-8mib-on-64-bit.patch")
    (mkAxpPatch "android_bionic/0016-make-__stack_chk_guard-read-only-at-runtime.patch")
    (mkAxpPatch "android_bionic/0017-on-64-bit-zero-the-leading-stack-canary-byte.patch")
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
    (mkAxpPatch "android_frameworks_base/0029-replace-agnss.goog-with-the-broadcom-psds-server.patch")
    (mkAxpPatch "android_frameworks_base/0032-add-a-setting-for-forcibly-disabling-supl.patch")
    (mkAxpPatch "android_frameworks_base/0035-filter-select-package-queries-for-gms.patch")
    (mkAxpPatch "android_frameworks_base/0036-do-not-auto-grant-camera-permission-to-the-euicc-lpa-ui-app.patch")
    (mkAxpPatch "android_frameworks_base/0038-systemui-require-unlocking-to-use-qs-tiles-by-default.patch")
    (mkAxpPatch "android_frameworks_base/0039-put-bare-minimum-metadata-in-screenshots.patch")
  ];

  source.dirs."packages/apps/LineageParts".patches = [
    (mkAxpPatch "android_packages_apps_LineageParts/0001-Remove_Analytics.patch")
  ];

  source.dirs."packages/apps/SetupWizard".patches = [
    (mkAxpPatch "android_packages_apps_SetupWizard/0001-Remove_Analytics.patch")
  ];

  source.dirs."system/sepolicy".patches = [
    (mkAxpPatch "android_system_sepolicy/0002-protected_files.patch")
    (mkAxpPatch "android_system_sepolicy/0003-ptrace_scope-1.patch")
  ];
}
