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
    rev = "0f2b426ac4787489aab900595bc7ea03165ee012";
    sha256 = "1bxm9rsxmz70p0xcjp6xacb7ihfsrf9w2dfii0vcpk2l9bwjc35z";
  };
}
