{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.appstore;
  mainApk = "appstore.apk";
  signScriptName = "sign-appstore";
  fdroid = {
    appId = "app.grapheneos.apps";
    metadataYml = ''
      Categories:
        - System
      License: Apache-2.0
      SourceCode: https://github.com/GrapheneOS/AppStore
      IssueTracker: https://github.com/GrapheneOS/AppStore/issues
      AutoName: GrapheneOS App Store
      Summary: App repository client for GrapheneOS apps
      Description: |-
        GrapheneOS App Store is the client for GrapheneOS app repositories.
        This package is built from source.
    '';
  };
}
