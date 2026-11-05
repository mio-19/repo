{
  callPackage,
  enableKSU ? true,
  enableLindroid ? true,
  enableUnprotectedKvm ? false,
}:
callPackage ./common.nix { } {
  pname = "grapheneos-pantah-kernel";
  buildScript = "build_pantah.sh";
  distDir = "pantah";
  inherit enableKSU enableLindroid enableUnprotectedKvm;
}
