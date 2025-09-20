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
    rev = "57bea0123c88bbac6b9fab21eb274435d376c54f";
    sha256 = "0nsw3xgm6hk7p36c1yiyqr0ya0j32fly54bxpcs03lxxd52xd2w1";
  };
}
