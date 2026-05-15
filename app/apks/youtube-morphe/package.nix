{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
  morphe-patches,
}:
let
  appPackage =
    let
      youtubeApk = fetchurl {
        # https://youtube.en.uptodown.com/android/download/1165342360
        name = "youtube-20.47.62.apk";
        url = "https://web.archive.org/web/20260507095312if_/https://dw.uptodown.net/dwn/IdhnqP6xT2dcasDhCpJg-1yfGw-8LuHpOvCHJQPRcEQRfjAshlfmJk5eMZEMFkLUFiDymwMcjGX7LS7GFgL8CFrZJ8ejG9wR6IeOm26dQIUKipReOhMLgwtXT_EPK3wJ/nI3U-UOyc3J3D4GJmZrN6DPh42TLqFmNYYdo4bpI_Jyq5F6lzwfaY4aqHGGO8tPIt3hX1qIW8eX7nsPCnJDZAJbKyrLmPaSdrKxGHc4KLCsZ2d9Wb6KcSM0YK94vnXis/E1bjO47fwVYrrSIV5f4pB0v9tSuWUqMpJWHBjjQNdawIIHSdbOuhoTnLW-CHFaCkUD9_ZmWOQC1WPMm-ARgmOw==/youtube-20-47-62.apk";
        hash = "sha256-5RijXuGlSq1lOgOU3OlZt3D1bckVmGoZng33GvNkr+0=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-morphe";
      version = "20.45.36-patches-${morphe-patches.version}";

      dontUnpack = true;

      nativeBuildInputs = [
        morphe-cli
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/youtube-morphe"
        mkdir -p "$workdir"
        cp ${youtubeApk} "$workdir/input.apk"
        chmod u+w "$workdir/input.apk"
        export MORPHE_VERSION_NAME_SUFFIX="-patches-${morphe-patches.version}"

        morphe-cli patch \
          --patches=${morphePatches} \
          --enable="Hide ads" \
          --enable="Change package name" \
          --enable="Disable Play Store updates" \
          --unsigned \
          --temporary-files-path "$workdir/tmp" \
          --out "$workdir/youtube-morphe.apk" \
          "$workdir/input.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 "$TMPDIR/youtube-morphe/youtube-morphe.apk" "$out/youtube-morphe.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Patched YouTube APK built with Morphe patches";
        homepage = "https://github.com/MorpheApp/morphe-patches";
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "youtube-morphe.apk";
  signScriptName = "sign-youtube-morphe";
  fdroid = {
    appId = "app.morphe.android.youtube";
    metadataYml = ''
      Categories:
        - Multimedia
      License: Proprietary
      SourceCode: https://github.com/MorpheApp/morphe-patches
      IssueTracker: https://github.com/MorpheApp/morphe-patches/issues
      AutoName: YouTube Morphe
      Summary: Patched YouTube APK with package rename
      Description: |-
        YouTube Morphe is a patched YouTube APK built with Morphe patches
        and installed under an alternate package name.
    '';
  };
}
