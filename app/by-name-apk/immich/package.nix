{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.immich;
  mainApk = "immich.apk";
  signScriptName = "sign-immich";
}
