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
    rev = "6ae81d3eb257b412acc3663ea64ffc0214c0080e";
    sha256 = "0dbbgaf577l3rb5cgs1zmavi3hszv0y7g0cfxaygwjvzl2hzbcvd";
  };
}
