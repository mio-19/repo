args@{
  config,
  pkgs,
  lib,
  ...
}:
{

  lindroid-drm = pkgs.fetchgit {
    #url = "https://github.com/Linux-on-droid/lindroid-drm-loopback.git";
    url = "https://github.com/Linux-On-LineageOS/lindroid-drm-loopback.git";
    rev = "01d020e58d5d09d70f37c28a062297a78d9b4f4e";
    sha256 = "1w1g5h3zrhdq3zzk0l0yzy73mjnm9f7xm1qzb29479jcacnck5yk";
  };
  lindroid-drm414 = pkgs.fetchgit {
    url = "https://github.com/mio-19/lindroid-drm-loopback.git";
    rev = "63c0370e64eea4c0545d203ec90c6635ce8d016f";
    sha256 = "1g345l16igsr8kw0m9ix3b36rpi2ynvx3v8li9n6hv23isc3gal8";
  };
}
