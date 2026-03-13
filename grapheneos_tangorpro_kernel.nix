{
  callPackage,
  enableKSU ? true,
  enableLindroid ? true,
}:
callPackage ./grapheneos_kernel_common.nix { } {
  pname = "grapheneos-tangorpro-kernel";
  buildScript = "build_tangorpro.sh";
  distDir = "tangorpro";
  inherit enableKSU enableLindroid;
}
