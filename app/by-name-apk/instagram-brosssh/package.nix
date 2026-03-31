# unstable
{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
  brosssh-patches,
}:
let
  # https://github.com/brosssh/morphe-patches/blob/580cb29062367ad5927689525da65c46f7d14592/patches/src/main/kotlin/app/morphe/patches/instagram/Constants.kt#L12
  # https://www.apkmirror.com/apk/instagram/instagram-instagram/instagram-422-0-0-0-35-release/
  instagramApkm = fetchurl {
    name = "com.instagram.android_422.0.0.0.35-382802000_1dpi_96159fb56bda5f000926e3d17ee14815_apkmirror.com.apkm";
    url = "https://web.archive.org/web/20260331053744if_/https://eb5e7388c3df147b74dd2379b7cf8323.r2.cloudflarestorage.com/downloadprod/wp-content/uploads/2026/03/07/69b79ab7695ee/com.instagram.android_422.0.0.0.35-382802000_1dpi_96159fb56bda5f000926e3d17ee14815_apkmirror.com.apkm?X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=72a5ba3a0b8a601e535d5525f12f8177%2F20260331%2Fauto%2Fs3%2Faws4_request&X-Amz-Date=20260331T053635Z&X-Amz-SignedHeaders=host&X-Amz-Expires=3600&X-Amz-Signature=8951c9b037912b0cc88d487edd1972b950b01eb6028841d02c963a847e6fdb63";
    hash = "sha256-aGlqKHXI7Nl+SzTJawlaqe3aLIkwriU6kyXQdkBSSTI=";
  };

  brossshPatches = "${brosssh-patches}/patches-${brosssh-patches.version}.mpp";
in
let
  appPackage = stdenv.mkDerivation {
    pname = "instagram-brosssh";
    version = "422.0.0.0.35-patches-${brosssh-patches.version}";

    dontUnpack = true;

    buildPhase = ''
      runHook preBuild

      workdir="$TMPDIR/instagram-brosssh"
      mkdir -p "$workdir"
      cp ${instagramApkm} "$workdir/input.apkm"
      chmod u+w "$workdir/input.apkm"

      ${lib.getExe morphe-cli} patch \
        --patches=${brossshPatches} \
        --unsigned \
        --enable="Sanitize sharing URLs" \
        --enable="Disable analytics" \
        --enable="Hide Stories from Home" \
        --enable="Open links externally" \
        --temporary-files-path "$workdir/tmp" \
        --out "$workdir/instagram-brosssh.apk" \
        "$workdir/input.apkm"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 "$TMPDIR/instagram-brosssh/instagram-brosssh.apk" "$out/instagram-brosssh.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Instagram patched with the Brosssh feature set";
      homepage = "https://github.com/brosssh/morphe-patches";
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "instagram-brosssh.apk";
  signScriptName = "sign-instagram-brosssh";
  fdroid = {
    appId = "com.instagram.android";
    metadataYml = ''
      Categories:
        - Social Networking
      License: Proprietary
      SourceCode: https://github.com/crimera/piko
      IssueTracker: https://github.com/crimera/piko/issues
      AutoName: Instagram Brosssh
      Summary: Instagram patched with the Brosssh tweaks, including privacy, download, and productivity options.
      Description: |-
        Instagram Brosssh wraps the Instagram 423.0.0.26.66 APK with the Brosssh patch bundle.
        The package ships the upstream Instagram app plus the Brosssh runtime hooks that enable features such as disabling ads, sanitizing share links, and providing download buttons for feed and reels.
    '';
  };
}
