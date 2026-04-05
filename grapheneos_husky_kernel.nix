# # pixel8pro-stock.patch pixel8pro-stock-fix-attempt3.patch lindroid ksu105 0001-daria.patch sidharth-hack.patch
{
  callPackage,
  enableKSU ? false,
  pwmmode ? "0x01", # 0x02 might be too dark under direct sunlight
  adbWritablePanelFreq ? true,
  enableLindroid ? false,
  enableDaria ? enableLindroid,
  enableDroidspaces ? false,
  stdenv,
  lib,
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
in
callPackage ./grapheneos_kernel_common.nix { } {
  pname = "grapheneos-husky-kernel";
  buildScript = "build_shusky.sh";
  distDir = "shusky";
  inherit
    enableKSU
    enableLindroid
    enableDaria
    enableDroidspaces
    ;
  extraBuildCommands = ''
    panel_patch=${panelPatch}
    ${lib.optionalString adbWritablePanelFreq ''
      panel_patch="$TMPDIR/$(basename "$panel_patch")"
      cp ${panelPatch} "$panel_patch"
      chmod u+w "$panel_patch"
      source "${stdenv}/setup"
      substituteInPlace "$panel_patch" \
        --replace-fail "module_param_array(freq_cmd, byte, NULL, 0644);" "module_param_array(freq_cmd, byte, NULL, 0666);" \
        --replace-fail "module_param_array(freq_cmd_ns, byte, NULL, 0644);" "module_param_array(freq_cmd_ns, byte, NULL, 0666);" \
        --replace-fail "module_param_array(freq_cmd_high_brightness, byte, NULL, 0644);" "module_param_array(freq_cmd_high_brightness, byte, NULL, 0666);" \
        --replace-fail "module_param_array(freq_cmd_high_brightness_ns, byte, NULL, 0644);" "module_param_array(freq_cmd_high_brightness_ns, byte, NULL, 0666);" \
        --replace-fail "module_param_array(freq_cmd_hbm, byte, NULL, 0644);" "module_param_array(freq_cmd_hbm, byte, NULL, 0666);" \
        --replace-fail "module_param_array(freq_cmd_hbm_ns, byte, NULL, 0644);" "module_param_array(freq_cmd_hbm_ns, byte, NULL, 0666);" \
        --replace-fail "module_param_array(freq_cmd_hbm_high_brightness, byte, NULL, 0644);" "module_param_array(freq_cmd_hbm_high_brightness, byte, NULL, 0666);" \
        --replace-fail "module_param_array(freq_cmd_hbm_high_brightness_ns, byte, NULL, 0644);" "module_param_array(freq_cmd_hbm_high_brightness_ns, byte, NULL, 0666);"
    ''}

    apply_patch "$panel_patch"
    apply_patch ${./kernel/pixel8pro-stock-fix-attempt3.patch}
  '';
}
