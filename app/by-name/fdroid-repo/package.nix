{
  callPackage,
  lib,
  stdenv,
  androidSdkBuilder,
  apk,
}:

let
  inherit (callPackage ./common.nix { inherit lib stdenv apk; })
    mkFdroidApp
    mkFdroidApkFilter
    ;

  fdroidApks = mkFdroidApkFilter { };
in
callPackage ./fdroid-repo.nix {
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-1-0
  ]);

  apps = lib.mapAttrsToList (_: mkFdroidApp) fdroidApks;

  repoName = "Unofficial Repo";
  repoDescription = "Unsigned F-Droid repository";
  repoUrl = "https://mio-19.github.io/fdroid-repo/repo";
}
