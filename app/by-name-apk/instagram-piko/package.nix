{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
  piko-patches,
}:
let
  instagramApk = fetchurl {
    name = "instagram-423-0-0-26-66.apk";
    url = "https://web.archive.org/web/20260330043542if_/https://dw.uptodown.net/dwn/7zskvd5g1faKCm6BHNRGzN3N6hjZySBKYyppcYLjyNolqFiELWXBY3z97C0muhAkuARQ8iwDVV2-M2Zt2SRtd_Rddk6O3V6ZFLBLjtPxatIcara_lBZQKzZE_qD8hxMg/UUMTBef2KbVdRyEHO3GJJOQhaEzo7xpc0pxqKbcorVQp-4PFSI0S2dV_ta2cK40Mb_eReFsPqsf9LrP61PYZ9-KhCyEjx7kOig6UC5POKsqP3HlHQEBNeeHYxm-HWH6w/sq04eZ3aopdf0fVv2UAnussPw3e8h73rs2Q87s_4Ew8emq7bhyURLJOXwPyDdYw9qSzuQfHPJjildXyNgwu5KA==/instagram-423-0-0-26-66.apk";
    hash = "sha256-0c3n9v9sqp65w82z6l679q64v6l0q1kl0qkv4x88ynxz7svwcn13";
    # Mirror metadata from https://instagram.en.uptodown.com/android/download/1157536748 via the archived download URL above.
  };

  pikoPatches = "${piko-patches}/patches-${piko-patches.version}.mpp";
in
let
  appPackage = stdenv.mkDerivation {
    pname = "instagram-piko";
    version = "423.0.0.26.66-patches-${piko-patches.version}";

    dontUnpack = true;

    nativeBuildInputs = [ morphe-cli ];

    buildPhase = ''
      runHook preBuild

      workdir="$TMPDIR/instagram-piko"
      mkdir -p "$workdir"
      cp ${instagramApk} "$workdir/input.apk"
      chmod u+w "$workdir/input.apk"

      morphe-cli patch \
        --patches=${pikoPatches} \
        --unsigned \
        --temporary-files-path "$workdir/tmp" \
        --out "$workdir/instagram-piko.apk" \
        "$workdir/input.apk"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 "$TMPDIR/instagram-piko/instagram-piko.apk" "$out/instagram-piko.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Instagram patched with the Piko feature set";
      homepage = "https://github.com/crimera/piko";
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "instagram-piko.apk";
  signScriptName = "sign-instagram-piko";
  fdroid = {
    appId = "com.instagram.android";
    metadataYml = ''
      Categories:
        - Social Networking
      License: Proprietary
      SourceCode: https://github.com/crimera/piko
      IssueTracker: https://github.com/crimera/piko/issues
      AutoName: Instagram Piko
      Summary: Instagram patched with the Piko tweaks, including privacy, download, and productivity options.
      Description: |-
        Instagram Piko wraps the Instagram 423.0.0.26.66 APK with the Piko patch bundle.
        The package ships the upstream Instagram app plus the Piko runtime hooks that enable features such as disabling ads, sanitizing share links, and providing download buttons for feed and reels.
    '';
  };
}
