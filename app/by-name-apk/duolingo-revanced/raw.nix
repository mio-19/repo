{
  lib,
  stdenv,
  fetchurl,
  revanced-cli,
  revanced-patches,
  apkeditor,
}:
let
  duolingoXapk = fetchurl {
    # APKPure page: https://apkpure.com/duolingo-language-lessons/com.duolingo/download/6.54.5
    name = "duolingo-6.54.5.xapk";
    url = "https://web.archive.org/web/20260324104708if_/https://d-e02.winudf.com/b/XAPK/Y29tLmR1b2xpbmdvXzIyMjdfNTE0MTQzNTY?_fn=RHVvbGluZ286IExhbmd1YWdlIExlc3NvbnNfNi41NC41X0FQS1B1cmUueGFwaw&_p=Y29tLmR1b2xpbmdv&download_id=1416000145532881&is_hot=true&k=635f77521ea42fa7a82014222b1ce48169c3bd20&uu=https%3A%2F%2Fd-12.winudf.com%2Fb%2FXAPK%2FY29tLmR1b2xpbmdvXzIyMjdfNTE0MTQzNTY%3Fk%3D778b7169797f06e1292efe64e49d570269c3bd20";
    hash = "sha256-mXlZL4BqSjOehF/312qvdI1NTTki24CBs/ADDyUHWnE=";
  };

  revancedBundle = "${revanced-patches}/app/revanced/patches/6.1.0/patches-6.1.0.rvp";
in
stdenv.mkDerivation {
  pname = "duolingo-revanced";
  version = "6.54.5-patches-6.1.0";

  dontUnpack = true;

  nativeBuildInputs = [
    apkeditor
    revanced-cli
  ];

  buildPhase = ''
    runHook preBuild

    workdir="$TMPDIR/duolingo-revanced"
    mkdir -p "$workdir"
    cp ${duolingoXapk} "$workdir/duolingo.xapk"
    chmod u+w "$workdir/duolingo.xapk"

    APKEditor m -i "$workdir/duolingo.xapk" -o "$workdir/duolingo-base.apk"

    revanced-cli patch \
      -b \
      -p ${revancedBundle} \
      -o "$workdir/duolingo-revanced.apk" \
      "$workdir/duolingo-base.apk"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 "$TMPDIR/duolingo-revanced/duolingo-revanced.apk" "$out/duolingo-revanced.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Patched Duolingo APK built with ReVanced patches";
    homepage = "https://github.com/ReVanced/revanced-patches";
    platforms = platforms.unix;
  };
}
