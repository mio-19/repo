{ lib }:
let
  inherit (lib) recursiveUpdateUntil;
  isAttrsNotDer = x: builtins.isAttrs x && !lib.isDerivation x;
  # https://discourse.nixos.org/t/nix-function-to-merge-attributes-records-recursively-and-concatenate-arrays/2030/9
  # https://noogle.dev/f/lib/recursiveUpdate
  deepMerge =
    lhs: rhs:
    recursiveUpdateUntil (
      path: lhs: rhs:
      !(isAttrsNotDer lhs && isAttrsNotDer rhs)
    ) lhs rhs;
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
