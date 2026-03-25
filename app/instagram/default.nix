{
  lib,
  stdenv,
  fetchurl,
  revanced-cli,
  revanced-patches,
  apkeditor,
}:
let
  instagramXapk = fetchurl {
    # APKPure page: https://apkpure.com/instagram-android-2025/com.instagram.android/download
    name = "instagram-422.0.0.44.64.xapk";
    url = "https://web.archive.org/web/20260325091625if_/https://d-e02.winudf.com/b/XAPK/Y29tLmluc3RhZ3JhbS5hbmRyb2lkXzM4MjgwNjM3MF8yZmYzZjFhNw?_fn=SW5zdGFncmFtXzQyMi4wLjAuNDQuNjRfQVBLUHVyZS54YXBr&_p=Y29tLmluc3RhZ3JhbS5hbmRyb2lk&download_id=1995909841835236&is_hot=false&k=ed7cbb6b24130c0f86cfcc7b160448b669c4f95c&uu=https%3A%2F%2Fd-14.winudf.com%2Fb%2FXAPK%2FY29tLmluc3RhZ3JhbS5hbmRyb2lkXzM4MjgwNjM3MF8yZmYzZjFhNw%3Fk%3Df4295fbb812d6d29f7ff537dbd99f29869c4f95c";
    hash = "sha256-4h/ih0fhRO0bl+lVJ2sEx+2w4eaVKK3p/hAevubto4Q=";
  };

  revancedBundle = "${revanced-patches}/app/revanced/patches/6.1.0/patches-6.1.0.rvp";
in
stdenv.mkDerivation {
  pname = "instagram-revanced";
  version = "422.0.0.44.64-patches-6.1.0";

  dontUnpack = true;

  nativeBuildInputs = [
    apkeditor
    revanced-cli
  ];

  buildPhase = ''
    runHook preBuild

    workdir="$TMPDIR/instagram-revanced"
    mkdir -p "$workdir"
    cp ${instagramXapk} "$workdir/instagram.xapk"
    chmod u+w "$workdir/instagram.xapk"

    APKEditor m -i "$workdir/instagram.xapk" -o "$workdir/instagram-base.apk"

    revanced-cli patch \
      -b \
      -p ${revancedBundle} \
      -o "$workdir/instagram-revanced.apk" \
      "$workdir/instagram-base.apk"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 "$TMPDIR/instagram-revanced/instagram-revanced.apk" "$out/instagram-revanced.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Patched Instagram APK built with ReVanced patches";
    homepage = "https://github.com/ReVanced/revanced-patches";
    platforms = platforms.unix;
  };
}
