{
  callPackage,
  lib,
  stdenv,
  androidSdkBuilder,
  apk,
}:

let
  inherit (callPackage ../fdroid-repo/common.nix { inherit lib stdenv apk; })
    mkFdroidApp
    mkFdroidApkFilter
    ;

  fdroidApks = mkFdroidApkFilter {
    ossOnly = true;
  };
in
callPackage ../fdroid-repo/fdroid-repo.nix {
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.build-tools-36-1-0
  ]);

  apps = lib.mapAttrsToList (_: mkFdroidApp) fdroidApks;

  repoName = "OSS Repo";
  repoDescription = "Unsigned F-Droid repository of open-source apps safe to redistribute";
  repoUrl = "https://mio-19.github.io/fdroid-repo-oss/repo";
}
