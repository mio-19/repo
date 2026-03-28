{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  revanced-cli,
  revanced-patches,
  apkeditor,
}:
let
  appPackage =
    let
      instagramXapk = fetchurl {
        # APKPure page: https://apkpure.com/instagram-android-2025/com.instagram.android/download/401.0.0.48.79
        name = "instagram-401.0.0.48.79.xapk";
        url = "https://web.archive.org/web/20260325092530if_/https://d-e02.winudf.com/b/XAPK/Y29tLmluc3RhZ3JhbS5hbmRyb2lkXzM4MDcwNjYzNV84NDUzZmFiYQ?_fn=SW5zdGFncmFtXzQwMS4wLjAuNDguNzlfQVBLUHVyZS54YXBr&_p=Y29tLmluc3RhZ3JhbS5hbmRyb2lk&download_id=otr_1746908693767993&is_hot=true&k=b078e841a0b622efb7644c103209bf9b69c4fb78&uu=https://d-23.winudf.com/b/XAPK/Y29tLmluc3RhZ3JhbS5hbmRyb2lkXzM4MDcwNjYzNV84NDUzZmFiYQ?k=9ff891b449dd6237a8851c739b764c0669c4fb78";
        hash = "sha256-Js2NnFcr8lP9+XfxgfylGO8DQBG4eLC2X7jC7EO4Bb8=";
      };

      revancedBundle = "${revanced-patches}/app/revanced/patches/6.1.0/patches-6.1.0.rvp";
    in
    stdenv.mkDerivation {
      pname = "instagram-revanced";
      version = "401.0.0.48.79-patches-6.1.0";

      dontUnpack = true;

      nativeBuildInputs = [
        apkeditor
        revanced-cli
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/instagram-revanced"
        mkdir -p "$workdir"
        cp ${instagramXapk} "$workdir/instagram.xapk"
        chmod u+w "$workdir/instagram.xapk"

        APKEditor m -i "$workdir/instagram.xapk" -o "$workdir/instagram-base.apk"

        revanced-cli patch \
          -b \
          -p ${revancedBundle} \
          -o "$workdir/instagram-revanced.apk" \
          "$workdir/instagram-base.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 "$TMPDIR/instagram-revanced/instagram-revanced.apk" "$out/instagram-revanced.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Patched Instagram APK built with ReVanced patches";
        homepage = "https://github.com/ReVanced/revanced-patches";
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "instagram-revanced.apk";
  signScriptName = "sign-instagram-revanced";
  fdroid = {
    appId = "com.instagram.android";
    metadataYml = ''
      Categories:
        - Internet
      License: Proprietary
      SourceCode: https://github.com/ReVanced/revanced-patches
      IssueTracker: https://github.com/ReVanced/revanced-patches/issues
      AutoName: Instagram ReVanced
      Summary: Patched Instagram APK
      Description: |-
        Instagram ReVanced is a patched Instagram APK built with
        ReVanced patches and kept under the original package name.
    '';
  };
}
