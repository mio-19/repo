# # pixel8pro-stock.patch pixel8pro-stock-fix-attempt3.patch lindroid ksu105 0001-daria.patch sidharth-hack.patch
{
  callPackage,
  enableKSU ? false,
  pwmmode ? "stock",
  enableLindroid ? false,
  enableDaria ? enableLindroid,
  enableDroidspaces ? false,
}:
let
  panelPatch =
    if pwmmode == "0x01" then
      ./kernel/pixel8pro-stock-0x01.patch
    else if pwmmode == "0x02" then
      # 0x02 might be too dark under direct sunlight
      ./kernel/pixel8pro-stock-0x02.patch
    else if pwmmode == "0x05" then
      ./kernel/pixel8pro-stock-0x05.patch
    else if pwmmode == "3840Hz" then
      ./kernel/pixel8pro-stock-3840Hz.patch
    else if pwmmode == "stock" then
      ./kernel/pixel8pro-stock.patch
    else
      throw "invalid pwmmode: ${pwmmode}";
in
callPackage ./gos_kernel_common.nix { } {
  pname = "grapheneos-shusky-kernel";
  buildScript = "build_shusky.sh";
  distDir = "shusky";
  inherit
    enableKSU
    enableLindroid
    enableDaria
    enableDroidspaces
    ;
  extraBuildCommands = ''
    apply_patch ${panelPatch}
    apply_patch ${./kernel/pixel8pro-stock-fix-attempt3.patch}
  '';
}
