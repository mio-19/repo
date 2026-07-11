{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  morphe-cli_1_10_0_dev_9,
  morphe-patches,
}:
let
  appPackage =
    let
      youtubeMusicApk = fetchurl {
        name = "youtube-music-9.25.50_APKPure.apk";
        url = "https://web.archive.org/web/20260711073943if_/https://data.winudf.com/APK/Y29tLmdvb2dsZS5hbmRyb2lkLmFwcHMueW91dHViZS5tdXNpY185MjU1MDI0MF80MTAxOTAzNA?_p=Y29tLmdvb2dsZS5hbmRyb2lkLmFwcHMueW91dHViZS5tdXNpYw%3D%3D&download_id=1024603002796928&filename=YouTube+Music_9.25.50_APKPure.apk&full_size=67702020&is_hot=true&k=c2605596946d1b3733bf611bc4adbdcd6a5495e1&package_name=com.google.android.apps.youtube.music&source=web&token=1783755489-c07846e6dc-0-0d041d9ab9e1e92fe10727380d92c0e8";
        hash = "sha256-5FnbADy/45YSx/hD/OHPKVShgNugxYSl8GJfwNUbEf0=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-music-morphe";
      version = "9.25.50-patches-${morphe-patches.version}";

      dontUnpack = true;

      nativeBuildInputs = [
        morphe-cli_1_10_0_dev_9
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/youtube-music-morphe"
        mkdir -p "$workdir"
        export MORPHE_VERSION_NAME_SUFFIX="-patches-${morphe-patches.version}"

        morphe-cli patch \
          --patches=${morphePatches} \
          --enable="Hide 'Get Music Premium'" \
          --enable="Change package name" \
          --unsigned \
          --temporary-files-path "$workdir/tmp" \
          --out "$workdir/youtube-music-morphe.apk" \
          ${youtubeMusicApk}

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 "$TMPDIR/youtube-music-morphe/youtube-music-morphe.apk" "$out/youtube-music-morphe.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Patched YouTube Music APK built with Morphe patches";
        homepage = "https://github.com/MorpheApp/morphe-patches";
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "youtube-music-morphe.apk";
  signScriptName = "sign-youtube-music-morphe";
  fdroid = {
    appId = "app.morphe.android.apps.youtube.music";
    metadataYml = ''
      Categories:
        - Multimedia
      License: Proprietary
      SourceCode: https://github.com/MorpheApp/morphe-patches
      IssueTracker: https://github.com/MorpheApp/morphe-patches/issues
      AutoName: YouTube Music Morphe
      Summary: Patched YouTube Music APK with package rename
      Description: |-
        YouTube Music Morphe is a patched YouTube Music APK built with
        Morphe patches and installed under an alternate package name.
    '';
  };
}
