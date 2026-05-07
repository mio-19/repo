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
        # APKPure page: https://apkpure.com/youtube-2025/com.google.android.youtube/download/21.16.256
        name = "youtube-21.16.256.apk";
        url = "https://web.archive.org/web/20260507092807if_/https://d-e03.winudf.com/b/APK/Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU2MTA2ODQxMl9mZGIzNmU1NQ?_fn=WW91VHViZV8yMS4xNi4yNTZfQVBLUHVyZS5hcGs&_p=Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmU%3D&download_id=1890301786123761&is_hot=true&k=b08aa5fb268cbf1a3673f6053e55447769fdac65&uu=https%3A%2F%2Fd-07.winudf.com%2Fb%2FAPK%2FY29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU2MTA2ODQxMl9mZGIzNmU1NQ%3Fk%3Dafdf11c16fa6384c7ceb14c88b7e2d4c69fdac65";
        hash = "sha256-ck0r8V0x2smNsA2CkU2zh27fZuYv4oRQAfIEIJ7PTAA=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-morphe";
      version = "20.45.36-patches-${morphe-patches.version}";

      dontUnpack = true;

      nativeBuildInputs = [
        morphe-cli
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/youtube-morphe"
        mkdir -p "$workdir"
        cp ${youtubeApk} "$workdir/input.apk"
        chmod u+w "$workdir/input.apk"

        morphe-cli patch \
          --patches=${morphePatches} \
          --enable="Hide ads" \
          --enable="Change package name" \
          --enable="Disable Play Store updates" \
          --unsigned \
          --temporary-files-path "$workdir/tmp" \
          --out "$workdir/youtube-morphe.apk" \
          "$workdir/input.apk"

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
