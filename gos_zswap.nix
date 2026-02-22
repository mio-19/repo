args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  # changing here is no effect but mightbe needed somewhere??
  source.dirs."vendor/adevtool".patches = [
    ./adevtool-bigger-zram.patch
  ];
  source.dirs."vendor/google_devices/${config.device}".postPatch = ''
    set -e
    cp proprietary/vendor/etc/fstab.zram.50p proprietary/vendor/etc/fstab.zram.100p
    substituteInPlace proprietary/vendor/etc/fstab.zram.100p --replace-fail "zramsize=50%" "size=100%"
    substituteInPlace proprietary/vendor/etc/fstab.zram.100p --replace-fail "zram_backingdev_size=1G" "zram_backingdev_size=4G"
    sed -i 's|vendor.zram.size=50p|vendor.zram.size=100p|' sysprop/vendor.prop
  '';
}
