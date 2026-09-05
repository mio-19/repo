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
        name = "YouTube+Music_9.32.51_APKPure.apk";
        url = "https://web.archive.org/web/20260904152310if_/https://data.winudf.com/APK/Y29tLmdvb2dsZS5hbmRyb2lkLmFwcHMueW91dHViZS5tdXNpY185MzI1MTI0MF85ZDg1OTBiNg?_p=Y29tLmdvb2dsZS5hbmRyb2lkLmFwcHMueW91dHViZS5tdXNpYw%3D%3D&download_id=1697404625424858&filename=YouTube+Music_9.32.51_APKPure.apk&full_size=70915435&is_hot=true&k=ce51d3b0838f8c78498b1d42fcc017fe6a9d8524&package_name=com.google.android.apps.youtube.music&source=web&token=1788535332-dcedb6a821-0-7aeed35d623eee774f91ae49baee9fdf";
        hash = "sha256-X8GUVKm7kh2eugAXiFUdRomNHB/hibIKye0SquIJJXQ=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-music-morphe";
      version = "9.32.51-patches-${morphe-patches.version}";

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
