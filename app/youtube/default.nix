{
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
}:
let
  youtubeApk = fetchurl {
    # APKPure page: https://apkpure.com/youtube-2025/com.google.android.youtube/download/20.41.33
    name = "youtube-20.41.33.apk";
    url = "https://d-02.winudf.com/b/APK/Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU1NzM4NDY0MF9jNmJjYWE3NA?_fn=WW91VHViZV8yMC40MS4zM19BUEtQdXJlLmFwaw&_p=Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmU%3D&download_id=1757304065173054&is_hot=true&k=6be682542ae60781474875130674b28669bcd896";
    hash = "sha256-1Az1GJdBm6wG4AKVpMRZP+8gqfFB1alS215aWZ5UZMM=";
  };

  morphePatches = fetchurl {
    name = "patches-1.19.0.mpp";
    url = "https://github.com/MorpheApp/morphe-patches/releases/download/v1.19.0/patches-1.19.0.mpp";
    hash = "sha256-L40a7MX0TklN3c/13U18jcQXcAYXkYF91IDbBSWsvcg=";
  };
in
stdenv.mkDerivation {
  pname = "youtube-morphe";
  version = "20.41.33-patches-1.19.0";

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
