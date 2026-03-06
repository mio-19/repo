{
  fetchgit,
  callPackage,
  lib,
  enableKSU ? true,
}:
let
  src = fetchgit {
    url = "https://gitlab.com/grapheneos/kernel_pixel_muzel.git";
    tag = "2026030200";
    fetchSubmodules = true;
    deepClone = false;
    sparseCheckout = [ ];
    hash = lib.fakeHash;
  };
in
callPackage ./grapheneos_kernel_common.nix { } {
  pname = "grapheneos-mustang-kernel";
  version = src.tag;
  inherit src;
  buildScript = "build_muzel.sh";
  distDir = "muzel";
  inherit enableKSU;
}
