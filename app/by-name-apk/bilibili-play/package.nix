{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.bilibili-play;
  mainApk = "bilibili-roaming.apk";
  signScriptName = "sign-bilibili-roaming";
  fdroid = {
    appId = "com.bilibili.app.in";
    metadataYml = ''
      Categories:
        - Video Players & Editors
      License: Proprietary
      SourceCode: https://github.com/yujincheng08/BiliRoaming
      IssueTracker: https://github.com/yujincheng08/BiliRoaming/issues
      AutoName: BiliBili Play
      Summary: BiliBili Google Play version patched with BiliRoaming via LSPatch
      Description: |-
        BiliBili Roaming embeds the latest BiliRoaming Xposed module
        using LSPatch so the official BiliBili client bypasses region
        locks and gains other enhancements without root.
    '';
  };
}
