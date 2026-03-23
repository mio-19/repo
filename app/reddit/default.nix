{
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
  morphe-patches,
  apkeditor,
  zip,
  unzip,
  androidSdkBuilder,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.build-tools-35-0-0
  ]);

  redditXapk = fetchurl {
    # APKPure page: https://apkpure.com/reddit-app/com.reddit.frontpage/download/2026.04.0
    name = "reddit-2026.04.0.xapk";
    url = "https://web.archive.org/web/20260321001122if_/https://d-14.winudf.com/b/XAPK/Y29tLnJlZGRpdC5mcm9udHBhZ2VfMjYwNDA0MV8zYTZiNjQxMg?_fn=UmVkZGl0XzIwMjYuMDQuMF9BUEtQdXJlLnhhcGs&_p=Y29tLnJlZGRpdC5mcm9udHBhZ2U%3D&download_id=otr_1945302452763944&is_hot=true&k=5a05c58f7ddcb913b586d3ab3e9ebac869bf3364";
    hash = "sha256-8bSHG+zZXj/pWiDztoQR+5PpzrecXHiP9QTty9BOlfA=";
  };

  morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
in
stdenv.mkDerivation {
  pname = "reddit-morphe";
  version = "2026.04.0-patches-${morphe-patches.version}";

  dontUnpack = true;

  nativeBuildInputs = [
    apkeditor
    morphe-cli
    unzip
    zip
  ];

  buildPhase = ''
    runHook preBuild

    workdir="$TMPDIR/reddit-morphe"
    mkdir -p "$workdir/input"
    cp ${redditXapk} "$workdir/reddit.xapk"
    chmod u+w "$workdir/reddit.xapk"

    unzip -q "$workdir/reddit.xapk" -d "$workdir/input"

    # Merge the split package into a standalone APK before patching.
    APKEditor m -i "$workdir/input" -o "$workdir/merged.apk"
    cp "$workdir/merged.apk" "$workdir/input.apk"
    chmod u+w "$workdir/input.apk"

    morphe-cli patch \
      --patches=${morphePatches} \
      --enable="Change package name" \
      --unsigned \
      --temporary-files-path "$workdir/tmp" \
      --out "$workdir/reddit-morphe.apk" \
      "$workdir/input.apk"

    ${androidSdk}/share/android-sdk/build-tools/35.0.0/zipalign -P 16 -f 4 \
      "$workdir/reddit-morphe.apk" "$workdir/reddit-morphe-aligned.apk"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 "$TMPDIR/reddit-morphe/reddit-morphe-aligned.apk" "$out/reddit-morphe.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Patched Reddit APK built with Morphe patches";
    homepage = "https://github.com/MorpheApp/morphe-patches";
    platforms = platforms.unix;
  };
}
