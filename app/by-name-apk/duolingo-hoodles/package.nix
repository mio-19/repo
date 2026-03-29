{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
  hoodles-patches,
  apkeditor,
  zip,
  unzip,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.build-tools-35-0-0
      ]);

      duolingoXapk = fetchurl {
        name = "duolingo-6.66.5.xapk";
        url = "https://web.archive.org/web/20260329035920if_/https://d-e02.winudf.com/b/XAPK/Y29tLmR1b2xpbmdvXzIyOTNfZTVhYjFmOGY?_fn=RHVvbGluZ286IExhbmd1YWdlIExlc3NvbnNfNi42Ni41X0FQS1B1cmUueGFwaw&_p=Y29tLmR1b2xpbmdv&download_id=1237403174754415&is_hot=true&k=c7bac36b8b194fc6fcfe8c3bccc381b469c9f50b&uu=https%3A%2F%2Fd-07.winudf.com%2Fb%2FXAPK%2FY29tLmR1b2xpbmdvXzIyOTNfZTVhYjFmOGY%3Fk%3De8d3d257f004040d51eb2cbf0c3a437769c9f50b";
        hash = "sha256-81BXWJ9Ozj0wxSFkLLB5ZHP4KbmTuLpWP0cDOV7nzv8=";
      };

      hoodlesPatches = "${hoodles-patches}/patches-${hoodles-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "duolingo-hoodles";
      version = "6.66.5-patches-${hoodles-patches.version}";

      dontUnpack = true;

      nativeBuildInputs = [
        apkeditor
        morphe-cli
        unzip
        zip
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/duolingo-hoodles"
        mkdir -p "$workdir/input"

        # Merge the split package into a standalone APK before patching.
        APKEditor m -i ${duolingoXapk} -o "$workdir/input.apk"

        morphe-cli patch \
          --patches=${hoodlesPatches} \
          --unsigned \
          --temporary-files-path "$workdir/tmp" \
          --out "$workdir/duolingo-hoodles.apk" \
          "$workdir/input.apk"

        ${androidSdk}/share/android-sdk/build-tools/35.0.0/zipalign -P 16 -f 4 \
          "$workdir/duolingo-hoodles.apk" "$workdir/duolingo-hoodles-aligned.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 "$TMPDIR/duolingo-hoodles/duolingo-hoodles-aligned.apk" "$out/duolingo-hoodles.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Patched Duolingo APK built with Hoodles patches";
        homepage = "https://github.com/hoo-dles/morphe-patches";
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "duolingo-hoodles.apk";
  signScriptName = "sign-duolingo-hoodles";
  fdroid = {
    appId = "com.duolingo.hoodles";
    metadataYml = ''
      Categories:
        - Education
      License: Proprietary
      SourceCode: https://github.com/hoo-dles/morphe-patches
      IssueTracker: https://github.com/hoo-dles/morphe-patches/issues
      AutoName: Duolingo Hoodles
      Summary: Patched Duolingo APK with package rename
      Description: |-
        Duolingo Hoodles is a patched Duolingo APK built with Hoodles patches
        and installed under an alternate package name.
    '';
  };
}
