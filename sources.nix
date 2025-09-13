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
    rev = "71fea78ad41e806d0177379b964cf6931d9baa1e";
    sha256 = "14jv9aa85521scnyn6fp683j78zbdr7884i2nf0f4q9vh9r2scbl";
  };
  lindroid-drm414 = pkgs.fetchgit {
    url = "https://github.com/mio-19/lindroid-drm-loopback.git";
    rev = "25ceb92b0ce8b74e8447ca8caafa6d50963818b2";
    sha256 = "09nkr6plvbcz0lzdhh86jb7f9gp0k8jsz85zzr0ipk0hzqgr12vs";
  };
}
