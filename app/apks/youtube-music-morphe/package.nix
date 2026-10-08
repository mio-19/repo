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
      youtubeMusicApk = fetchurl {
        name = "YouTube+Music_9.38.51_APKPure.apk";
        url = "https://web.archive.org/web/20261008062955if_/https://data.winudf.com/APK/Y29tLmdvb2dsZS5hbmRyb2lkLmFwcHMueW91dHViZS5tdXNpY185Mzg1MTI0MF9hYmM5MzRhOA?_p=Y29tLmdvb2dsZS5hbmRyb2lkLmFwcHMueW91dHViZS5tdXNpYw%3D%3D&download_id=1215200506134073&filename=YouTube+Music_9.38.51_APKPure.apk&full_size=71937319&is_hot=true&k=a534b9f77200460356a0a335aafcf1926ac9db4c&package_name=com.google.android.apps.youtube.music&source=web&token=1791440972-60d2fbc274-0-63cdb2dd43d6c6ebe0cf96543be58557";
        hash = "sha256-+M0o0rQ//3PaNS3K7QoVqKiOvV8/DTQy3djPep6T+Vs=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-music-morphe";
      version = "9.38.51-patches-${morphe-patches.version}";

      dontUnpack = true;

      nativeBuildInputs = [
        morphe-cli
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/youtube-music-morphe"
        mkdir -p "$workdir"
        export MORPHE_VERSION_NAME_SUFFIX="-patches-${morphe-patches.version}"

        morphe-cli patch \
          --patches=${morphePatches} \
          --enable="Hide 'Get Music Premium'" \
          --enable="Clone app" \
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

      passthru = {
        inherit youtubeMusicApk morphePatches;
      };

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
