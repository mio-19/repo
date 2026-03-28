{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.bilibili-cn;
  mainApk = "bilibili-cn.apk";
  signScriptName = "sign-bilibili-cn";
  fdroid = {
    appId = "tv.danmaku.bili";
    metadataYml = ''
      Categories:
        - Video Players & Editors
      License: Proprietary
      SourceCode: https://github.com/yujincheng08/BiliRoaming
      IssueTracker: https://github.com/yujincheng08/BiliRoaming/issues
      AutoName: BiliBili CN
      Summary: BiliBili patched with BiliRoaming via LSPatch
      Description: |-
        BiliBili Roaming embeds the latest BiliRoaming Xposed module
        using LSPatch so the official BiliBili client bypasses region
        locks and gains other enhancements without root.
    '';
  };
}
