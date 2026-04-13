{ lib }:
let
  isAttrsNotDer = x: builtins.isAttrs x && !lib.isDerivation x;
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
      if isAttrsNotDer lValue && isAttrsNotDer rValue then
        deepMerge lValue rValue
      else if builtins.isList lValue && builtins.isList rValue then
        lValue ++ rValue
      else
        rValue
    ) rhs);
  deepMerges =
    xs:
    if !lib.isList xs then
      throw "deepMerges: Expected a list"
    else if builtins.length xs == 0 then
      throw "deepMerges: Cannot merge an empty list"
    else
      builtins.foldl' deepMerge (builtins.head xs) (builtins.tail xs);
in
{
  __functor = _: deepMerge;
  passthru.deepMerge = deepMerge;
  passthru.deepMerges = deepMerges;
}
