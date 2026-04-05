args@{
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
let
  inherit (pkgs) fetchpatch;
in
{
  source.dirs."system/netd".patches = [
    (fetchpatch {
      name = "Fix multiple DNS leaks";
      url = "https://github.com/GrapheneOS/platform_system_netd/pull/16.patch";
      hash = "sha256-qoehzZxMGFLaxwu78D8xS04fic3waqxfO4iSoUHMnSs=";
    })
  ];
  source.dirs."packages/modules/Connectivity".patches = [
    (fetchpatch {
      name = "Fix multiple DNS leaks";
      url = "https://github.com/GrapheneOS/platform_packages_modules_Connectivity/pull/39.patch";
      hash = "sha256-1xuRI3erSBT8VgKpE3qvbDGB2cyOET10Ew66qkvnnFk=";
    })
  ];
  source.dirs."packages/modules/DnsResolver".patches = [
    (fetchpatch {
      name = "Fix multiple DNS leaks";
      url = "https://github.com/GrapheneOS/platform_packages_modules_DnsResolver/pull/14.patch";
      hash = "sha256-Qjlj7BIIuKz9nDTLKLn5MaXFkbzWk1LzBA7VVgBghPQ=";
    })
  ];
}
