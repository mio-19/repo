{
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
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
    # APKPure page: https://apkpure.com/reddit-app/com.reddit.frontpage/download/2026.10.0
    name = "reddit-2026.10.0.xapk";
    url = "https://web.archive.org/web/20260321014813/https://d-e03.winudf.com/b/XAPK/Y29tLnJlZGRpdC5mcm9udHBhZ2VfMjYxMDExMV82NDQ3NzhhMA?_fn=UmVkZGl0XzIwMjYuMTAuMF9BUEtQdXJlLnhhcGs&_p=Y29tLnJlZGRpdC5mcm9udHBhZ2U%3D&download_id=otr_1288900400242495&is_hot=false&k=d4e785d5506f5669ef2435f252b6507e69bf4a45&uu=https%3A%2F%2Fd-12.winudf.com%2Fb%2FXAPK%2FY29tLnJlZGRpdC5mcm9udHBhZ2VfMjYxMDExMV82NDQ3NzhhMA%3Fk%3De687161b965656916cbd871934051b1369bf4a45";
    hash = "sha256-0T6VT/G2FU3uvk9RGd17aQJFAqxVF18lbpIzncyEvDw=";
  };

  morphePatches = fetchurl {
    name = "patches-1.20.0.mpp";
    url = "https://github.com/MorpheApp/morphe-patches/releases/download/v1.20.0/patches-1.20.0.mpp";
    hash = "sha256-r65NcSLhRPEnWnCsVjzzt5gmNElovpjTs0VKY2375Hs=";
  };
in
stdenv.mkDerivation {
  pname = "reddit-morphe";
  version = "2026.10.0-patches-1.20.0";

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
