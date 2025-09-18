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
    rev = "da7872dbe08f22bc809a2ba3e0271e3b62014cce";
    sha256 = "06s21m80nyvzbp99amgmwrqvjslb4wjidg057wzy1s1kamr7sj6x";
  };
}
