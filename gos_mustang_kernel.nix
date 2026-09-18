{
  fetchgit,
  callPackage,
  enableKSU ? true,
  enableLindroid ? false,
  pwmmode ? "stock",
}:

let
  panelPatch =
    if pwmmode == "0x01" then
      ./kernel/pixel10-stock-0x01.patch
    else if pwmmode == "stock" then
      ""
    else
      throw "invalid pwmmode: ${pwmmode}";
in
let
  src = fetchgit {
    url = "https://gitlab.com/grapheneos/kernel_pixel_muzel.git";
    tag = "2026091000";
    fetchSubmodules = true;
    deepClone = false;
    sparseCheckout = [ ];
    hash = "sha256-+MeS0MJXWiUVm+AAHUxLA9BUh9JicfWDsRp4ysC8YJM=";
  };
in
callPackage ./gos_kernel_common.nix { } {
  pname = "grapheneos-mustang-kernel";
  inherit src;
  buildScript = "build_muzel.sh";
  distDir = "muzel";
  installSubdir = "grapheneos/muzel";
  inherit enableKSU enableLindroid;
  extraBuildCommands = if panelPatch != "" then "apply_patch ${panelPatch}" else "";
  buildCommand = ''
    ./build_muzel.sh --lto=full --repo_manifest="$(realpath .)":"$(realpath aosp_manifest.xml)"
  '';
}
