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
    hash = "sha256-jEq++YK6cztn68xeFWkd+4/EhviiH2pTbsC8posT+3o=";
  };
in
callPackage ./grapheneos_kernel_common.nix { } {
  pname = "grapheneos-mustang-kernel";
  version = src.tag;
  inherit src;
  buildScript = "build_muzel.sh";
  distDir = "muzel";
  installSubdir = "grapheneos/muzel";
  inherit enableKSU;
  buildCommand = ''
    ./build_muzel.sh --lto=full --repo_manifest="$(realpath .)":"$(realpath aosp_manifest.xml)"
  '';
}
