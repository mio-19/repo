# # pixel8pro-stock.patch pixel8pro-stock-fix-attempt3.patch lindroid ksu105 0001-daria.patch sidharth-hack.patch
{
  callPackage,
  enableKSU ? false,
  pwmmode ? "0x01", # 0x02 might be too dark under direct sunlight
  adbWritablePanelFreq ? true,
  enableLindroid ? false,
  enableDaria ? enableLindroid,
  enableDroidspaces ? false,
  runCommand,
}:
let
  panelPatch =
    if pwmmode == "0x01" then
      ./kernel/pixel8pro-stock-0x01.patch
    else if pwmmode == "0x02" then
      ./kernel/pixel8pro-stock-0x02.patch
    else if pwmmode == "0x05" then
      ./kernel/pixel8pro-stock-0x05.patch
    else if pwmmode == "3840Hz" then
      ./kernel/pixel8pro-stock-3840Hz.patch
    else if pwmmode == "stock" then
      ./kernel/pixel8pro-stock.patch
    else
      throw "invalid pwmmode: ${pwmmode}";
  patchedPanelPatch =
    if adbWritablePanelFreq then
      runCommand "pixel8pro-panel-patch-${pwmmode}-adb-writable.patch" { } ''
        cp ${panelPatch} "$out"
        chmod u+w "$out"
        substituteInPlace "$out" \
          --replace-fail "module_param_array(freq_cmd, byte, NULL, 0644);" "module_param_array(freq_cmd, byte, NULL, 0664);"
      ''
    else
      panelPatch;
in
callPackage ./grapheneos_kernel_common.nix { } {
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
    apply_patch ${patchedPanelPatch}
    apply_patch ${./kernel/pixel8pro-stock-fix-attempt3.patch}
  '';
}
