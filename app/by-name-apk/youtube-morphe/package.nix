{ callPackage, ... }:
let
  appPackage = callPackage (
    {
      lib,
      stdenv,
      fetchurl,
      morphe-cli,
      morphe-patches,
    }:
    let
      youtubeApk = fetchurl {
        # APKPure page: https://apkpure.com/youtube-2025/com.google.android.youtube/download/20.45.36
        name = "youtube-20.45.36.apk";
        url = "https://web.archive.org/web/20260320225634if_/https://d-e03.winudf.com/b/APK/Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU1NzkxNTA3Ml85OTIyYWNmOQ?_fn=WW91VHViZV8yMC40NS4zNl9BUEtQdXJlLmFwaw&_p=Y29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmU%3D&download_id=otr_1725909013636193&is_hot=true&k=9f03bd4e067ebc6cb974ef88609df1a969bf21d9&uu=https%3A%2F%2Fd-15.winudf.com%2Fb%2FAPK%2FY29tLmdvb2dsZS5hbmRyb2lkLnlvdXR1YmVfMTU1NzkxNTA3Ml85OTIyYWNmOQ%3Fk%3D10dfa553ab84c1f507b4e3ee5da6e81069bf21d9";
        hash = "sha256-X9nE2heHhCIXgI1IYPFyE+t+1aS3blZ5m396ZODoCtc=";
      };

      morphePatches = "${morphe-patches}/patches-${morphe-patches.version}.mpp";
    in
    stdenv.mkDerivation {
      pname = "youtube-morphe";
      version = "20.45.36-patches-${morphe-patches.version}";

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
          --enable="Hide ads" \
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
  ) { };
in
callPackage ../../by-name/mk-apk-package/package.nix {
  inherit appPackage;
  mainApk = "youtube-morphe.apk";
  signScriptName = "sign-youtube-morphe";
  fdroid = {
    appId = "app.morphe.android.youtube";
    metadataYml = ''
      Categories:
        - Multimedia
      License: Proprietary
      SourceCode: https://github.com/MorpheApp/morphe-patches
      IssueTracker: https://github.com/MorpheApp/morphe-patches/issues
      AutoName: YouTube Morphe
      Summary: Patched YouTube APK with package rename
      Description: |-
        YouTube Morphe is a patched YouTube APK built with Morphe patches
        and installed under an alternate package name.
    '';
  };
}
