args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  source.dirs."vendor/adevtool".patches = [
    ./adevtool-bigger-zram.patch # changing here is no effect but mightbe needed somewhere??
    ./adevtool-100p.patch
  ];
  /*
    preBuild = ''
      set -e
      pwd
      cd "vendor/google_devices/${config.device}"
      [ ! -f proprietary/vendor/etc/fstab.zram.100p ]
      [ -f proprietary/vendor/etc/fstab.zram.50p ]
      cp proprietary/vendor/etc/fstab.zram.50p proprietary/vendor/etc/fstab.zram.100p
      substituteInPlace proprietary/vendor/etc/fstab.zram.100p --replace-fail "zramsize=50%" "size=100%"
      substituteInPlace proprietary/vendor/etc/fstab.zram.100p --replace-fail "zram_backingdev_size=1G" "zram_backingdev_size=4G"
      sed -i 's|vendor.zram.size=50p|vendor.zram.size=100p|' sysprop/vendor.prop
      cd -
    '';
  */

}
