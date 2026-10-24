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
        name = "YouTube+Music_9.40.51_APKPure.apk";
        url = "https://web.archive.org/web/20261024023141if_/https://data.winudf.com/APK/Y29tLmdvb2dsZS5hbmRyb2lkLmFwcHMueW91dHViZS5tdXNpY185NDA1MTI0MF9kMjNkYWYwNQ?_p=Y29tLmdvb2dsZS5hbmRyb2lkLmFwcHMueW91dHViZS5tdXNpYw%3D%3D&download_id=1314607593142374&filename=YouTube+Music_9.40.51_APKPure.apk&full_size=71458416&is_hot=true&k=2cd43ec0b9707b26da2a8a6ed827b9366adebb4d&package_name=com.google.android.apps.youtube.music&source=web&token=1792809037-412e3f524d-0-687606e23f507bf036bc79485fa0f21c";
        hash = "sha256-E3c+Ei2/qkXxj+P6QzpEgewMISA3UOe5e3ZWG6tu5Cs=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-music-morphe";
      version = "9.40.51-patches-${morphe-patches.version}";

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
