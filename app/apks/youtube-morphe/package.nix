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
        name = "youtube-21.28.204.apk";
        url = "https://web.archive.org/web/20260724082833if_/https://data.winudf.com/APK/Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU2MTE4NTA5M181ZDc0YTMxYw?_p=Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmU%3D&download_id=1691204850574436&filename=YouTube_21.28.204_APKPure.apk&full_size=199012427&is_hot=true&k=3d7b88fbaf3305c7a6312aca48522a426a65c509&package_name=com.google.android.youtube&source=web&token=1784881673-c86bf78fca-0-e6a621791b3c71bdf938b9bb45911f81";
        hash = "sha256-fF+hnxSvX7pt8lPiPMoQyNcYcCikmsOJooinvxJ1hJw=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-morphe";
      version = "21.28.204-patches-${morphe-patches.version}";

      dontUnpack = true;

      nativeBuildInputs = [
        morphe-cli
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/youtube-morphe"
        mkdir -p "$workdir"
        export MORPHE_VERSION_NAME_SUFFIX="-patches-${morphe-patches.version}"

        morphe-cli patch \
          --patches=${morphePatches} \
          --enable="Hide ads" \
          --enable="Change package name" \
          --enable="Disable Play Store updates" \
          --unsigned \
          --temporary-files-path "$workdir/tmp" \
          --out "$workdir/youtube-morphe.apk" \
          ${youtubeApk}

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
