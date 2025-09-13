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
    rev = "6f4352fd79733f905ae0156a484b8ca293160a3a";
    sha256 = "1cfxbm2c4dbzzjmbfcay1jigz8lshcq67bflp8lnr4030fgyirnl";
  };
}
