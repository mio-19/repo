{
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
}:
let
  youtubeMusicApk = fetchurl {
    # Uptodown page: https://youtube-music.en.uptodown.com/android/download/1122511188
    name = "youtube-music-8.44.54.apk";
    url = "https://web.archive.org/web/20260320232250if_/https://dw.uptodown.net/dwn/rR6WO7qAeWNMQVK2Kv2yN_Xwa4SWIGrnFnokkuiNlSWDAnJEcO2DbmiGf9okDhVlWPcisCrmVJjKb37-OMwkgJqstr1eYW-YkOs4wgg8U7KQgKyh3eAyoSVHgeuC2ElI/jR8t9imqnEeE1DSQxvsKpbySgppdp6ywHykm40yJXaT7upLk7WaRmyyg1VYHRGt-dUU4i_1P0nLWWz2vNmXbP18pwNmnZkXwtUQGYQMMe4eTvf2xyREB8Bh7sKyGFMVl/QjOf1ZYFbUHFcu-Sn937d2-kjFYEf_5D6z7uZjZVK_LJoDXVmYG3UplGHfDqrfbifWd-BrZgwfqjwDH7wRLBLU9Dl53EAvU-FJvLRgFxdKQ=/youtube-music-8-44-54.apk";
    hash = "sha256-y5zjbRRS/M/t9lvPvQY21QXzjMXlUcibiE2Wn4OAYlQ=";
  };

  morphePatches = fetchurl {
    name = "patches-1.20.0.mpp";
    url = "https://github.com/MorpheApp/morphe-patches/releases/download/v1.20.0/patches-1.20.0.mpp";
    hash = "sha256-r65NcSLhRPEnWnCsVjzzt5gmNElovpjTs0VKY2375Hs=";
  };
in
stdenv.mkDerivation {
  pname = "youtube-music-morphe";
  version = "8.44.54-patches-1.20.0";

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
}
