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
    rev = "23e6e56ef522bc429247c60009dff83432f64585";
    sha256 = "1wdppx4425snkp5ag6s9wbh384a6dfh5k6phc84qzw718xx6fza4";
  };
}
