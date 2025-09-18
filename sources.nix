args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  lindroid-drm = pkgs.fetchgit {
    url = "https://github.com/Linux-on-droid/lindroid-drm-loopback.git";
    #url = "https://github.com/Linux-On-LineageOS/lindroid-drm-loopback.git";
    rev = "bfcfb9d5609894b0fd122f6c3e2cf5a48d3ebcaf";
    sha256 = "021wwvf4db47cpl8gbkgn4xkm36rvyybzhmr8jijkrp2zjyl372s";
  };
}
