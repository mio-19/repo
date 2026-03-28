{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.nix-on-droid;
  mainApk = "nix-on-droid.apk";
  signScriptName = "sign-nix-on-droid";
  fdroid = {
    appId = "com.termux.nix";
    metadataYml = ''
      Categories:
        - Development
      License: MIT
      WebSite: https://nix-on-droid.unboiled.info
      SourceCode: https://github.com/nix-community/nix-on-droid
      IssueTracker: https://github.com/nix-community/nix-on-droid/issues
      Name: Nix-on-Droid
      AutoName: Nix
      Description: |-
        Nix-on-Droid brings the Nix package manager to Android.

        This app is the terminal-emulator part, built from the
        `nix-on-droid-app` source repository that F-Droid uses for
        the `com.termux.nix` package.

        Nix-on-Droid uses a fork of the Termux application as its
        terminal emulator.
    '';
  };
}
