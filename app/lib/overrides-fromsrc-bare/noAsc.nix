{
  lib,
  deepMerge,
  runCommand,
}:
basic:
let
  noAsc =
    _:
    runCommand "empty.asc" { } ''
      touch $out
    '';
  inherit (lib) mapAttrs' nameValuePair mapAttrs;
  entryNoAsc = entry: mapAttrs' (name: _: nameValuePair (name + ".asc") noAsc) entry;
in
deepMerge basic (mapAttrs (_: entryNoAsc) basic)
