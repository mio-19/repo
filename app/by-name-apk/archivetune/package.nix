{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.archivetune;
  mainApk = "archivetune.apk";
  signScriptName = "sign-archivetune";
  fdroid = {
    appId = "moe.koiverse.archivetune";
    metadataYml = ''
      AntiFeatures:
        NonFreeNet:
          en-US: Depends on YouTube and YouTube Music.
      Categories:
        - Multimedia
      License: GPL-3.0-only
      SourceCode: https://github.com/koiverse/ArchiveTune
      IssueTracker: https://github.com/koiverse/ArchiveTune/issues
      AutoName: ArchiveTune
      Summary: Privacy-focused YouTube Music client
      Description: |-
        ArchiveTune is a YouTube Music client for Android with offline-friendly
        source packaging, modern Material 3 UI, lyrics support, and playback
        customization features.
        This package is built from source.
    '';
  };
}
