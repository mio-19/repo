{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  revanced-cli,
  revanced-patches,
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

      revancedBundle = "${revanced-patches}/app/revanced/patches/6.1.0/patches-6.1.0.rvp";
    in
    stdenv.mkDerivation {
      pname = "youtube-revanced";
      version = "20.47.62-patches-6.1.0";

      dontUnpack = true;

      nativeBuildInputs = [
        revanced-cli
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/youtube-revanced"
        mkdir -p "$workdir"
        cp ${youtubeApk} "$workdir/youtube.apk"
        chmod u+w "$workdir/youtube.apk"

        revanced-cli patch \
          -b \
          -p ${revancedBundle} \
          --enable="Change package name" \
          --enable="Hide ads" \
          --enable="GmsCore support" \
          --enable="MicroG support" \
          -o "$workdir/youtube-revanced.apk" \
          "$workdir/youtube.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 "$TMPDIR/youtube-revanced/youtube-revanced.apk" "$out/youtube-revanced.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Patched YouTube APK built with ReVanced patches";
        homepage = "https://github.com/ReVanced/revanced-patches";
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "youtube-revanced.apk";
  signScriptName = "sign-youtube-revanced";
  fdroid = {
    appId = "app.revanced.android.youtube";
    metadataYml = ''
      Categories:
        - Multimedia
      License: Proprietary
      SourceCode: https://github.com/ReVanced/revanced-patches
      IssueTracker: https://github.com/ReVanced/revanced-patches/issues
      AutoName: YouTube ReVanced
      Summary: Patched YouTube APK
      Description: |-
        YouTube ReVanced is a patched YouTube APK built with
        ReVanced patches.
    '';
  };
}
