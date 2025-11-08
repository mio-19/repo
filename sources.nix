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
    rev = "1c23798ac74939ab4dd02624d7fdea71ae5527ad"; # pin
    sha256 = "1hdvkaa045jk4gq9fixsdlxcdly86xkxwq5iqz87mgnpxjca5vnd";
  };
}
