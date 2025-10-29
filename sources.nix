args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  lindroid-drm = pkgs.fetchgit {
    url = "https://github.com/Linux-on-droid/lindroid-drm-loopback.git";
    #url = "https://github.com/mio-19/lindroid-drm-loopback.git";
    #url = "https://github.com/Linux-On-LineageOS/lindroid-drm-loopback.git";
    rev = "53ecac1e2b49bbf947e9068f988779578cf803aa";
    sha256 = "1hdvkaa045jk4gq9fixsdlxcdly86xkxwq5iqz87mgnpxjca5vnd";
  };
}
