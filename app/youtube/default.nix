{
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
}:
let
  youtubeApk = fetchurl {
    name = "youtube-21.11.48.apk";
    url = "https://web.archive.org/web/20260319042759if_/https://d-e03.winudf.com/b/APK/Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU2MTA2MTE1Ml8zNzY5ZmE1MQ?_fn=WW91VHViZV8yMS4xMS40ODNfQVBLUHVyZS5hcGs&_p=Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmU%3D&download_id=1664505587805684&is_hot=true&k=f58a936c9fb4c848b9b9637197d7563a69bccca3&uu=https%3A%2F%2Fd-09.winudf.com%2Fb%2FAPK%2FY29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU2MTA2MTE1Ml8zNzY5ZmE1MQ%3Fk%3D4a5771b46730a90ed65af11222555f6d69bccca3";
    hash = "sha256-wJL32chPEbGoQ/T2BxrWWLAumLEwLvnFeP05yNYHL7M=";
  };

  morphePatches = fetchurl {
    name = "patches-1.19.0.mpp";
    url = "https://github.com/MorpheApp/morphe-patches/releases/download/v1.19.0/patches-1.19.0.mpp";
    hash = "sha256-L40a7MX0TklN3c/13U18jcQXcAYXkYF91IDbBSWsvcg=";
  };
in
stdenv.mkDerivation {
  pname = "youtube-morphe";
  version = "21.11.483-patches-1.19.0";

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
