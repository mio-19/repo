{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.koreader;
  mainApk = "koreader.apk";
  signScriptName = "sign-koreader";
  fdroid = {
    appId = "org.koreader.launcher.fdroid";
    metadataYml = ''
      Categories:
        - Reading
      License: AGPL-3.0-only
      SourceCode: https://github.com/koreader/koreader
      IssueTracker: https://github.com/koreader/koreader/issues
      AutoName: KOReader
      Summary: Ebook reader optimized for e-ink and Android devices
      Description: |-
        KOReader is a document reader supporting EPUB, PDF, DJVU and more.
        This package is built from source.
    '';
  };
}
