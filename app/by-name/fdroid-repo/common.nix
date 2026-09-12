{
  lib,
  stdenv,
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
      preSigned = app.meta.preSigned or false;
      inherit (app.meta) appId metadataYml;
    };

  linuxOnlyApkNames = [
    "komi-store"
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

    # gradle lock platform dependent issue. need update lock for darwin:
    "youtube-morphe"
    "youtube-music-morphe"
    "youtube-revanced"
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

    # need to update golang hash for darwin:

    # need to update npm lock for darwin:
    "pdfviewer"

    # cannot build on darwin due to nixpkgs didn't package android toolchain for darwin aarch64
    "kernelsu"
    "bitwarden-android"
    "bitwarden-authenticator"

    # build tool "qmake" runs on linux only
    "firebird"

    # failed to compile on darwin after https://github.com/NixOS/nixpkgs/pull/500309
    #"rain"
    #"weathermaster"
    #"meshcore-open"
    #"immich"

    "joplin"

    "sunup" # Internal compiler error. See log for more details

    "ytdlnis" # fails on darwin with 404 for newpipeextractor
    "gamenative" # fails on darwin with 404

    "ollama-app" # gtk4 failed on darwin

    "vpnhotspot" # too complicated to build on darwin due to mitm-cache/gradle proxy, ksp, daemon socket and memory issues
    "eden" # buildPhase fails mysteriously/killed on darwin
    "tuxguitar-android" # buildPhase fails mysteriously/killed on darwin
    "amethyst" # misses AGP plugin marker from deps.json on darwin
    "droidspaces" # build fails mysteriously on darwin
    "fdroid-basic" # build fails mysteriously on darwin
    "meditrak" # fails with FSEvents stream error on darwin
    "shelter" # Gradle fails to use mitmCache proxy on darwin
    "v2rayng" # misses AGP plugin marker from deps.json on darwin
    "forkgram" # buildPhase fails mysteriously/killed on darwin
    "forkgram-classic" # buildPhase fails mysteriously/killed on darwin
    "element-android" # misses Gradle plugin marker from deps.json on darwin
    "archivetune" # misses Gradle plugin marker from deps.json on darwin
    "gh4a" # misses AGP plugin marker from deps.json on darwin
    "breezy-weather" # misses Gradle plugin marker from deps.json on darwin
    "futo-keyboard" # misses AGP plugin marker from deps.json on darwin
    "mastodon-android" # Gradle fails to use mitmCache proxy on darwin
    "microg-re" # Gradle fails to use mitmCache proxy on darwin
    "aurorastore" # depends on gradle_9_5_1 which fails to compile on darwin
    "komi-store" # depends on gradle_9_5_1 which fails to compile on darwin
    "meshtastic" # depends on gradle_9_5_1 which fails to compile on darwin
    "nextcloud-android" # depends on gradle_9_5_1 which fails to compile on darwin
    "pdfviewer" # depends on gradle_9_5_1 which fails to compile on darwin
    "termux-x11" # depends on gradle_9_5_1 which fails to compile on darwin
    "thunderbird" # depends on gradle_9_5_1 which fails to compile on darwin
    "zotero-android" # depends on gradle_9_5_1 which fails to compile on darwin
    "mpv-android" # Gradle fails to use mitmCache proxy on darwin
    "kdeconnect-android" # buildPhase fails mysteriously/killed on darwin
    "luanti" # Gradle fails to use mitmCache proxy on darwin
    "lspatch" # ephemeral-port-reserve throws Operation not permitted on darwin
    "lumo" # Gradle plugin and FSEvents stream error on darwin
    "lspatch-manager" # depends on lspatch
    "meshcore-open" # buildPhase fails mysteriously/killed on darwin
    "uplink" # pkgsCross Android NDK rust + Flutter APK
    "mpvex" # Gradle fails to resolve foojay-resolver plugin on darwin
    "onlyoffice-documents" # misses Gradle plugin marker from deps.json on darwin
    "immich" # misses Gradle plugin marker from deps.json on darwin
    "weathermaster" # misses AGP plugin marker from deps.json on darwin
    "rain" # misses Gradle plugin marker from deps.json on darwin
    "nekobox-for-android" # misses Gradle plugin marker from deps.json on darwin
    "grapheneos-camera" # Gradle Worker Daemon fails to start on darwin
    "gallery" # misses lint-gradle dependency on darwin
  ];

  # Apps with OSS-looking licenses that still should not be published in fdroid-repo-oss
  # (patched proprietary APKs, trademark derivatives, etc.).
  nonOssApkNames = [
    "forkgram"
    "forkgram-classic"
  ];

  metadataLicenseLine =
    metadataYml:
    let
      matches = builtins.match ".*License: ([^\n]+).*" metadataYml;
    in
    if matches == null then null else lib.head matches;

  isProprietaryMetadata =
    metadataYml:
    let
      license = metadataLicenseLine metadataYml;
    in
    license != null && lib.hasInfix "Proprietary" license;

  hasFdroidMetadata = app: (app ? meta) && (app.meta ? metadataYml) && (app.meta ? appId);

  platformOk = name: stdenv.hostPlatform.isLinux || !(builtins.elem name linuxOnlyApkNames);

  mkFdroidApkFilter =
    {
      excludedApkNames ? [ ],
      ossOnly ? false,
    }:
    lib.filterAttrs (
      name: app:
      hasFdroidMetadata app
      && !(builtins.elem name excludedApkNames)
      && !(ossOnly && builtins.elem name nonOssApkNames)
      && !(ossOnly && isProprietaryMetadata app.meta.metadataYml)
      && platformOk name
    ) apk;
in
{
  inherit
    mkFdroidApp
    linuxOnlyApkNames
    nonOssApkNames
    mkFdroidApkFilter
    isProprietaryMetadata
    ;
}
