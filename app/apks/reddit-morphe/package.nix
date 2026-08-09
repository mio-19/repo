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
        name = "reddit-2026.14.0.xapk";
        url = "https://web.archive.org/web/20260809105447/https://data.winudf.com/XAPK/Y29tLnJlZGRpdC5mcm9udHBhZ2VfMjYxNDE0MF8yMTJjOTViYw?_p=Y29tLnJlZGRpdC5mcm9udHBhZ2U%3D&download_id=1402505559203032&filename=Reddit_2026.14.0_APKPure.xapk&full_size=130005156&is_hot=true&k=80a5b404b388d98bf14c8203f58b564c6a7aff32&package_name=com.reddit.frontpage&source=web&token=1786272818-99908d31f8-0-f09009bf47dfa01e110785dff6b98ef4";
        hash = "sha256-reNTTc7+vzjk6cXkMkWJbEyEnKd5tbOaesG1tPUCGkc=";
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
