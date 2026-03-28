{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.meditrak;
  mainApk = "meditrak.apk";
  signScriptName = "sign-meditrak";
  fdroid = {
    appId = "projects.medicationtracker";
    metadataYml = ''
      Categories:
        - Health & Fitness
      License: GPL-3.0-only
      SourceCode: https://github.com/AdamGuidarini/MediTrak
      IssueTracker: https://github.com/AdamGuidarini/MediTrak/issues
      AutoName: MediTrak
      Summary: Medication tracker
      Description: |-
        MediTrak is a simple, offline medication tracking app.
        Track doses, set reminders, and view history - no account required.
    '';
  };
}
