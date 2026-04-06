args@{
  pkgs,
  pkgs-unstable,
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
      default = "stock";
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
      (fetchpatch {
        name = "SystemUIProxy: Add onLongPressKeyEvent()";
        url = "https://github.com/LineageOS/android_frameworks_base/commit/bc48bf59e0a30111ffb6001689490cc939290693.patch";
        hash = "sha256-Y/7BV1jJfnAYIWaw387DpQzE8h5lK4S0TRlLRNmNG1Y=";
      })
      (fetchpatch {
        name = "SystemUIProxy: Add onSleepEvent";
        url = "https://github.com/LineageOS/android_frameworks_base/commit/3ca5f9315f722436ef205291fc860c262b602c64.patch";
        hash = "sha256-lt/70GEfBjKbdGu2T3/6OLIRKVQnfwF1u/suMJEAn94=";
      })
      # TODO: check https://github.com/LineageOS/android_frameworks_base/commit/310d180a3cb18d82dccce28c6757cb9427b1cd99
    ];
    source.dirs."packages/apps/Launcher3" =
      if los_fork then
        lib.mkForce {
          src =
            if (config.launcherVariant == "los") then
              sources.lineage_launcher3.src
            else if (config.launcherVariant == "derpfest") then
              sources.derpfest_launcher3.src
            else
              assert config.launcherVariant == "evox";
              sources.evox_launcher3.src;
        }
      else
        assert config.launcherVariant == "stock";
        {
          patches = [
            (fetchpatch {
              name = "allapps: make search bar look good";
              url = "https://github.com/GrapheneOS/platform_packages_apps_Launcher3/pull/69.diff";
              hash = "sha256-sDwsfex93ZiQcVWZ/4GCL69XV/F0p1vONqL8Dy+Tr7I=";
            })
            (fetchpatch {
              name = "Launcher3: Add hasNavigationBar() check.patch";
              url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/bdd98e87d1438e13f95ad4992071ef44fd931695.patch";
              hash = "sha256-Ke0NsftuKxJrDTyAZdj4tOrInNDf2aA2gRd1rs84dsk=";
            })
            (fetchpatch {
              name = "Launcher3: Hide scrollbar when searching All Apps";
              url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/8f2bb1a5685bc043e4b52d7a79291994f8a32078.patch";
              hash = "sha256-ukOdTP5Ks91d5Q8aGjF0h/6tdM2HCHc5vScbtx9CaCk=";
            })
          ];
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
