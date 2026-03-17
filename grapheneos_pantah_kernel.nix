{
  callPackage,
  enableKSU ? true,
  enableLindroid ? true,
}:
callPackage ./grapheneos_kernel_common.nix { } {
  pname = "grapheneos-pantah-kernel";
  buildScript = "build_pantah.sh";
  distDir = "pantah";
  inherit enableKSU enableLindroid;
}
