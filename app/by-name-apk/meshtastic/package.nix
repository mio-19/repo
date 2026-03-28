{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.meshtastic;
  mainApk = "meshtastic.apk";
  signScriptName = "sign-meshtastic";
  fdroid = {
    appId = "com.geeksville.mesh";
    metadataYml = ''
      Categories:
        - Internet
      License: GPL-3.0-only
      SourceCode: https://github.com/meshtastic/Meshtastic-Android
      IssueTracker: https://github.com/meshtastic/Meshtastic-Android/issues
      AutoName: Meshtastic
      Summary: Meshtastic mesh networking app
      Description: |-
        Meshtastic is an open-source, off-grid mesh networking application
        using LoRa radios. This is the F-Droid flavor built from source.
    '';
  };
}
