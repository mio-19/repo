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

    # need different gradle lockfile on darwin
    "haven"

    # on darwin:  error: bitwise operation between different enumeration types ('ecma_property_flags_t' and 'ecma_property_types_t') [-Werror,-Wenum-enum-conversion]
    "gadgetbridge"

    # [CXX1429] error when building with ndkBuild using /nix/var/nix/builds/nix-38269-3239929316/source/termux-shared/src/main/cpp/Android.mk: ERROR: Unknown host CPU architecture: arm64
    "nix-on-droid"

    # cannot build on darwin due to stdenv
    "koreader"

    # can build locally but not on garnix
    "recorder"

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
  ];

  excludedApkNames = [
    # ndk from nixpkgs: error: Android NDK doesn't support building on arm64-apple-darwin, as far as we know
    # actually ndk from android-nixpkgs run fine on aarch64 darwin with rosetta2 with x86_64 ndk.
    # ndk failed to build on x86_64 linux after recent nixpkgs bump. last working: 9cf7092bdd603554bd8b63c216e8943cf9b12512 first broken: 4724d5647207377bede08da3212f809cbd94a648
    "kernelsu"
  ];

  fdroidApks = lib.filterAttrs (
    name: app:
    (app.meta ? metadataYml)
    && !(builtins.elem name excludedApkNames)
    && (stdenv.isLinux || !(builtins.elem name linuxOnlyApkNames))
  ) apk;
in
callPackage ./fdroid-repo.nix {
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  apps = lib.mapAttrsToList (_: mkFdroidApp) fdroidApks;
}
