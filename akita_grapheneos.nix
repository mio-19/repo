args@{ config, pkgs, ... }:
{
  buildDateTime = 1762946435;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = [
    # https://github.com/LSPosed/DisableFlagSecure/blob/4b3c477a06f05096af6da1a70941c12418e0d567/app/src/main/java/io/github/lsposed/disableflagsecure/DisableFlagSecure.java
    #./frameworks-base-DisableFlagSecure.patch
    # https://github.com/VarunS2002/Xposed-Disable-FLAG_SECURE/blob/f35b4c31f7bc593c4d8142d86885b8a35ef5708b/app/src/main/java/com/varuns2002/disable_flag_secure/DisableFlagSecure.kt
    ./Disable-FLAG_SECURE.patch
  ];
}
