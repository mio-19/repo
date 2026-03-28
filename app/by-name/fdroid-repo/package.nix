{
  callPackage,
  lib,
  stdenv,
  androidSdkBuilder,
  fdroid-basic,
  shizuku,
  appstore,
  droidspaces-oss,
  glimpse,
  forkgram,
  meshtastic,
  microg-re,
  thunderbird,
  lspatch-manager,
  vpnhotspot,
  meditrak,
  tuxguitar-android,
  zotero-android,
  meshcore-open,
  element-android,
  sunup,
  gamenative,
  archivetune,
  amethyst,
  tailscale,
  termux,
  termux-styling,
  termux-x11,
  emacs,
  haven,
  gadgetbridge,
  nix-on-droid,
  kernelsu,
  koreader,
  recorder,
  youtube-morphe,
  youtube-music-morphe,
  reddit-morphe,
  spotify-revanced,
  duolingo-revanced,
  microsoft-lens-revanced,
  facebook-revanced,
  bilibili-play,
  bilibili-cn,
  rednote,
  instagram-revanced,
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
in
callPackage ./fdroid-repo.nix {
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-0-0
  ]);

  apps = [
    (mkFdroidApp fdroid-basic)
    (mkFdroidApp shizuku)
    (mkFdroidApp appstore)
    (mkFdroidApp droidspaces-oss)
    (mkFdroidApp glimpse)
    (mkFdroidApp forkgram)
    (mkFdroidApp meshtastic)
    (mkFdroidApp microg-re)
    (mkFdroidApp thunderbird)
    (mkFdroidApp lspatch-manager)
    (mkFdroidApp vpnhotspot)
    (mkFdroidApp meditrak)
    (mkFdroidApp tuxguitar-android)
    (mkFdroidApp zotero-android)
    (mkFdroidApp meshcore-open)
    (mkFdroidApp element-android)
    (mkFdroidApp sunup)
    (mkFdroidApp gamenative)
    (mkFdroidApp archivetune)
    (mkFdroidApp amethyst)
  ]
  ++ lib.optionals stdenv.isLinux [
    (mkFdroidApp tailscale)
    (mkFdroidApp termux)
    (mkFdroidApp termux-styling)
    (mkFdroidApp termux-x11)
    (mkFdroidApp emacs)

    # need different gradle lockfile on darwin
    (mkFdroidApp haven)

    # on darwin:  error: bitwise operation between different enumeration types ('ecma_property_flags_t' and 'ecma_property_types_t') [-Werror,-Wenum-enum-conversion]
    (mkFdroidApp gadgetbridge)

    # [CXX1429] error when building with ndkBuild using /nix/var/nix/builds/nix-38269-3239929316/source/termux-shared/src/main/cpp/Android.mk: ERROR: Unknown host CPU architecture: arm64
    (mkFdroidApp nix-on-droid)

    # ndk from nixpkgs: error: Android NDK doesn't support building on arm64-apple-darwin, as far as we know
    # actually ndk from android-nixpkgs run fine on aarch64 darwin with rosetta2 with x86_64 ndk.
    # ndk failed to build on x86_64 linud after recent nixpkgs bump. last working: 9cf7092bdd603554bd8b63c216e8943cf9b12512 first broken: 4724d5647207377bede08da3212f809cbd94a648
    # (mkFdroidApp kernelsu)

    # cannot build on darwin due to stdenv
    (mkFdroidApp koreader)

    # can build locally but not on garnix
    (mkFdroidApp recorder)

    # gradle lock platform dependent issue. need update lock for darwin:
    (mkFdroidApp youtube-morphe)
    (mkFdroidApp youtube-music-morphe)
    (mkFdroidApp reddit-morphe)
    (mkFdroidApp spotify-revanced)
    (mkFdroidApp duolingo-revanced)
    (mkFdroidApp microsoft-lens-revanced)
    (mkFdroidApp facebook-revanced)
    (mkFdroidApp bilibili-play)
    (mkFdroidApp bilibili-cn)
    (mkFdroidApp rednote)
    (mkFdroidApp instagram-revanced)
  ];
}
