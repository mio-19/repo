{
  fdroid-repo-oss,
  androidSdkBuilder,
  python3,
  dejavu_fonts,
  writeShellScriptBin,
  jdk,
  lib,
  fdroidserver,
}:
let
  inherit
    (import ../fdroid-repo/sign-script.nix {
      inherit
        androidSdkBuilder
        python3
        dejavu_fonts
        writeShellScriptBin
        jdk
        lib
        fdroidserver
        ;
      iconFallbackScript = ../sign-fdroid-repo/fdroid-repo-icon-fallback.py;
    })
    mkFdroidRepoSignScript
    ;
in
mkFdroidRepoSignScript {
  name = "sign-fdroid-repo-oss";
  repoPath = "${fdroid-repo-oss}";
  defaultOut = "fdroid-repo-oss-signed";
}
