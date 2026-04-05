args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  source.dirs."system/sepolicy".patches = with pkgs; [
    # ERROR: permissive domains not allowed in user builds https://t.me/linux_on_droid/5984 - You could just vandalize the check if you really want user builds: https://t.me/linux_on_droid/13590 - https://github.com/droidng/android_system_sepolicy/commit/b491a953db739aa2daffabc13c9b153d329013ee#diff-8d88eb632967032ab70dc52ece6ec958fb13d818e22d3513130ae177993b2fd7
    ./platform_system_sepolicy-remove-check-of-permissive-.patch
    ./port-su-to-user-builds.patch # not working, needs more work
  ];
}
