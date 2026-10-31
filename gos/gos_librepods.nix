args@{
  config,
  pkgs,
  lib,
  self,
  ...
}:
{
  options = {
    librepodsAirpodsSupport = lib.mkOption {
      type = lib.types.bool;
      default = false;
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
        apk = "${self.packages.${pkgs.stdenv.hostPlatform.system}.apk_librepods}/librepods.apk";
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
