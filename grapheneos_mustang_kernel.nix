{
  fetchgit,
  callPackage,
  enableKSU ? true,
  enableLindroid ? false,
}:
let
  src = fetchgit {
    url = "https://gitlab.com/grapheneos/kernel_pixel_muzel.git";
    tag = "2026040300";
    fetchSubmodules = true;
    deepClone = false;
    sparseCheckout = [ ];
    hash = "";
  };
in
callPackage ./grapheneos_kernel_common.nix { } {
  pname = "grapheneos-mustang-kernel";
  inherit src;
  buildScript = "build_muzel.sh";
  distDir = "muzel";
  installSubdir = "grapheneos/muzel";
  inherit enableKSU enableLindroid;
  buildCommand = ''
    ./build_muzel.sh --lto=full --repo_manifest="$(realpath .)":"$(realpath aosp_manifest.xml)"
  '';
}
