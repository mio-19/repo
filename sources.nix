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
    rev = "4cb1abe623d5db53b149e06e85119311a9b60a97";
    sha256 = "0jh1kqr598l5ajd3xsdakv2dxywgnnfd8rm372c8nbmr1pn1sm9x";
  };
}
