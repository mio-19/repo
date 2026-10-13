# Splice the upstream GrapheneOS AVB public key into robotnix factory images.
#
# GrapheneOS generate-factory-images-common.sh copies $AVB_PKMD into the factory
# zip and appends `fastboot erase/flash avb_custom_key` to flash-all.sh and
# flash-all.bat. Robotnix already generates ${signing.avb.key}_pkmd.bin; this
# exports it as AVB_PKMD when releaseScript runs with that keys directory.
#
# Call this from outside the robotnix module system. robotnix is a _module.args
# value, so reading it while computing imports recurses.
{
  lib,
  robotnix,
}:
let
  releaseNix = robotnix.outPath + "/modules/release.nix";
  original = builtins.readFile releaseNix;
  # Keep this snippet in sync with robotnix modules/release.nix factoryImgScript.
  old = "
      \${lib.optionalString (config.flavor == \"grapheneos\") ''
        export DISABLE_UART=\"true\"
        export DISABLE_FIPS=\"true\"
        export DISABLE_DPM=\"true\"
      ''}
";
  new = "
      \${lib.optionalString (config.flavor == \"grapheneos\") ''
        export DISABLE_UART=\"true\"
        export DISABLE_FIPS=\"true\"
        export DISABLE_DPM=\"true\"
        if [[ -f \"\$KEYSDIR/\${config.signing.avb.key}_pkmd.bin\" ]]; then
          export AVB_PKMD=\"\$KEYSDIR/\${config.signing.avb.key}_pkmd.bin\"
        fi
      ''}
";
in
assert lib.assertMsg (lib.hasInfix old original) ''
  robotnix modules/release.nix no longer contains the GrapheneOS factory-image
  environment block. Update gos/avb-custom-key.nix to match.
'';
{
  disabledModules = [ releaseNix ];
  imports = [
    (builtins.toFile "robotnix-release-avb-pkmd.nix" (lib.replaceStrings [ old ] [ new ] original))
  ];
}
