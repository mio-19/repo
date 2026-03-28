{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.fdroid-basic;
  mainApk = "fdroid-basic.apk";
  signScriptName = "sign-fdroid-basic";
  fdroid = {
    appId = "org.fdroid.basic";
    metadataYml = ''
      Categories:
        - App Store & Updater
        - System
      License: GPL-3.0-or-later
      AuthorName: F-Droid
      AuthorEmail: team@f-droid.org
      WebSite: https://f-droid.org
      SourceCode: https://gitlab.com/fdroid/fdroidclient
      IssueTracker: https://gitlab.com/fdroid/fdroidclient/issues
      Translation: https://hosted.weblate.org/projects/f-droid/f-droid
      Changelog: https://gitlab.com/fdroid/fdroidclient/-/blob/HEAD/CHANGELOG.md
      Donate: https://f-droid.org/donate
      Liberapay: F-Droid-Data
      OpenCollective: F-Droid-Euro
      Bitcoin: bc1qd8few44yaxc3wv5ceeedhdszl238qkvu50rj4v
      AutoName: F-Droid Basic
      Summary: Basic F-Droid client
      Description: |-
        F-Droid Basic is a lightweight client for browsing and installing
        applications from F-Droid repositories.
        This package is built from source.
    '';
  };
}
