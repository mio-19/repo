{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.zotero-android;
  mainApk = "zotero-android.apk";
  signScriptName = "sign-zotero-android";
  fdroid = {
    appId = "org.zotero.android";
    metadataYml = ''
      Categories:
        - Reading
        - Science & Education
      License: AGPL-3.0-only
      WebSite: https://www.zotero.org/
      SourceCode: https://github.com/zotero/zotero-android
      IssueTracker: https://github.com/zotero/zotero-android/issues
      Changelog: https://github.com/zotero/zotero-android/releases
      AutoName: Zotero
      Summary: Sync and manage your Zotero library on Android
      Description: |-
        Zotero is a research assistant for collecting, organizing,
        annotating, and syncing references, PDFs, and notes.

        This package is built from source from the latest upstream tag.
    '';
  };
}
