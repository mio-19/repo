{
  callPackage,
  enableKSU ? true,
  enableLindroid ? true,
  enableDroidspaces ? true,
  enableUnprotectedKvm ? false,
}:
callPackage ./common.nix { } {
  pname = "grapheneos-tangorpro-kernel";
  buildScript = "build_tangorpro.sh";
  distDir = "tangorpro";
  inherit
    enableKSU
    enableLindroid
    enableDroidspaces
    enableUnprotectedKvm
    ;
}
