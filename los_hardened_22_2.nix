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
    Conservative AXP.OS hardening/privacy subset for LineageOS 22.2.

    Source:
    - Scripts/LineageOS-22.2/Patch.sh
    - Patches/LineageOS-22.2 from AXP.OS build repo axp branch via nvfetcher

    Selection:
    - keep patches that are broadly sensible for a LineageOS 22.2 enchilada build
    - prefer hardening/privacy changes over branding, updater server, microG,
      and other AXP-specific policy choices
    - skip imperative Patch.sh edits based on git revert/sed/cp since those do
      not map cleanly to robotnix source patch lists
  */

  source.dirs."art".patches = [
    (mkAxpPatch "android_art/0001-constify_JNINativeMethod.patch")
  ];

  source.dirs."bionic".patches = [
    (mkAxpPatch "android_bionic/0010-add-a-real-explicit_bzero-implementation.patch")
    (mkAxpPatch "android_bionic/0013-fix-undefined-out-of-bounds-accesses-in-sched.h.patch")
    (mkAxpPatch "android_bionic/0014-replace-vla-formatting-with-dprintf-like-function.patch")
    (mkAxpPatch "android_bionic/0015-increase-default-pthread-stack-to-8mib-on-64-bit.patch")
    (mkAxpPatch "android_bionic/0016-make-__stack_chk_guard-read-only-at-runtime.patch")
    (mkAxpPatch "android_bionic/0017-on-64-bit-zero-the-leading-stack-canary-byte.patch")
    (mkAxpPatch "android_bionic/0018-switch-pthread_atfork-handler-allocation-to-mmap.patch")
    (mkAxpPatch "android_bionic/0019-add-memory-protection-for-pthread_atfork-handlers.patch")
    (mkAxpPatch "android_bionic/0025-bionic-sort-and-cache-hosts-file-data-for-fast-lookup.patch")
    (mkAxpPatch "android_bionic/0027-add-a-toggle-to-disable-etchosts-lookup.patch")
  ];

  source.dirs."build/make".patches = [
    (mkAxpPatch "android_build_make/0001-Enable_fwrapv.patch")
  ];

  source.dirs."build/soong".patches = [
    (mkAxpPatch "android_build_soong/0001-Enable_fwrapv.patch")
  ];

  source.dirs."external/conscrypt".patches = [
    (mkAxpPatch "android_external_conscrypt/0001-constify_JNINativeMethod.patch")
  ];

  source.dirs."frameworks/base".patches = [
    (mkAxpPatch "android_frameworks_base/0001-supl-dont-send-imsi--phone-number-to-supl-server.patch")
    (mkAxpPatch "android_frameworks_base/0002-use-permanent-fingerprint-lockout-immediately.patch")
    (mkAxpPatch "android_frameworks_base/0005-always-set-deprecated-build.serial-to-unknown.patch")
    (mkAxpPatch "android_frameworks_base/0006-stop-auto-granting-location-to-system-browsers.patch")
    (mkAxpPatch "android_frameworks_base/0026-systemui-use-new-privacy-indicators-for-location.patch")
    (mkAxpPatch "android_frameworks_base/0027-dont-report-statementservice.patch")
    (mkAxpPatch "android_frameworks_base/0028-dont-leak-device-wide-package-list-to-apps-when-work-profile.patch")
    (mkAxpPatch "android_frameworks_base/0029-replace-agnss.goog-with-the-broadcom-psds-server.patch")
    (mkAxpPatch "android_frameworks_base/0032-add-a-setting-for-forcibly-disabling-supl.patch")
    (mkAxpPatch "android_frameworks_base/0035-filter-select-package-queries-for-gms.patch")
    (mkAxpPatch "android_frameworks_base/0036-do-not-auto-grant-camera-permission-to-the-euicc-lpa-ui-app.patch")
    (mkAxpPatch "android_frameworks_base/0038-systemui-require-unlocking-to-use-qs-tiles-by-default.patch")
    (mkAxpPatch "android_frameworks_base/0039-put-bare-minimum-metadata-in-screenshots.patch")
  ];

  source.dirs."frameworks/native".patches = [
    (mkAxpPatch "android_frameworks_native/0001-require-other_sensors-permission-for-sensors.patch")
    (mkAxpPatch "android_frameworks_native/0002-protect-step-sensors-with-other_sensors-permission-for-target-sdkLT29-apps.patch")
    (mkAxpPatch "android_frameworks_native/0004-exempt-system-processes-from-other_sensors-permission-enforcement.patch")
  ];

  source.dirs."libcore".patches = [
    (mkAxpPatch "android_libcore/0001-dont-throw-securityexception-when-internet-permission-is-revoked.patch")
    (mkAxpPatch "android_libcore/0002-constify_JNINativeMethod.patch")
  ];

  source.dirs."packages/apps/LineageParts".patches = [
    (mkAxpPatch "android_packages_apps_LineageParts/0001-Remove_Analytics.patch")
  ];

  source.dirs."packages/apps/Settings".patches = [
    (mkAxpPatch "android_packages_apps_Settings/0012-add-a-toggle-for-forcibly-disabling-supl.patch")
  ];

  source.dirs."packages/apps/SetupWizard".patches = [
    (mkAxpPatch "android_packages_apps_SetupWizard/0001-Remove_Analytics.patch")
  ];

  source.dirs."packages/modules/Permission".patches = [
    (mkAxpPatch "android_packages_modules_Permission/0001-add-special-handling-for-internetother_sensors.patch")
    (mkAxpPatch "android_packages_modules_Permission/0002-fix-usage-ui-summary-for-networksensors.patch")
    (mkAxpPatch "android_packages_modules_Permission/0003-stop-auto-granting-location-to-system-browsers.patch")
    (mkAxpPatch "android_packages_modules_Permission/0004-fixup-add-special-handling-for-internetother_sensors.patch")
    (mkAxpPatch "android_packages_modules_Permission/0005-fixup-fix-usage-ui-summary-for-networksensors.patch")
    (mkAxpPatch "android_packages_modules_Permission/0006-systemui-use-new-privacy-indicators-for-location.patch")
  ];

  source.dirs."system/core".patches = [
    (mkAxpPatch "android_system_core/0001-Harden.patch")
    (mkAxpPatch "android_system_core/0002-ptrace_scope.patch")
  ];

  source.dirs."system/sepolicy".patches = [
    (mkAxpPatch "android_system_sepolicy/0002-protected_files.patch")
    (mkAxpPatch "android_system_sepolicy/0003-ptrace_scope-1.patch")
    (mkAxpPatch "android_system_sepolicy/0003-ptrace_scope-2.patch")
  ];
}
