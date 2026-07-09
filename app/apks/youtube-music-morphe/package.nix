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
        # https://youtube-music.en.uptodown.com/android/download/1164645913-x
        name = "youtube-music-8.47.56.apk";
        url = "https://web.archive.org/web/20260507094903if_/https://dw.uptodown.net/dwn/MFhQ8_gxRt-iwo-ip3SSEvXz2URDWbEvJa1VW5E5CY00eaurN8S5euBXJStp8VNfRc6T_8UPIBZzZDDRsjTsw-UsqM4QHo__2GOB25F3d6HKuP_WvTUFqp8vIi110pnN/uMMoLcNJq_uDd3yis7FL-VEta8MdZQXkGUsKlsa7XnAW61zplE8l3J6Myzv8993gAHuHbqcWfSWqbx9d9GNLSjd4TwTmAUV9Bw6tk3mo1Ju6Ze_SBa6aPGjN5gQJBlEn/pxOEgaYm2OPaBFn76E2LzVBd96O6d_0rtEKf0gjLcLbXF9bt0U4fkEUw08SOmschh_mCqlDtxrXCmsilH6qEwenDPf56d17EhJzaeYG2dZY=/youtube-music-8-47-56.apk";
        hash = "sha256-yTTvRQ3TywSpOh6EKmdRJTihAckBFUION8RndH6P7NI=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-music-morphe";
      version = "8.44.54-patches-${morphe-patches.version}";

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
