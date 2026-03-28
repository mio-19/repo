{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.amethyst;
  mainApk = "amethyst.apk";
  signScriptName = "sign-amethyst";
  fdroid = {
    appId = "org.angelauramc.amethyst";
    metadataYml = ''
      Categories:
        - Games
      License: GPL-3.0-only
      SourceCode: https://github.com/AngelAuraMC/Amethyst-Android
      IssueTracker: https://github.com/AngelAuraMC/Amethyst-Android/issues
      Changelog: https://github.com/AngelAuraMC/Amethyst-Android/commits/v3_openjdk
      AutoName: Amethyst
      Summary: Android launcher for Minecraft Java Edition
      Description: |-
        Amethyst is an Android launcher for Minecraft Java Edition based
        on the PojavLauncher codebase with an updated native stack and
        bundled runtime components.
        This package is built from source from the latest `v3_openjdk`
        branch commit pinned in this repo.
    '';
  };
}
