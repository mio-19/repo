{
  lib,
  runCommand,
}:
rec {
  # https://discourse.nixos.org/t/nix-function-to-merge-attributes-records-recursively-and-concatenate-arrays/2030/9
  deepMerge =
    lhs: rhs:
    lhs
    // rhs
    // (builtins.mapAttrs (
      rName: rValue:
      let
        lValue = lhs.${rName} or null;
      in
      if builtins.isAttrs lValue && builtins.isAttrs rValue then
        deepMerge lValue rValue
      else if builtins.isList lValue && builtins.isList rValue then
        lValue ++ rValue
      else
        rValue
    ) rhs);
  noAsc =
    basic:
    let
      emptyAsc =
        _:
        runCommand "empty.asc" { } ''
          touch $out
        '';
      inherit (lib) mapAttrs' nameValuePair mapAttrs;
      entryNoAsc = entry: mapAttrs' (name: _: nameValuePair (name + ".asc") emptyAsc) entry;
    in
    deepMergeUnique basic (mapAttrs (_: entryNoAsc) basic);
  # based on https://discourse.nixos.org/t/nix-function-to-merge-attributes-records-recursively-and-concatenate-arrays/2030/9
  deepMergeUnique =
    lhs: rhs:
    lhs
    // rhs
    // (builtins.mapAttrs (
      rName: rValue:
      let
        lValue = lhs.${rName} or null;
      in
      if builtins.isAttrs lValue && builtins.isAttrs rValue then
        deepMergeUnique lValue rValue
      else if builtins.isList lValue && builtins.isList rValue then
        lValue ++ rValue
      else if lValue == null then
        rValue
      else
        throw "Conflict at ${rName}: ${lValue} vs ${rValue}"
    ) rhs);
}
