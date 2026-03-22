args@{
  pkgs,
  pkgs-unstable,
  lib,
  self,
  ...
}:
{
  source.dirs."frameworks/base".patches = with pkgs; [
    (fetchpatch {
      name = "platform_frameworks_base: Allow Apple's servers for captive portal check";
      url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/329.patch";
      hash = "sha256-Ti9+k2+q0qjxS6xbeXw/WEKBXKsheCYpvVi8tAYly5Y=";
    })
  ];
  source.dirs."packages/modules/NetworkStack".patches = with pkgs; [
    (fetchpatch {
      name = "platform_packages_modules_NetworkStack: Allow Apple's servers for captive portal check";
      url = "https://github.com/GrapheneOS/platform_packages_modules_NetworkStack/pull/18.patch";
      hash = "sha256-TViWdVRnM1Q1L0W7827/vdodrS+Z3icYX0DtP96iiuU=";
    })
  ];
  source.dirs."packages/apps/Settings".patches = with pkgs; [
    (fetchpatch {
      name = "platform_packages_apps_Settings: Allow Apple's servers for captive portal check";
      url = "https://github.com/GrapheneOS/platform_packages_apps_Settings/pull/420.patch";
      hash = "sha256-EBoT8mVj+jgF+x6zKzdKc0n2ASdZd3MXvVtc/f0kYTo=";
    })
  ];
}
