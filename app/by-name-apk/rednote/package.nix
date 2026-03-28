{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.rednote;
  mainApk = "rednote.apk";
  signScriptName = "sign-rednote";
  fdroid = {
    appId = "com.xingin.xhs";
    metadataYml = ''
      Categories:
        - Internet
      License: Proprietary
      SourceCode: https://xiaohongshu.cn.uptodown.com/android/dw/1032665165
      IssueTracker: https://xiaohongshu.cn.uptodown.com/android/dw/1032665165
      AutoName: RedNote
      Summary: Patched Xiaohongshu APK
      Description: |-
        RedNote is a patched Xiaohongshu (Little Red Book) APK built with
        LSPatch
    '';
  };
}
