args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  source.dirs."vendor/adevtool".patches = [ ./adevtool-call-vendor-lindroid.patch ];
  source.dirs."frameworks/native".patches = [ ./inputflinger.patch ];
  # to fix soft reboot when starting container on A14 (temporary!!! workaround) https://t.me/linux_on_droid/10346
  source.dirs."frameworks/base".patches = [
    ./16qpr2-Ignore-uevent-s-with-null-name-for-Extcon-WiredAcces.patch
  ];
  source.dirs."vendor/lindroid" = {
    src = pkgs.fetchFromGitHub {
      # lindroid-22.1
      owner = "Linux-on-droid";
      repo = "vendor_lindroid";
      rev = "279f7f4dca7fdae757be74febd5bf7630f416737";
      hash = "sha256-mZowr9x1wKeJC956bl095HtAK/2t7NHMuC0+QXCQRpM=";
    };
    # https://t.me/linux_on_droid/18552
    postPatch = ''
      sed -i 's|android.hardware.graphics.common-V5|android.hardware.graphics.common-V7|' interfaces/composer/Android.bp
    '';
    patches = with pkgs; [
      (fetchpatch {
        # https://t.me/linux_on_droid/26461
        name = "perspectived: exempt from init dir mutation";
        url = "https://github.com/yaap/vendor_lindroid/commit/762067a0e9506af5127cd95d96acc3725c05b7d8.patch";
        hash = "sha256-7LTKEWHAXG+EJC5zW1kXdMr1Nrsh0Jr3+3p6pmoSVX4=";
      })
    ];
  };
  source.dirs."external/lxc".src = pkgs.fetchFromGitHub {
    owner = "Linux-on-droid";
    repo = "external_lxc";
    # lindroid-21
    rev = "4e3a3630fff3dc04e0d4a761309f87f248e40b17";
    hash = "sha256-lh/YEh1ubAW51GKFZiraQZqbGGkdT6zuSVunDRAaKbE=";
  };
  source.dirs."libhybris".src = pkgs.fetchFromGitHub {
    owner = "Linux-on-droid";
    repo = "libhybris";
    # lindroid-21
    rev = "419f3ff6736e01cb0e579f65a34c85cfa7de578b";
    hash = "sha256-h9QmJ/uZ2sHMGX3/UcxD+xe/myONacKwoBhmn0RK5sI=";
  };
  source.dirs."system/sepolicy".patches = with pkgs; [
    (fetchpatch {
      # https://t.me/linux_on_droid/26461
      name = "private/domain: add new attr for relaxing a dir init neverallow";
      url = "https://github.com/yaap/system_sepolicy/commit/d48ff481d9651cedb435a9974648e5c9a81fe211.patch";
      hash = "sha256-bDUOj+NwErgqjM+abpF6ITaz3+GHag+qMoZXsfCv+KI=";
    })
    (fetchpatch {
      # https://t.me/linux_on_droid/28140
      name = "Allow perspectived as a permissive domain";
      url = "https://github.com/yaap/system_sepolicy/commit/cb883371539af5d127e4a16b05a5ecb425a3c3c3.patch";
      hash = "sha256-9uTl/63Ua1LkFMXRkB6jJcegZTvlmb0L6cq7+W+VgVU=";
    })
  ];
}
