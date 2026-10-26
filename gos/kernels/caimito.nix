{
  callPackage,
  enableKSU ? true,
  pwmmode ? "stock",
  enableLindroid ? true,
  enableDroidspaces ? true,
}:
let
  panelPatch =
    if pwmmode == "0x01" then
      ../../kernel/pixel9pro-stock-0x01.patch
    else if pwmmode == "stock" then
      ""
    else
      throw "invalid pwmmode: ${pwmmode}";
in
callPackage ./common.nix { } {
  pname = "grapheneos-caimito-kernel";
  buildScript = "build_caimito.sh";
  distDir = "caimito";
  inherit enableKSU enableLindroid enableDroidspaces;
  extraBuildCommands = if panelPatch != "" then "apply_patch ${panelPatch}" else "";
}
