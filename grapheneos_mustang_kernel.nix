{
  fetchgit,
  callPackage,
  enableKSU ? true,
  enableLindroid ? false,
}:
let
  src = fetchgit {
    url = "https://gitlab.com/grapheneos/kernel_pixel_muzel.git";
    tag = "2026030700";
    fetchSubmodules = true;
    deepClone = false;
    sparseCheckout = [ ];
    hash = "sha256-XuswPXInCQtHy2yl6T16uuWGzd6Kd37QIpnUm0WNbzw=";
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
