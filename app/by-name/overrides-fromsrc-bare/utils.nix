{
  lib,
  runCommand,
}:
let
  inherit (lib) recursiveUpdateUntil assertMsg;
  isAttrsNotDer = x: builtins.isAttrs x && !lib.isDerivation x;
in
rec {
  inherit isAttrsNotDer;
  noAsc =
    basic:
    let
      emptyAsc =
        _:
        runCommand "empty.asc" { } ''
          touch $out
        '';
      inherit (lib) mapAttrs' nameValuePair mapAttrs;
      # TODO: don't add .asc for entries that already have an .asc
      entryNoAsc = entry: mapAttrs' (name: _: nameValuePair (name + ".asc") emptyAsc) entry;
    in
    deepMerge (mapAttrs (_: entryNoAsc) basic) basic;
  # https://noogle.dev/f/lib/recursiveUpdate
  deepMerge =
    lhs: rhs:
    recursiveUpdateUntil (
      path: lhs: rhs:
      !(isAttrsNotDer lhs && isAttrsNotDer rhs)
    ) lhs rhs;
  # https://noogle.dev/f/lib/recursiveUpdate
  deepMergeUnique =
    lhs: rhs:
    recursiveUpdateUntil (
      path: lhs: rhs:
      assert assertMsg (
        isAttrsNotDer lhs && isAttrsNotDer rhs
      ) "Conflict at ${lib.concatStringsSep "." path}";
      false
    ) lhs rhs;
}
// rec {
  # https://discourse.nixos.org/t/nix-function-to-merge-attributes-records-recursively-and-concatenate-arrays/2030/9
  deepMerge' =
    lhs: rhs:
    lhs
    // rhs
    // (builtins.mapAttrs (
      rName: rValue:
      let
        lValue = lhs.${rName} or null;
      in
      if isAttrsNotDer lValue && isAttrsNotDer rValue then
        deepMerge' lValue rValue
      else if builtins.isList lValue && builtins.isList rValue then
        lValue ++ rValue
      else
        rValue
    ) rhs);
  # based on https://discourse.nixos.org/t/nix-function-to-merge-attributes-records-recursively-and-concatenate-arrays/2030/9
  deepMergeUnique' =
    lhs: rhs:
    lhs
    // rhs
    // (builtins.mapAttrs (
      rName: rValue:
      let
        lValue = lhs.${rName} or null;
      in
      if isAttrsNotDer lValue && isAttrsNotDer rValue then
        deepMergeUnique' lValue rValue
      else if builtins.isList lValue && builtins.isList rValue then
        lValue ++ rValue
      else if lValue == null then
        rValue
      else
        throw "Conflict at ${rName}"
    ) rhs);
}
