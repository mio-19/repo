{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.spotify-revanced;
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
