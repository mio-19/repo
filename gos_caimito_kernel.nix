{
  callPackage,
  enableKSU ? true,
  enableLindroid ? true,
  enableDroidspaces ? true,
}:
callPackage ./gos_kernel_common.nix { } {
  pname = "grapheneos-caimito-kernel";
  buildScript = "build_caimito.sh";
  distDir = "caimito";
  inherit enableKSU enableLindroid enableDroidspaces;
}
