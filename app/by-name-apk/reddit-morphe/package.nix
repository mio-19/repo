{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
  morphe-patches,
  zip,
  unzip,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.build-tools-35-0-0
      ]);

      redditXapk = fetchurl {
        # APKPure page: https://apkpure.com/reddit-app/com.reddit.frontpage/download/2026.04.0
        name = "reddit-2026.04.0.xapk";
        url = "https://web.archive.org/web/20260407145944if_/https://d-14.winudf.com/b/XAPK/Y29tLnJlZGRpdC5mcm9udHBhZ2VfMjYwNDA0MV8zYTZiNjQxMg?_fn=UmVkZGl0XzIwMjYuMDQuMF9BUEtQdXJlLnhhcGs&_p=Y29tLnJlZGRpdC5mcm9udHBhZ2U%3D&download_id=otr_1559604511559923&is_hot=true&k=5fdfbf8d6daa67af899596a95d08eabf69d66ce6";
        hash = "sha256-8bSHG+zZXj/pWiDztoQR+5PpzrecXHiP9QTty9BOlfA=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "reddit-morphe";
      version = "2026.04.0-patches-${morphe-patches.version}";

      dontUnpack = true;

      nativeBuildInputs = [
        morphe-cli
        unzip
        zip
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/reddit-morphe"

        morphe-cli patch \
          --patches=${morphePatches} \
          --enable="Change package name" \
          --enable="Disable Play Store updates" \
          --unsigned \
          --temporary-files-path "$workdir/tmp" \
          --out "$workdir/reddit-morphe.apk" \
          ${redditXapk}

        ${androidSdk}/share/android-sdk/build-tools/35.0.0/zipalign -P 16 -f 4 \
          "$workdir/reddit-morphe.apk" "$workdir/reddit-morphe-aligned.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 "$TMPDIR/reddit-morphe/reddit-morphe-aligned.apk" "$out/reddit-morphe.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Patched Reddit APK built with Morphe patches";
        homepage = "https://github.com/MorpheApp/morphe-patches";
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "reddit-morphe.apk";
  signScriptName = "sign-reddit-morphe";
  fdroid = {
    appId = "com.reddit.frontpage.morphe";
    metadataYml = ''
      Categories:
        - Internet
      License: Proprietary
      SourceCode: https://github.com/MorpheApp/morphe-patches
      IssueTracker: https://github.com/MorpheApp/morphe-patches/issues
      AutoName: Reddit Morphe
      Summary: Patched Reddit APK with package rename
      Description: |-
        Reddit Morphe is a patched Reddit APK built with Morphe patches
        and installed under an alternate package name.
    '';
  };
}
