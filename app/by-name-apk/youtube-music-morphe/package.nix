{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
  morphe-patches,
  ...
}:
let
  appPackage =
    let
      youtubeMusicApk = fetchurl {
        # Uptodown page: https://youtube-music.en.uptodown.com/android/download/1122511188
        name = "youtube-music-8.44.54.apk";
        url = "https://web.archive.org/web/20260320232250if_/https://dw.uptodown.net/dwn/rR6WO7qAeWNMQVK2Kv2yN_Xwa4SWIGrnFnokkuiNlSWDAnJEcO2DbmiGf9okDhVlWPcisCrmVJjKb37-OMwkgJqstr1eYW-YkOs4wgg8U7KQgKyh3eAyoSVHgeuC2ElI/jR8t9imqnEeE1DSQxvsKpbySgppdp6ywHykm40yJXaT7upLk7WaRmyyg1VYHRGt-dUU4i_1P0nLWWz2vNmXbP18pwNmnZkXwtUQGYQMMe4eTvf2xyREB8Bh7sKyGFMVl/QjOf1ZYFbUHFcu-Sn937d2-kjFYEf_5D6z7uZjZVK_LJoDXVmYG3UplGHfDqrfbifWd-BrZgwfqjwDH7wRLBLU9Dl53EAvU-FJvLRgFxdKQ=/youtube-music-8-44-54.apk";
        hash = "sha256-y5zjbRRS/M/t9lvPvQY21QXzjMXlUcibiE2Wn4OAYlQ=";
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
        cp ${youtubeMusicApk} "$workdir/input.apk"
        chmod u+w "$workdir/input.apk"

        morphe-cli patch \
          --patches=${morphePatches} \
          --enable="Hide 'Get Music Premium'" \
          --enable="Change package name" \
          --unsigned \
          --temporary-files-path "$workdir/tmp" \
          --out "$workdir/youtube-music-morphe.apk" \
          "$workdir/input.apk"

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
