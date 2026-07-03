{
  fdroid-repo-oss,
  writeShellScriptBin,
  jdk,
  androidSdkBuilder,
}:
let
  inherit
    (import ../fdroid-repo/keystore-update-script.nix {
      inherit writeShellScriptBin jdk androidSdkBuilder;
    })
    mkFdroidKeystoreUpdateScript
    ;
in
mkFdroidKeystoreUpdateScript {
  name = "fdroid-keystore-update-oss";
  repoPath = "${fdroid-repo-oss}";
}
