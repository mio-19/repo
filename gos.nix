args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  buildDateTime = 1771586071;
  flavor = "grapheneos";
  grapheneos.channel = "alpha";
  source.dirs."frameworks/base".patches = with pkgs; [
    #./No-gestural-navigation-hint-bar.patch

    #./Disable-FLAG_SECURE.patch
    # https://github.com/GrapheneOS/os-issue-tracker/issues/664#issuecomment-3937125786
    (fetchpatch {
      url = "https://github.com/GrapheneOS/platform_frameworks_base/pull/313.patch";
      hash = "sha256-PhOtWmysEnLIF3zPYKJT7tbzPva1UYHuxKvUFGWfDJE=";
    })
  ];
  source.dirs."packages/apps/Settings".patches = with pkgs; [
    # https://github.com/GrapheneOS/os-issue-tracker/issues/664#issuecomment-3937125786
    (fetchpatch {
      url = "https://github.com/GrapheneOS/platform_packages_apps_Settings/pull/411.patch";
      hash = "sha256-ascs+B2SxXrCC6Vj9zGsjtuuyC7xD3YrqaHCy9MXyuY=";
    })
  ];
}
