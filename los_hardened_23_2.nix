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
    Conservative AXP.OS hardening/privacy subset reused for LineageOS 23.x.

    Source:
    - AXP.OS LineageOS-22.2 patch set from the build repo commit above

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
    (mkAxpPatch
      "android_bionic/0015-increase-default-pthread-stack-to-8mib-on-64-bit.patch"
      "sha256-ph9oEKrpEnrZypb1OLACcvPm3eHlGHqE2395uNtgLGQ="
    )
    (mkAxpPatch
      "android_bionic/0016-make-__stack_chk_guard-read-only-at-runtime.patch"
      "sha256-rEsGT19++5yQ2jEl6ZVeJ0PZEMAxltfgWjEdr0EviHw="
    )
    (mkAxpPatch
      "android_bionic/0017-on-64-bit-zero-the-leading-stack-canary-byte.patch"
      "sha256-0x9qGmSFFlwbLSnRnm+qTelWAo6+t1CdIxXN6xm+1C4="
    )
    (mkAxpPatch
      "android_bionic/0018-switch-pthread_atfork-handler-allocation-to-mmap.patch"
      "sha256-tPE2g/4bTIlFL2jB42dgshh7jGltiH7KWezL3TuYPRU="
    )
    (mkAxpPatch
      "android_bionic/0019-add-memory-protection-for-pthread_atfork-handlers.patch"
      "sha256-elZ8736gwzNxhX/VSLR2DwmSlsgAsXHI3jOU9rn7x94="
    )
  ];

  source.dirs."build/make".patches = [
    (mkAxpPatch
      "android_build_make/0001-Enable_fwrapv.patch"
      "sha256-zl+dz6OnI0gJHIhp5xLepRr89ldZAmI8OKMS8hFCwk0="
    )
  ];

  source.dirs."frameworks/base".patches = [
    (mkAxpPatch
      "android_frameworks_base/0001-supl-dont-send-imsi--phone-number-to-supl-server.patch"
      "sha256-ATswmZ8kaFpFzzJ5ROmtRkBy4mdC1IoMrj24aMTVWL4="
    )
    (mkAxpPatch
      "android_frameworks_base/0002-use-permanent-fingerprint-lockout-immediately.patch"
      "sha256-EGruvo0TzM9Tgc0Nq7tYFGebCcegZxENBD7KWYEYIwk="
    )
    (mkAxpPatch
      "android_frameworks_base/0005-always-set-deprecated-build.serial-to-unknown.patch"
      "sha256-T1PxIkX+Pmk29h+nkHRpaPB7TQnUjfLhBpNFb09cM+s="
    )
    (mkAxpPatch
      "android_frameworks_base/0006-stop-auto-granting-location-to-system-browsers.patch"
      "sha256-zCtXrc/0Ejqbt23s0hN3XO4JAbAY+9xiTS8oDaPGQJ4="
    )
    (mkAxpPatch
      "android_frameworks_base/0029-replace-agnss.goog-with-the-broadcom-psds-server.patch"
      "sha256-zWpizyG70TAJR43zM2ZS92QIh3qWxfmDm+qbKhc66P8="
    )
    (mkAxpPatch
      "android_frameworks_base/0036-do-not-auto-grant-camera-permission-to-the-euicc-lpa-ui-app.patch"
      "sha256-9hCetvzul6/GKvLF7PY0bTC+CgzT9XIAXth3HTdHh5s="
    )
    (mkAxpPatch
      "android_frameworks_base/0039-put-bare-minimum-metadata-in-screenshots.patch"
      "sha256-tP+qRVQTdKARVekYh3Qh5ozDtDY9n2g38iU1E8eQiCo="
    )
  ];

  source.dirs."packages/apps/LineageParts".patches = [
    (mkAxpPatch
      "android_packages_apps_LineageParts/0001-Remove_Analytics.patch"
      "sha256-g3rcmu0Ka4pAWUhfieYcl33/226Ag649Z/PhpZOYPZo="
    )
  ];

  source.dirs."packages/apps/SetupWizard".patches = [
    (mkAxpPatch
      "android_packages_apps_SetupWizard/0001-Remove_Analytics.patch"
      "sha256-sURYx1U4uhu0O9/Vgl31o9PLI3YGNUhmkLdVRQDScj0="
    )
  ];

  source.dirs."system/sepolicy".patches = [
    (mkAxpPatch
      "android_system_sepolicy/0002-protected_files.patch"
      "sha256-fmrhLxn0XcmV4+lpbsqK3tqdVCUCfV0Guzy7+b0OP8M="
    )
    (mkAxpPatch
      "android_system_sepolicy/0003-ptrace_scope-1.patch"
      "sha256-CjogtICNVfqksNjrz/RQv9VKuxD+EFuV7bng/e4OSd8="
    )
  ];
}
