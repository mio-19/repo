{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.emacs;
  mainApk = "emacs.apk";
  signScriptName = "sign-emacs";
  fdroid = {
    appId = "org.gnu.emacs";
    metadataYml = ''
      Categories:
        - Development
        - Text Editor
        - Writing
      License: GPL-3.0-or-later
      WebSite: https://www.gnu.org/software/emacs/
      SourceCode: https://git.savannah.gnu.org/cgit/emacs.git/tree/
      IssueTracker: https://debbugs.gnu.org/
      Changelog: https://git.savannah.gnu.org/cgit/emacs.git/tree/etc/NEWS?h=master
      Donate: https://my.fsf.org/donate/
      AutoName: Emacs
      Summary: GNU Emacs with Termux shared user ID support
      Description: |-
        GNU Emacs is an extensible, customizable, free/libre text
        editor and Lisp environment.

        This build is compiled from source from the current Emacs 31.0.50
        development snapshot and configured with the shared user ID `com.termux`,
        so it can access the files and executables of the Termux app
        from this repo when both are installed and signed together.

        Install Termux first, then install this Emacs build.
    '';
  };
}
