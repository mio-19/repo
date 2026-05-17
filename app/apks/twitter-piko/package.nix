{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  morphe-cli,
  piko-patches,
}:
let
  twitterApk = fetchurl {
    name = "twitter-11.77.0-release.0.arm64-v8a.xapk";
    url = "https://web.archive.org/web/20260330045821if_/https://d-e02.winudf.com/b/XAPK/Y29tLnR3aXR0ZXIuYW5kcm9pZF8zMTE3NzAwMDBfNGZiNWE5ZGM?_fn=WF8xMS43Ny4wLXJlbGVhc2UuMF9BUEtQdXJlLnhhcGs&_p=Y29tLnR3aXR0ZXIuYW5kcm9pZA%3D%3D&download_id=1798906392154095&is_hot=true&k=2c6dc823807857949edd405a539aa43a69cb544b&uu=https%3A%2F%2Fd-04.winudf.com%2Fb%2FXAPK%2FY29tLnR3aXR0ZXIuYW5kcm9pZF8zMTE3NzAwMDBfNGZiNWE5ZGM%3Fk%3Db9ad14589f27ef0a765e501dd86cdac869cb544b";
    hash = "sha256-wax+CYRAwnmULxLRQiCkM9L7Z/eoEqxmRuP9SEq/s1Q=";
    # APK mirror harvested from https://apkpure.com/x-formerly-twitter/com.twitter.android/download via the archived download URL above.
  };

  pikoPatches = "${piko-patches}/patches-${piko-patches.version}.mpp";
in
let
  appPackage = stdenv.mkDerivation {
    pname = "twitter-piko";
    version = "11.77.0-release.0-patches-${piko-patches.version}";

    dontUnpack = true;

    nativeBuildInputs = [ morphe-cli ];

    buildPhase = ''
      runHook preBuild

      workdir="$TMPDIR/twitter-piko"
      mkdir -p "$workdir"
      cp ${twitterApk} "$workdir/input.apkm"
      chmod u+w "$workdir/input.apkm"

      morphe-cli patch \
        --patches=${pikoPatches} \
        --unsigned \
        --temporary-files-path "$workdir/tmp" \
        --out "$workdir/twitter-piko.apk" \
        "$workdir/input.apkm"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 "$TMPDIR/twitter-piko/twitter-piko.apk" "$out/twitter-piko.apk"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Twitter patched with the Piko feature bundle";
      homepage = "https://github.com/crimera/piko";
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "twitter-piko.apk";
  signScriptName = "sign-twitter-piko";
  fdroid = {
    appId = "com.twitter.android";
    metadataYml = ''
      Categories:
        - Social Networking
      License: Proprietary
      SourceCode: https://github.com/crimera/piko
      IssueTracker: https://github.com/crimera/piko/issues
      AutoName: Twitter Piko
      Summary: Twitter powered by the Piko patch set for privacy, downloads, and UI tweaks.
      Description: |-
        Twitter Piko wraps the Twitter 11.77.0 release APK with the Piko patch bundle,
        delivering ad suppression, link sanitation, and download actions alongside the upstream experience.
    '';
  };
}
