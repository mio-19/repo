args@{
  pkgs,
  pkgs-unfree,
  lib,
  config,
  self,
  ...
}:
let
  sources = (import ../_sources/generated.nix) {
    inherit (pkgs)
      fetchurl
      fetchgit
      fetchFromGitHub
      dockerTools
      ;
  };
  inherit (pkgs) fetchpatch;
  los_fork =
    config.launcherVariant == "los"
    || config.launcherVariant == "derpfest"
    || config.launcherVariant == "evox";
in
{
  options = {
    launcherVariant = lib.mkOption {
      type = lib.types.enum [
        "stock"
        "los"
        "derpfest"
        "evox"
      ];
      default = "los";
      description = "launcher variant to build";
    };
  };
  config = {
    source.dirs."vendor/lineage-compat".src = lib.mkIf los_fork ./vendor/lineage-compat;
    source.dirs."vendor/derpfest-compat".src = lib.mkIf (
      config.launcherVariant == "derpfest"
    ) ./vendor/derpfest-compat;
    source.dirs."packages/apps/Settings".patches = lib.mkIf los_fork [
      ./settings-add-taskbar-navigation-options.patch
    ];
    source.dirs."frameworks/base".patches = lib.mkIf los_fork [
      # from https://github.com/LineageOS/android_frameworks_base/commit/bc48bf59e0a30111ffb6001689490cc939290693.patch
      ./SystemUIProxy-Add-onLongPressKeyEvent.patch
      # from https://github.com/LineageOS/android_frameworks_base/commit/3ca5f9315f722436ef205291fc860c262b602c64.patch
      ./SystemUIProxy-Add-onSleepEvent.patch
      # TODO: check https://github.com/LineageOS/android_frameworks_base/commit/310d180a3cb18d82dccce28c6757cb9427b1cd99
    ];
    source.dirs."packages/apps/Launcher3" =
      if los_fork then
        lib.mkForce {
          src =
            if (config.launcherVariant == "los") then
              sources.lineage_launcher3_wip.src
            else if (config.launcherVariant == "derpfest") then
              sources.derpfest_launcher3.src
            else
              assert config.launcherVariant == "evox";
              sources.evox_launcher3.src;
          patches = [
            # from https://github.com/GrapheneOS/platform_packages_apps_Launcher3/pull/69.diff
            ./los-allapps-make-search-bar-look-good-https-github.com-G.patch
            (fetchpatch {
              name = "Move IDesktopMode to desktopmode.api";
              url = "https://github.com/GrapheneOS/platform_packages_apps_Launcher3/commit/eacf5cd09f473bbd01bb6bdf3d0ae6296a44b7dc.diff";
              hash = "sha256-PXwyBYBVL8VrVV2ZwuSMuWG7mY+YMmU/SKzH75UwHjc=";
            })
          ]
          ++ lib.optionals (config.launcherVariant == "evox") [
            ./evox-launcher3-add-current-aconfig-flags.patch
          ];
        }
      else
        assert config.launcherVariant == "stock";
        {
          patches = [ ];
        };
  };
}
# derpfest compile failed:
/*
  packages/apps/Launcher3/src/com/android/launcher3/graphics/DrawableFactory.java:42: error: symbol not found com.android.launcher3.util.override.ResourceBasedOverride
  import com.android.launcher3.util.override.ResourceBasedOverride;
         ^
  packages/apps/Launcher3/src/com/android/launcher3/graphics/DrawableFactory.java:47: error: could not resolve ResourceBasedOverride
  public class DrawableFactory implements ResourceBasedOverride {
                                          ^
  packages/apps/Launcher3/src/com/android/launcher3/graphics/DrawableFactory.java:41: error: symbol not found com.android.launcher3.util.override.MainThreadInitializedObject
  import com.android.launcher3.util.override.MainThreadInitializedObject;
         ^
  packages/apps/Launcher3/src/com/android/launcher3/graphics/DrawableFactory.java:49: error: could not resolve MainThreadInitializedObject
      public static final MainThreadInitializedObject<DrawableFactory> INSTANCE =
                          ^
*/
