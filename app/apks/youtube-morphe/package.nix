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
      youtubeApk = fetchurl {
        name = "youtube-21.25.523.xapk";
        url = "https://web.archive.org/web/20260711073652if_/https://data.winudf.com/XAPK/Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU2MTE3OTk3Nl9iZjNkMjMxZQ?_p=Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmU%3D&download_id=1376001748427698&filename=YouTube_21.25.523_APKPure.xapk&full_size=152431534&is_hot=true&k=93e080bdc2bf8f1bfe753e78959a76a56a549569&package_name=com.google.android.youtube&source=web&token=1783755369-9884ee6b38-0-1d3fb56337050385ea862c0aec7acea0";
        hash = "sha256-TmppeMyIEgQrQaa6jKBh8BOJe+Mqjv7gthnC3TV4n0A=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-morphe";
      version = "21.25.523-patches-${morphe-patches.version}";

      dontUnpack = true;

      nativeBuildInputs = [
        morphe-cli_1_10_0_dev_9
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
