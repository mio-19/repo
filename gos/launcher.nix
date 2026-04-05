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
in
{
  options = {
    losLauncher = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use los launcher";
    };
  };
  config = {
    source.dirs."vendor/lineage-compat".src = lib.mkIf config.losLauncher ./vendor/lineage-compat;
    source.dirs."packages/apps/Settings".patches = lib.mkIf config.losLauncher [
      ./settings-add-taskbar-navigation-options.patch
    ];
    source.dirs."frameworks/base".patches = lib.mkIf config.losLauncher [
      (fetchpatch {
        name = "SystemUIProxy: Add onLongPressKeyEvent()";
        url = "https://github.com/LineageOS/android_frameworks_base/commit/bc48bf59e0a30111ffb6001689490cc939290693.patch";
        hash = "sha256-Y/7BV1jJfnAYIWaw387DpQzE8h5lK4S0TRlLRNmNG1Y=";
      })
    ];
    source.dirs."packages/apps/Launcher3" =
      if (config.losLauncher) then
        lib.mkForce {
          src = sources.lineage_launcher3.src;
        }
      else
        {
          patches = [
            (fetchpatch {
              name = "allapps: make search bar look good";
              url = "https://github.com/GrapheneOS/platform_packages_apps_Launcher3/pull/69.diff";
              hash = "sha256-sDwsfex93ZiQcVWZ/4GCL69XV/F0p1vONqL8Dy+Tr7I=";
            })
            # cannot find symbol ENABLE_TASKBAR/NAVIGATION_BAR_HINT
            /*
              (fetchpatch {
                # from https://github.com/VoltageOS/packages_apps_Launcher3/commit/6a474287135cb6fc147379efd0c1bfc069f49efd
                name = "Launcher3: Implement taskbar toggle.patch";
                url = "https://github.com/mio-19/platform_packages_apps_Launcher3/commit/381899ea085f2a8f642b7aaebf74bef50daa6d60.patch";
                hash = "sha256-u2EpJIH0QDJuWhuKYjNSKE4GCCpd1FQwd5FnUtca6es=";
              })
              (fetchpatch {
                # from https://github.com/VoltageOS/packages_apps_Launcher3/commit/f445d2b4af7408bf56a168516d2e8c3c71b37cc6
                name = "Launcher3: Implement gesture hint toggle.patch";
                url = "https://github.com/mio-19/platform_packages_apps_Launcher3/commit/7480f89cb0f526d8fb667bfd4972cca826aa70b5.patch";
                hash = "sha256-wxgturb6mCY37A6QL4CAGuoFx9p1IPcAVmZlEtWC06k=";
              })
            */
            (fetchpatch {
              name = "Launcher3: Add hasNavigationBar() check.patch";
              url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/bdd98e87d1438e13f95ad4992071ef44fd931695.patch";
              hash = "sha256-Ke0NsftuKxJrDTyAZdj4tOrInNDf2aA2gRd1rs84dsk=";
            })
            # cannot find symbol CONFIG_HINT_NO_WRAP
            /*
              (fetchpatch {
                name = "Launcher3: Do not wrap icons from icon pack";
                url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/f64b5c694b1b5feee9e77f3dd87c221fccd8eab1.patch";
                hash = "sha256-B75RY2QPeU0vtAWC2+DH9udi4n5lHhpFtfROyE6PqRg=";
              })
            */
            (fetchpatch {
              name = "Launcher3: Hide scrollbar when searching All Apps";
              url = "https://github.com/VoltageOS/packages_apps_Launcher3/commit/8f2bb1a5685bc043e4b52d7a79291994f8a32078.patch";
              hash = "sha256-ukOdTP5Ks91d5Q8aGjF0h/6tdM2HCHc5vScbtx9CaCk=";
            })
          ];
        };
  };
}
