args@{ config, pkgs, ... }:
{
  buildDateTime = 1762925552;
  flavor = "grapheneos";
  device = "akita";
  grapheneos.channel = "alpha";
  apps.fdroid.enable = true;
  source.dirs."frameworks/base".patches = [
    # https://github.com/LSPosed/DisableFlagSecure/blob/4b3c477a06f05096af6da1a70941c12418e0d567/app/src/main/java/io/github/lsposed/disableflagsecure/DisableFlagSecure.java
    ./frameworks-base-DisableFlagSecure.patch
  ];
}
