{
  pkgs,
  ...
}:
let
  commit = "df79a0f102ea0cce4004153397f158d85b5f16d2";
  mkAxpPatch =
    path: hash:
    pkgs.fetchpatch {
      url = "https://git.disroot.org/AXP.OS/build/raw/commit/${commit}/Patches/LineageOS-22.2/${path}";
      inherit hash;
    };
in
{
  /*
    Conservative AXP.OS hardening/privacy subset for LineageOS 22.2.

    Source:
    - Scripts/LineageOS-22.2/Patch.sh
    - Patches/LineageOS-22.2 from AXP.OS build repo commit above

    Selection:
    - keep patches that are broadly sensible for a LineageOS 22.2 enchilada build
    - prefer hardening/privacy changes over branding, updater server, microG,
      and other AXP-specific policy choices
    - skip imperative Patch.sh edits based on git revert/sed/cp since those do
      not map cleanly to robotnix source patch lists
  */

  source.dirs."art".patches = [
    (mkAxpPatch "android_art/0001-constify_JNINativeMethod.patch" "sha256-RyQUjkQ7wbPXjA3Skr/kDjMY6WDqbk8o9HrhQQYRcUw=")
  ];

  source.dirs."bionic".patches = [
    (mkAxpPatch "android_bionic/0010-add-a-real-explicit_bzero-implementation.patch" "sha256-2amA/FrIw9x/S5adlHN72riS99LqcEiNuHxPVU+PyMY=")
    (mkAxpPatch "android_bionic/0013-fix-undefined-out-of-bounds-accesses-in-sched.h.patch" "sha256-w0xe4QhDFS7/SItxiNqQFa9WHHextj0ClIUjouYztOQ=")
    (mkAxpPatch "android_bionic/0015-increase-default-pthread-stack-to-8mib-on-64-bit.patch" "sha256-ph9oEKrpEnrZypb1OLACcvPm3eHlGHqE2395uNtgLGQ=")
    (mkAxpPatch "android_bionic/0016-make-__stack_chk_guard-read-only-at-runtime.patch" "sha256-rEsGT19++5yQ2jEl6ZVeJ0PZEMAxltfgWjEdr0EviHw=")
    (mkAxpPatch "android_bionic/0017-on-64-bit-zero-the-leading-stack-canary-byte.patch" "sha256-0x9qGmSFFlwbLSnRnm+qTelWAo6+t1CdIxXN6xm+1C4=")
    (mkAxpPatch "android_bionic/0018-switch-pthread_atfork-handler-allocation-to-mmap.patch" "sha256-tPE2g/4bTIlFL2jB42dgshh7jGltiH7KWezL3TuYPRU=")
    (mkAxpPatch "android_bionic/0019-add-memory-protection-for-pthread_atfork-handlers.patch" "sha256-elZ8736gwzNxhX/VSLR2DwmSlsgAsXHI3jOU9rn7x94=")
  ];

  source.dirs."build/make".patches = [
    (mkAxpPatch "android_build_make/0001-Enable_fwrapv.patch" "sha256-zl+dz6OnI0gJHIhp5xLepRr89ldZAmI8OKMS8hFCwk0=")
  ];

  source.dirs."build/soong".patches = [
    (mkAxpPatch "android_build_soong/0001-Enable_fwrapv.patch" "sha256-t037r0RxpjNauJsC7ZbyToU4PmVzrOHaB8Rk7kGjGWc=")
  ];

  source.dirs."external/conscrypt".patches = [
    (mkAxpPatch "android_external_conscrypt/0001-constify_JNINativeMethod.patch" "sha256-JKwzBrkjlon8a9vGY+XAobZINhQ/agD5VtwHJNh6zoI=")
  ];

  source.dirs."frameworks/base".patches = [
    (mkAxpPatch "android_frameworks_base/0001-supl-dont-send-imsi--phone-number-to-supl-server.patch" "sha256-ATswmZ8kaFpFzzJ5ROmtRkBy4mdC1IoMrj24aMTVWL4=")
    (mkAxpPatch "android_frameworks_base/0002-use-permanent-fingerprint-lockout-immediately.patch" "sha256-EGruvo0TzM9Tgc0Nq7tYFGebCcegZxENBD7KWYEYIwk=")
    (mkAxpPatch "android_frameworks_base/0005-always-set-deprecated-build.serial-to-unknown.patch" "sha256-T1PxIkX+Pmk29h+nkHRpaPB7TQnUjfLhBpNFb09cM+s=")
    (mkAxpPatch "android_frameworks_base/0006-stop-auto-granting-location-to-system-browsers.patch" "sha256-zCtXrc/0Ejqbt23s0hN3XO4JAbAY+9xiTS8oDaPGQJ4=")
    (mkAxpPatch "android_frameworks_base/0027-dont-report-statementservice.patch" "sha256-yw2vQ9pV6p1nz75rXTuehFgNr8IzA+dknP9n617igQg=")
    (mkAxpPatch "android_frameworks_base/0028-dont-leak-device-wide-package-list-to-apps-when-work-profile.patch" "sha256-wFkPx1lJ4bomEVrtjhaIKVadKENBW7Ri+fvfnncGbSE=")
    (mkAxpPatch "android_frameworks_base/0029-replace-agnss.goog-with-the-broadcom-psds-server.patch" "sha256-zWpizyG70TAJR43zM2ZS92QIh3qWxfmDm+qbKhc66P8=")
    (mkAxpPatch "android_frameworks_base/0036-do-not-auto-grant-camera-permission-to-the-euicc-lpa-ui-app.patch" "sha256-9hCetvzul6/GKvLF7PY0bTC+CgzT9XIAXth3HTdHh5s=")
    (mkAxpPatch "android_frameworks_base/0038-systemui-require-unlocking-to-use-qs-tiles-by-default.patch" "sha256-jZmz1bP/nz/4EDnqQBSoZUkV3g2RGeblN/fVftd7mbk=")
    (mkAxpPatch "android_frameworks_base/0039-put-bare-minimum-metadata-in-screenshots.patch" "sha256-tP+qRVQTdKARVekYh3Qh5ozDtDY9n2g38iU1E8eQiCo=")
  ];

  source.dirs."libcore".patches = [
    (mkAxpPatch "android_libcore/0002-constify_JNINativeMethod.patch" "sha256-Bpg9uOpkQJy8oCqQZb2Zb7BAnwAtFNZ42IOGF0Kljtk=")
  ];

  source.dirs."packages/apps/LineageParts".patches = [
    (mkAxpPatch "android_packages_apps_LineageParts/0001-Remove_Analytics.patch" "sha256-g3rcmu0Ka4pAWUhfieYcl33/226Ag649Z/PhpZOYPZo=")
  ];

  source.dirs."packages/apps/SetupWizard".patches = [
    (mkAxpPatch "android_packages_apps_SetupWizard/0001-Remove_Analytics.patch" "sha256-sURYx1U4uhu0O9/Vgl31o9PLI3YGNUhmkLdVRQDScj0=")
  ];

  source.dirs."packages/modules/Permission".patches = [
    (mkAxpPatch "android_packages_modules_Permission/0003-stop-auto-granting-location-to-system-browsers.patch" "sha256-4O81hZVdcV/lxV8ak/Smwiskk6j+4YtVwklUgg+wkTk=")
  ];

  source.dirs."system/core".patches = [
    (mkAxpPatch "android_system_core/0001-Harden.patch" "sha256-/4ScarAGJ15L9prui/QlO3Ff6/cdolBgbYGgEwG6dnA=")
    (mkAxpPatch "android_system_core/0002-ptrace_scope.patch" "sha256-XeQwk+rW3+H8isHT47FvqVcJJS0C54j/QX9Z3pqrLA4=")
  ];

  source.dirs."system/sepolicy".patches = [
    (mkAxpPatch "android_system_sepolicy/0002-protected_files.patch" "sha256-fmrhLxn0XcmV4+lpbsqK3tqdVCUCfV0Guzy7+b0OP8M=")
    (mkAxpPatch "android_system_sepolicy/0003-ptrace_scope-1.patch" "sha256-CjogtICNVfqksNjrz/RQv9VKuxD+EFuV7bng/e4OSd8=")
    (mkAxpPatch "android_system_sepolicy/0003-ptrace_scope-2.patch" "sha256-Fa/PaI47TgT4kf9z4uvvAt5+B/v2yGXsFOD8syL99TY=")
  ];
}
