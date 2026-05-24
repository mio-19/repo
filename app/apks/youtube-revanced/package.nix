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
        # https://youtube.en.uptodown.com/android/download/1113555850
        name = "youtube-20.40.45.apk";
        url = "https://files.catbox.moe/iv053i.apk";
        hash = "sha256-t2WdpJKh69i9fOopCb5O4fWOAKJYbWWhyRsuHl7GrNE=";
      };

      revancedBundle = "${revanced-patches}/app/revanced/patches/6.1.0/patches-6.1.0.rvp";
    in
    stdenv.mkDerivation {
      pname = "youtube-revanced";
      version = "20.40.45-patches-6.1.0";

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
