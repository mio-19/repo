{
  callPackage,
  mk-apk-package,
  androidSdkBuilder,
  ...
}:
let
  appPackage =
    let
      lspatch = callPackage ../../by-name/lspatch/common.nix {
        inherit androidSdkBuilder;
      };
    in
    lspatch.manager;
in
mk-apk-package {
  inherit appPackage;
  mainApk = "lspatch-manager.apk";
  signScriptName = "sign-lspatch-manager";
  fdroid = {
    appId = "org.lsposed.lspatch";
    metadataYml = ''
      Categories:
        - Development
        - System
      License: GPL-3.0-only
      WebSite: https://github.com/JingMatrix/LSPatch
      SourceCode: https://github.com/JingMatrix/LSPatch
      IssueTracker: https://github.com/JingMatrix/LSPatch/issues
      AutoName: LSPatch
      Summary: Rootless LSPosed patch manager
      Description: |-
        LSPatch is a rootless implementation of the LSPosed framework.

        This package is the Android manager app built from source.
        The matching CLI jar is also packaged separately in this repo
        as `lspatch-cli`.
    '';
  };
}
