args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  librepodsApk = pkgs.fetchurl {
    name = "LibrePods-v1.0.4.apk";
    url = "https://github.com/librepods-org/librepods/releases/download/v1.0.4/LibrePods-FOSS-v1.0.4-100040301-release.apk";
    hash = "sha256-gT4uUytFy2GEqHkIuQNuCYRmH4NKOWz3YZ1EP5t021Q=";
  };
in
{
  options = {
    librepodsAirpodsSupport = lib.mkOption {
      type = lib.types.bool;
      default = config.bundleLibrePods;
      description = "Whether to enable Apple VendorID spoofing and L2CAP ERTM compatibility in the Bluetooth stack for LibrePods and AirPods.";
    };

    bundleLibrePods = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to bundle LibrePods as a prebuilt privileged application in GrapheneOS.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.librepodsAirpodsSupport {
      source.dirs."packages/modules/Bluetooth".patches = [
        ./bluetooth-apple-vendorid-and-l2cap.patch
      ];
    })

    (lib.mkIf config.bundleLibrePods {
      apps.prebuilt.librepods = {
        enable = true;
        name = "LibrePods";
        apk = librepodsApk;
        packageName = "me.kavishdevar.librepods";
        privileged = true;
        privappPermissions = [
          "BLUETOOTH_PRIVILEGED"
          "MODIFY_PHONE_STATE"
          "INTERACT_ACROSS_USERS"
          "LOCAL_MAC_ADDRESS"
        ];
      };
    })
  ];
}
