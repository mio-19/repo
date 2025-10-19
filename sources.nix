args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  lindroid-drm = pkgs.fetchgit {
    #url = "https://github.com/Linux-on-droid/lindroid-drm-loopback.git";
    url = "https://github.com/mio-19/lindroid-drm-loopback.git";
    #url = "https://github.com/Linux-On-LineageOS/lindroid-drm-loopback.git";
    rev = "bfa24f48033660e1f470842582e4b241d9622b4d";
    sha256 = "1h9rnd939g5sff127p4mkjks7ddxdzwsr24mzq9bzwk6wakqkbrg";
  };
}
