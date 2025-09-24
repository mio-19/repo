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
    rev = "6dc67b3128a54e387170b50c13037e4370d06751";
    sha256 = "038s6wva9i6rz9kkz2p9b16172f05lwcnm8vxmwkxrjsb87ikw2b";
  };
}
