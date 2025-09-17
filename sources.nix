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
    rev = "f3eb5f8ca3e2555c5a642ea8e2eb8268f35d30a3";
    sha256 = "1cmyfw6k0y8my1b4pwhrwyqfg4fri5cjxz352r48yshj4zxsf6dw";
  };
}
