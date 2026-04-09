{
  callPackage,
  lib,
  stdenv,
  androidSdkBuilder,
  apk,
}:

let
  mkFdroidApp =
    app:
    assert lib.assertMsg (app.meta ? mainApk)
      "fdroid-repo app ${app.pname or app.name or "<unknown>"} is missing meta.mainApk";
    assert lib.assertMsg (app.meta ? appId)
      "fdroid-repo app ${app.pname or app.name or "<unknown>"} is missing meta.appId";
    assert lib.assertMsg (app.meta ? metadataYml)
      "fdroid-repo app ${app.pname or app.name or "<unknown>"} is missing meta.metadataYml";
    {
      apkPath = "${app}/${app.meta.mainApk}";
      inherit (app.meta) appId metadataYml;
    };

  linuxOnlyApkNames = [
    "tailscale"
    "termux"
    "termux-styling"
    "termux-x11"
    "emacs"
    "comaps"

    # need different gradle lockfile on darwin
    "haven"

    # on darwin:  error: bitwise operation between different enumeration types ('ecma_property_flags_t' and 'ecma_property_types_t') [-Werror,-Wenum-enum-conversion]
    "gadgetbridge"

    # [CXX1429] error when building with ndkBuild using /nix/var/nix/builds/nix-38269-3239929316/source/termux-shared/src/main/cpp/Android.mk: ERROR: Unknown host CPU architecture: arm64
    "nix-on-droid"

    # cannot build on darwin due to fhs
    "koreader"

    # can build locally but not on garnix - Operation not permitted
    "recorder"
    "archivetune"

    # gradle lock platform dependent issue. need update lock for darwin:
    "youtube-morphe"
    "youtube-music-morphe"
    "reddit-morphe"
    "spotify-revanced"
    "duolingo-revanced"
    "microsoft-lens-revanced"
    "facebook-revanced"
    "bilibili-play"
    "bilibili-cn"
    "rednote"
    "instagram-revanced"
    "duolingo-hoodles"
    "instagram-brosssh"
    "twitter-piko"
    "gallery"

    # need to update golang hash for darwin:
    "nekobox-for-android"

    # need to update npm lock for darwin:
    "pdfviewer"

    # cannot build on darwin due to nixpkgs didn't package android toolchain for darwin aarch64
    "kernelsu"
    "bitwarden-android"
    "bitwarden-authenticator"

    # build tool "qmake" runs on linux only
    "firebird"

    # failed to compile on darwin after https://github.com/NixOS/nixpkgs/pull/500309
    "rain"
  ];

  excludedApkNames = [
  ];

  fdroidApks = lib.filterAttrs (
    name: app:
    (app ? meta)
    && (app.meta ? metadataYml)
    && !(builtins.elem name excludedApkNames)
    && (stdenv.isLinux || !(builtins.elem name linuxOnlyApkNames))
  ) apk;
in
callPackage ./fdroid-repo.nix {
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-1-0
  ]);

  apps = lib.mapAttrsToList (_: mkFdroidApp) fdroidApks;
}
