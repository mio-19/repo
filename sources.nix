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
    rev = "3af8e2d601c38c70a504e6c1ea17ac670989f93c";
    sha256 = "0m0sl0wfq01lzqfcag70cir3dqbh1v3i9m1v2n1wj83ywv74gfrg";
  };
}
