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
    rev = "d44bfb83c7940f9adf8ee2714d05746f0fc86312"; # pin
    sha256 = "0bdskvx2b135dlf1l1pf7c88ghsjmf4n0prl7z95xmvpsfizz1w9";
  };
}
