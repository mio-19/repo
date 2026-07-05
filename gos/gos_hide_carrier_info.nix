args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) fetchpatch;
in
{
  options = {
    perAppHideCarrierInfo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to add a per-app setting for hiding carrier/network information.";
    };
  };

  config = lib.mkIf config.perAppHideCarrierInfo {
    source.dirs."frameworks/base".patches = [
      # adapted from https://github.com/GrapheneOS/platform_frameworks_base/pull/394 (marked "dirty";
      # regenerated against the current release with the other GrapheneOS frameworks/base patches
      # applied, since upstream `parse` became `public static` and flag 29 is HIDE_LOCATION_INDICATOR)
      ./hide-carrier-info-frameworks-base.patch
    ];

    source.dirs."packages/apps/Settings".patches = [
      (fetchpatch {
        name = "add per-app hide carrier info setting";
        url = "https://github.com/GrapheneOS/platform_packages_apps_Settings/pull/436.patch";
        hash = "sha256-9jgN6y6bAGbT7pHjEFM4yLSGt4T+Cqny1VFG4TPsVhA=";
      })
    ];

    source.dirs."bionic".patches = [
      (fetchpatch {
        # use combined .diff: the 4-commit .patch series does not apply with GNU patch
        name = "add extended sysprop overrides";
        url = "https://github.com/GrapheneOS/platform_bionic/pull/73.diff";
        hash = "sha256-He0JbjO7Vt47rqeyXJ0fV8ADhvoYYjyvIKkbckZ1xCA=";
      })
    ];

    source.dirs."packages/services/Telephony".patches = [
      (fetchpatch {
        name = "filter out getNetworkCountryIsoForPhone and getSimStateForSlotIndex for hide_carrier_info feature";
        url = "https://github.com/GrapheneOS/platform_packages_services_Telephony/pull/26.patch";
        hash = "sha256-xi4x3/x7YPR2PiOJwAbbcRFNfNSqtHKSZp80Z/tq1fY=";
      })
    ];
  };
}
