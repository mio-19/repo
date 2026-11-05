{ config, lib, ... }:
{
  options.enableUnprotectedKvm = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Build the device kernel with kvm-arm.mode=nvhe for Limbo/DroidVM KVM
      guests. This reduces pKVM isolation and requires a compatible device and
      root access for VM applications. See docs/pkvm.md before enabling.
    '';
  };
}
