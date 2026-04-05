args@{
  config,
  pkgs,
  lib,
  ...
}:
let
  sources = (import ../_sources/generated.nix) {
    inherit (pkgs)
      fetchurl
      fetchgit
      fetchFromGitHub
      dockerTools
      ;
  };
  inherit (pkgs) fetchpatch;
in
{
  options = {
    enableLindroid = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to build Lindroid";
    };
    enableDroidspaces = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to build Droidspaces";
    };
  };
  config = {
    source.dirs."vendor/adevtool".patches = lib.mkIf config.enableLindroid [
      ./adevtool-call-vendor-lindroid.patch
    ];
    source.dirs."frameworks/native".patches = lib.mkIf config.enableLindroid [ ./inputflinger.patch ];
    # to fix soft reboot when starting container on A14 (temporary!!! workaround) https://t.me/linux_on_droid/10346
    source.dirs."frameworks/base".patches = lib.mkIf config.enableLindroid [
      ./16qpr2-Ignore-uevent-s-with-null-name-for-Extcon-WiredAcces.patch
    ];
    source.dirs."vendor/lindroid" = lib.mkIf config.enableLindroid {
      # lindroid-22.1
      src = sources.vendor_lindroid.src;
      # https://t.me/linux_on_droid/18552
      postPatch = ''
        sed -i 's|android.hardware.graphics.common-V5|android.hardware.graphics.common-V7|' interfaces/composer/Android.bp
      '';
      patches = [
        (fetchpatch {
          # https://t.me/linux_on_droid/26461
          name = "perspectived: exempt from init dir mutation";
          url = "https://github.com/yaap/vendor_lindroid/commit/762067a0e9506af5127cd95d96acc3725c05b7d8.patch";
          hash = "sha256-7LTKEWHAXG+EJC5zW1kXdMr1Nrsh0Jr3+3p6pmoSVX4=";
        })
      ];
    };
    source.dirs."external/lxc" = lib.mkIf config.enableLindroid { src = sources.external_lxc.src; };
    source.dirs."libhybris" = lib.mkIf config.enableLindroid { src = sources.libhybris.src; };
    source.dirs."system/sepolicy".patches = lib.mkIf config.enableLindroid [
      (fetchpatch {
        # https://t.me/linux_on_droid/26461
        name = "private/domain: add new attr for relaxing a dir init neverallow";
        url = "https://github.com/yaap/system_sepolicy/commit/d48ff481d9651cedb435a9974648e5c9a81fe211.patch";
        hash = "sha256-bDUOj+NwErgqjM+abpF6ITaz3+GHag+qMoZXsfCv+KI=";
      })
      # https://t.me/linux_on_droid/28140
      # https://github.com/yaap/system_sepolicy/commit/cb883371539af5d127e4a16b05a5ecb425a3c3c3
      ./Allow-perspectived-as-a-permissive-domain.patch
    ];
    source.dirs."build/make".patches = lib.mkIf (config.enableLindroid || config.enableDroidspaces) [
      # VINTF check doesn't like CONFIG_SYSVIPC=y
      ./skip-VINTF-check-for-CONFIG_SYSVIPC.patch # alternatively: sed -i '/# CONFIG_SYSVIPC is not set/d'  */*/android-base.config
    ];
  };
}
