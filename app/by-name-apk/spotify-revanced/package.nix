{ callPackage, ... }:
let
  appPackage = callPackage (
    {
      lib,
      stdenv,
      fetchurl,
      revanced-cli,
      revanced-patches,
      apkeditor,
    }:
    let
      spotifyXapk = fetchurl {
        # APKPure page: https://apkpure.com/spotify-music-and-podcasts/com.spotify.music/download/9.1.32.2083
        name = "spotify-9.1.32.2083.xapk";
        url = "https://web.archive.org/web/20260321025903/https://d-e03.winudf.com/b/XAPK/Y29tLnNwb3RpZnkubXVzaWNfMTM5NDc1MTg5XzIxZGViZTNi?_fn=U3BvdGlmeTogTXVzaWMgYW5kIFBvZGNhc3RzXzkuMS4zMi4yMDgzX0FQS1B1cmUueGFwaw&_p=Y29tLnNwb3RpZnkubXVzaWM%3D&download_id=otr_1715907518846850&is_hot=true&k=5505c605bbf87eab9b1a349a41d488a969bf5ab0&uu=https%3A%2F%2Fd-30.winudf.com%2Fb%2FXAPK%2FY29tLnNwb3RpZnkubXVzaWNfMTM5NDc1MTg5XzIxZGViZTNi%3Fk%3D147b1654127b66406afd15dbcbe7d32d69bf5ab0";
        hash = "sha256-PkjXF8v+AZIrPfZB5hJgDMKHv/A402fMjD7mGTz6mnQ=";
      };

      revancedBundle = "${revanced-patches}/app/revanced/patches/6.1.0/patches-6.1.0.rvp";
    in
    stdenv.mkDerivation {
      pname = "spotify-revanced";
      version = "9.1.32.2083-patches-6.1.0";

      dontUnpack = true;

      nativeBuildInputs = [
        apkeditor
        revanced-cli
      ];

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/spotify-revanced"
        mkdir -p "$workdir"
        cp ${spotifyXapk} "$workdir/spotify.xapk"
        chmod u+w "$workdir/spotify.xapk"

        APKEditor m -i "$workdir/spotify.xapk" -o "$workdir/spotify-base.apk"

        revanced-cli patch \
          -b \
          -p ${revancedBundle} \
          -o "$workdir/spotify-revanced.apk" \
          "$workdir/spotify-base.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 "$TMPDIR/spotify-revanced/spotify-revanced.apk" "$out/spotify-revanced.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Patched Spotify APK built with ReVanced patches";
        homepage = "https://github.com/ReVanced/revanced-patches";
        platforms = platforms.unix;
      };
    }
  ) { };
in
callPackage ../../by-name/mk-apk-package/package.nix {
  inherit appPackage;
  mainApk = "spotify-revanced.apk";
  signScriptName = "sign-spotify-revanced";
  fdroid = {
    appId = "com.spotify.music";
    metadataYml = ''
      Categories:
        - Multimedia
      License: Proprietary
      SourceCode: https://github.com/ReVanced/revanced-patches
      IssueTracker: https://github.com/ReVanced/revanced-patches/issues
      AutoName: Spotify ReVanced
      Summary: Patched Spotify APK
      Description: |-
        Spotify ReVanced is a patched Spotify APK built with ReVanced
        patches and kept under the original package name.
    '';
  };
}
