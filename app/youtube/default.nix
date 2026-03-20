{
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
}:
let
  youtubeApk = fetchurl {
    # APKPure page: https://apkpure.com/youtube-2025/com.google.android.youtube/download/20.21.37
    name = "youtube-20.21.37.apk";
    url = "https://web.archive.org/web/20260320085821if_/https://d-08.winudf.com/b/APK/Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU1NDc3MTM5Ml82ZTI3MjU5Ng?_fn=WW91VHViZV8yMC4yMS4zN19BUEtQdXJlLmFwaw&_p=Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmU%3D&download_id=otr_1682901765726057&is_hot=false&k=5bc01633e7b1d5e124747a02c4a80f1269be5d9e";
    hash = "sha256-3b85+icp8ycmFu+OVaYTqhf6dSeiX5I/hJstLEQBACo=";
  };

  morphePatches = fetchurl {
    name = "patches-1.19.0.mpp";
    url = "https://github.com/MorpheApp/morphe-patches/releases/download/v1.19.0/patches-1.19.0.mpp";
    hash = "sha256-L40a7MX0TklN3c/13U18jcQXcAYXkYF91IDbBSWsvcg=";
  };
in
stdenv.mkDerivation {
  pname = "youtube-morphe";
  version = "20.21.37-patches-1.19.0";

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
      --enable="Change package name" \
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
}
