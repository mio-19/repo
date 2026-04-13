{
  deepMerge,
  lib,
  buildMavenRepo,
}:
let

  mergeTwo =
    x: y:
    let
      x' = buildMavenRepo.passthru.readLockFile x;
      y' = buildMavenRepo.passthru.readLockFile y;
    in
    deepMerge x' y';
in
xs:
if !lib.lists.isList xs then
  xs
else if lib.lists.length xs == 1 then
  lib.head xs
else if lib.lists.length xs == 0 then
  throw "mergeLock: empty list"
else
  builtins.foldl' mergeTwo { } xs
/*
  runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '
      reduce .[] as $item ({}; . * $item)
    ' ${builtins.concatStringsSep " " xs} > $out
  ''
*/
